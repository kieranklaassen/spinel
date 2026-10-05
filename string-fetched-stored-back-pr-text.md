Title: A String fetched out of a boxed container and stored back takes its appends

## What this changes

242 of 998 measured programs that fetch a String out of a boxed container, store it back and then change it in place answered as CRuby on c6bbdfbc9 and are wrong on master since #7462: 162 lose the change without a word and 80 raise NoMethodError. This makes all 242 right again.

```ruby
h = {}
%w[a b a a].each do |w|
  fresh = !h.key?(w)
  h[w] = h.fetch(w, +"")
  h[w] << "," unless fresh
  h[w] << w
end
p h.to_a
```

prints `[["a", "a,a,a"], ["b", "b"]]` in CRuby and did here until #7462; since then it prints `[["a", ""], ["b", ""]]`. The Array form (`a[i] = a.fetch(i, +"")`) loses the append the same way, and `concat`, `prepend`, `setbyte`, `slice!` and `reverse!` on such an element raise NoMethodError.

The fetch is a read the append's handle is demanded of, and its own value is boxed. While such a read was typed the handle, the store boxed it as one. #7462 types it as the boxed value it is, which it is: the value may be no String at all. The store then took the box as it came, a plain String in it stayed a plain String, and the append answered a new String that nothing kept. The store of such a read now lifts the box with `sp_poly_strbuf_lift`, the helper a boxed variable handed to an appending callee already goes through: a plain String becomes the handle, as it did before #7462, and any other value passes as the box it is, as #7462 made it. The read's type stays #7462's.

**Checked** on fa08b100d with gcc, against CRuby 3.3.6 run with `--enable-frozen-string-literal`, each program at `SPINEL_GC_STRESS` unset, 1 and 2; the new test again under CRuby 4.0.7:

- 998 programs in two families: a Hash with String, Integer and Symbol keys and an Array; the read by `fetch` with a default and with a block, `dig`, `[]`, `values` and `h[k] || +""`; stored back under its key and then changed by `<<` (once, chained, twice, read back after), `concat`, `prepend`, `insert`, `replace`, `clear`, `upcase!`, `reverse!`, `setbyte`, `slice!`, `squeeze!`, `sub!` or the separator idiom above, or put in a literal, pushed, bound to a local or passed to a method that appends; at the top level and in a method. Each also built on c6bbdfbc9 and on fa08b100d with #7462 reverted:

  | c6bbdfbc9 | fa08b100d | #7462 reverted | this branch | programs |
  |---|---|---|---|---|
  | right | wrong | right | right | 162 |
  | right | NoMethodError | right | right | 80 |
  | right | right | right | right, C differs | 42 |
  | right | right | right | C byte-identical | 334 |
  | wrong | wrong | wrong | C byte-identical | 280 |
  | NoMethodError | NoMethodError | NoMethodError | C byte-identical | 80 |
  | C error | C error | C error | C byte-identical | 20 |

  No program right on fa08b100d is wrong on this branch, and none that was right on c6bbdfbc9 is left wrong.
- `tools/cident.sh fa08b100d` (test/, benchmark/ and packages/*/test; optcarrot was not in the corpus where this was measured): 6103 identical, 8 differ, 0 refusal changes. The 8 are the new test and seven tests that pass before and after: `bang_result_through_shared_handle`, `int_element_alias_not_string`, `mapped_array_mutable_elements`, `poly_string_append_integer`, `returned_container_mutable_string`, `string_alias_accessor_read`, `string_alias_out_of_container`. Every changed line (13) is master's line with only the `sp_poly_strbuf_lift(` ... `)` wrap added.
- Where a marked element read is stored boxed, the store takes the wrap whether or not master was wrong: those seven tests and the 42 programs above are right on master, get it and stay right. The wrap does nothing for a box that is no plain String. It costs them 10 instructions per store: `h = {"k" => +"a"}` and 300,000 times `h["k"] = h.fetch("k", +"")` is 57,971,029 instructions before and 60,971,014 after (callgrind).
- `tools/refusals.sh`: pass (426 records). `make reject-test`: pass. `test/strbuf_demand_value_widens_later.rb`, #7462's own test, passes.

**Left alone**

- 360 of the 998 were wrong (280) or raised NoMethodError (80) on c6bbdfbc9 as well, and their C is byte-identical here: a Hash with Symbol keys (`h[:a] = h.fetch(:a, +""); h[:a] << "v"` prints `[[:a, ""]]`), the block form on a Hash (`h.fetch(k) { +"" }`), the `h[k] || +""` spelling, a Hash that holds an Integer beside its Strings, and the read put in an Array or Hash literal or pushed (`z = [h.fetch(k, +"")]; z[0] << "v"`). The block form on an Array is cured.

`emit_boxed_impl` grows by 13 lines and stays under 400; no function over 1,000 lines is touched.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7: the 8 lines are equal)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
