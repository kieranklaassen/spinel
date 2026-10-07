<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def band(v)
  case v
  when "a".."m" then "low"
  when "n".."z" then "high"
  when 1..9 then "digit"
  else "other"
  end
end
puts band("c"), band("q"), band(5), band(nil)
```

prints `other`, `other`, `digit`, `other` (`spinel diff`: output-diff). CRuby prints `low`, `high`, `digit`, `other`. `("aa".."az") === h["k"]` for a boxed `"ab"` and `["c", 5, "q", nil].grep("a".."m")` answer `false` and `[]` the same way.

`===` of a String Range is membership. With a boxed value it was written as an equality of the Range and the value, which no String satisfies, in two places:

- the `===` call. The arm for a receiver that compares by value leaves out an Integer Range and a Float Range by their families 5 and 6 of `eq_family`, and not the String Range's 7. It leaves 7 out too, and the call falls to `emit_range_call`, which covers as it does for a String argument.
- `when`. `emit_when_typed_test` had an arm for a String subject against a String Range, and for a boxed subject against an Integer or a Float Range, and none for a boxed subject against a String Range. It gains one.

Both ask `sp_srange_cover` for the String the value holds; a value that is no String is not covered. The first commit moves that test of a boxed value out of `emit_range_call` into one function for the two to share, and changes no C (cident: 6,429 identical, 0 differ).

The Range is not boxed for the test, so nothing is allocated between the value and the test, and programs master answered right run fewer instructions (callgrind on master 759d120f, 300,000 turns of two tests with an Integer and a String outside the Range: `===` 178,217,460 to 64,267,976 with gcc 13.3 and 159,676,814 to 65,722,959 with clang 18.1; `when` 249,624,742 to 131,468,247 and 225,684,389 to 126,023,872). No corpus program's C changes beyond the one the piece beneath changes. optcarrot's C is unchanged.

Not here: `K === x` for a constant `K` that holds a String Range answers false (the call is read as a class test); `["c", "d"].all?("a".."m")` on a String Array answers false; `in "a".."m"` raises TypeError.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: "cover? and include? of a String Range read a boxed String that was appended to" (its test of a boxed value is the one moved and shared here, and the tests here ask an appended String too)
