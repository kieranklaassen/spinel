Title: A String fetched out of a boxed container and stored back takes its appends

## What this changes

242 of 998 measured programs that fetch a String out of a boxed container, store it back and then change it in place answered as CRuby on c6bbdfbc9 and are wrong on master (4d56c1573) since #7462: 162 lose the change without a word and 80 raise NoMethodError. This makes all 242 right again.

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

The fetch is a read the append's handle is demanded of, and its own value is boxed. While such a read was typed the handle, the store boxed it as one. #7462 types it as the boxed value it is, which it is: the value may be no String at all. The store then took the box as it came, a plain String in it stayed a plain String, and the append answered a new String that nothing kept. The store of such a read now lifts the box: a plain String becomes the handle, as it did before #7462, and any other value passes as the box it is, as #7462 made it. The read's type stays #7462's.

Two commits. The second keeps a frozen String out of the lift: it can take no change in place, and a frozen literal taken as the default (`h[k] = h.fetch(k, "none")`) stays the one object it is on master, where the first commit alone stored a copy of it.

Depends on the search fix beneath it ("A boxed String the program appends to is still a String to include?, casecmp and pack"): the lift puts a handle in a box where master has a plain String, and without that fix `%w[ab].include?(h[k])`, `casecmp` and `pack` do not see a handle as a String.

**Checked** on 4d56c1573 with the search fix beneath, gcc, against CRuby 3.3.6 run with `--enable-frozen-string-literal`, each program at `SPINEL_GC_STRESS` unset, 1 and 2:

- 998 programs in two families: a Hash with String, Integer and Symbol keys and an Array; the read by `fetch` with a default and with a block, `dig`, `[]`, `values` and `h[k] || +""`; stored back under its key and then changed by `<<` (once, chained, twice, read back after), `concat`, `prepend`, `insert`, `replace`, `clear`, `upcase!`, `reverse!`, `setbyte`, `slice!`, `squeeze!`, `sub!` or the separator idiom above, or put in a literal, pushed, bound to a local or passed to a method that appends; at the top level and in a method. 714 give byte-identical C; 284 differ:

  | 4d56c1573 | this branch | programs |
  |---|---|---|
  | wrong | right | 162 |
  | NoMethodError | right | 80 |
  | right | right | 42 |

  The 242 were right on c6bbdfbc9.
- 1,279 programs a second reader wrote against the first form of this branch: the stored String read back in every way it can be, handed as the argument to 47 String-taking forms, compared by identity with whatever else holds it, with a default that is frozen, binary, UTF-8 or 300 bytes long, and the change in place never run, run after the reads, or changing nothing. 346 give byte-identical C; 933 differ:

  | 4d56c1573 | this branch | programs |
  |---|---|---|
  | wrong | right | 85 |
  | NoMethodError | right | 45 |
  | right | right | 775 |
  | wrong | wrong | 20 |
  | C error | C error | 8 |

  No program right on 4d56c1573 is wrong on this branch, and no raise or C error becomes an answer. The 20 and the 8 are under "Left alone".
- `tools/cident.sh 4d56c1573` (test/, benchmark/ and packages/*/test; optcarrot was not in the corpus where this was measured): 6108 identical, 17 differ, 0 refusal changes. 8 are the search fix's. The other 9 are the two new tests and seven tests that pass before and after: `bang_result_through_shared_handle`, `int_element_alias_not_string`, `mapped_array_mutable_elements`, `poly_string_append_integer`, `returned_container_mutable_string`, `string_alias_accessor_read`, `string_alias_out_of_container`. Each of their 17 changed lines is the line beneath with only the `sp_poly_strbuf_lift_unfrozen(` ... `)` wrap added.
- `tools/refusals.sh`: pass (426 records). `make reject-test`: pass. `test/strbuf_demand_value_widens_later.rb`, #7462's own test, passes.

**Cost.** Where a marked element read is stored boxed, the store takes the wrap whether or not master was wrong. What it does depends on what the box holds (callgrind instructions and peak memory, master then this branch; none of the four programs appends):

| the store | instructions | per store | peak |
|---|---|---|---|
| one key, 3,000,000 stores; the element is a handle already | 1,071,667,629 to 1,098,667,805 | 9 | 9 to 10 MB |
| 400,000 new keys, default a frozen literal | 573,844,355 to 579,044,373 | 13 | 55 MB both |
| 400,000 new keys, default `+"value"` | 685,984,976 to 917,100,343 | 578 | 62 to 106 MB |
| Array, 300,000 new slots, default `+"value"` | 200,452,064 to 746,266,715 | 1,819 | 17 to 51 MB |

A plain String that is not frozen gets a handle and a copy of its bytes per store, as it did before #7462. That is what makes the append after it reach the element.

**Left alone**, each as on master:

- 360 of the 998 were wrong (280) or raised NoMethodError (80) on c6bbdfbc9 as well, and their C is byte-identical here: a Hash with Symbol keys (`h[:a] = h.fetch(:a, +""); h[:a] << "v"` prints `[[:a, ""]]`), the block form on a Hash (`h.fetch(k) { +"" }`), the `h[k] || +""` spelling, a Hash that holds an Integer beside its Strings, and the read put in an Array or Hash literal or pushed (`z = [h.fetch(k, +"")]; z[0] << "v"`). The block form on an Array is cured.
- The default kept under another name (`d = +"d"; h[k] = h.fetch(k, d); h[k] << "x"` leaves both `"d"`; CRuby prints `"dx"` twice): the element is a copy, as on master. Making it the same String is a sharing rule, and none is added here.
- Of the 20: 9 compare a frozen literal read back out of a slot it was already in by identity; 8 are the search fix's own "Left alone" (`(a..a).to_a` of boxed ends, `equal?` on a literal); 2 have the right bytes now and differ only in how 3.3.6 prints an Encoding and a non-ASCII String; 1 appends through a second Array the String was pushed to from `each`. The 8 C errors are `between?` and `concat`, `insert`, `prepend` and `replace` taking the boxed String as their argument.

`emit_boxed_impl` grows by 14 lines to 380; no function over 1,000 lines is touched. `lib/spinel_rt.h` gains one helper, `sp_poly_strbuf_lift_unfrozen`, beside `sp_poly_strbuf_lift`; nothing there changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7: the 8 lines of `string_fetched_stored_back` are equal; `frozen_string_fetched_stored_back`, 12 lines, was run under 3.3.6 only)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the search fix)
