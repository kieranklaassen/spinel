<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
spans = [("ab".."ae"), 1]
r = spans[0]
p r.begin
p r.end
```

stops at `undefined method 'begin' for an instance of Range (NoMethodError)` (`spinel diff`: exception-diff). CRuby prints `"ab"` and `"ae"`. `first` and `last` of the same Range answer.

The Range comes out of the Array boxed, and `begin` and `end` of a boxed value go to `sp_poly_range_begin_v` and `sp_poly_range_end_v`. Each has an arm for a Float Range and falls to the Integer Range's reader, which raises for anything else. Each gains an arm for a String Range, asked only of what is no Integer Range, on the way to the raise: the end as it sits in the `sp_StrRange`, boxed by `sp_box_str`, which boxes the NULL of an end left out as nil.

Cost: with clang 17 instructions for a `begin` and an `end` of an Integer Range read from a boxed slot, with gcc nothing. What it buys is the two Strings where master raises NoMethodError. No generated C changes; the two functions are in the runtime, and the lines are added. Callgrind on master a2bd8900, 300,000 turns of `r.begin.to_i + r.end.to_i` on one boxed slot: with gcc 13.3 an Integer Range 46,865,611 instructions for master's 47,465,620 and a Float Range 58,265,638 for 58,265,648; with clang 18.1 an Integer Range 47,123,069 for 42,023,056 (12%) and a Float Range 49,823,106 for 48,923,092. clang tests the tag and class of a boxed value in one compare while two kinds of Range are asked for, and in two once a third is: the cost is in that test, not in the String that comes back (on an Integer Range the same arm answering nil counts the same). Five other placements of the arm (ahead of the Integer Range's reader with and without `SP_UNLIKELY`, after it, out of line with and without the raise) cost clang 12 to 17 a turn too and gcc 3 to 9; this one costs gcc nothing.

Not changed: an end changed in place after the Range is made is not seen through `begin` and `end`, as it is not through `first` and `last`.

A boxed read now answers the two ends. A String Range held by an instance variable, a Struct member, a global, a constant or a class variable could lose them on master, where `begin` raised and read nothing: so this depends on the two pieces that keep them, "A String Range stored into an instance variable or a Struct member keeps its ends" and "A String Range in a global, a constant or a class variable keeps its ends". Neither of those two needs this change, nor does "include? and member? on a String Range read from a boxed slot walk its members".

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (equal under CRuby 4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: "A String Range stored into an instance variable or a Struct member keeps its ends" and "A String Range in a global, a constant or a class variable keeps its ends" (the ends of a String Range in a slot are kept by those two, and this answers them)
