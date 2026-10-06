<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
spans = [("ab".."ae"), 1]
r = spans[0]
p r.begin
p r.end
```

stops at `undefined method 'begin' for an instance of Range (NoMethodError)` (`spinel diff`: exception-diff). CRuby prints `"ab"` and `"ae"`. `first` and `last` of the same Range answer.

The Range comes out of the Array boxed, and `begin` and `end` of a boxed value go to `sp_poly_range_begin_v` and `sp_poly_range_end_v`. Each has an arm for a Float Range and falls to the Integer Range's reader, which raises for anything else. Each gains an arm for a String Range, asked only of what is no Integer Range, on the way to the raise: the end as it sits in the `sp_StrRange`, boxed by `sp_box_str`, which boxes the NULL of an end left out as nil.

Cost: no generated C changes; the two functions are in the runtime, and the lines are added. Callgrind on master 23e9734df74b, 300,000 turns of `r.begin.to_i + r.end.to_i` on one boxed slot: with gcc an Integer Range 33,061,928 instructions for master's 33,661,898 and a Float Range 43,861,950 for 43,861,921; with clang an Integer Range 41,125,497 for 36,025,485 and a Float Range 43,225,524 for 42,325,512. clang compiles the loop another way once a third kind of Range can come back, wherever the arm is put.

Not changed: an end changed in place after the Range is made is not seen through `begin` and `end`, as it is not through `first` and `last`.

A boxed read now answers the two ends. A String Range held by an instance variable, a Struct member, a global, a constant or a class variable could lose them on master, where `begin` raised and read nothing: so this depends on the two pieces that keep them, #<fork PR 146> and #<fork PR 148>.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (equal under CRuby 4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: #<fork PR 146> and #<fork PR 148> (the ends of a String Range in a slot are kept by those two, and this answers them)
