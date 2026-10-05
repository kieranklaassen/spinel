<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
spans = [("ab".."ae"), 1]
r = spans[0]
p r.begin
p r.end
```

stopped at `undefined method 'begin' for an instance of Range (NoMethodError)`. CRuby prints `"ab"` and `"ae"`. `first` and `last` of the same Range answer.

The Range comes out of the Array boxed, and `begin` and `end` of a boxed value go to `sp_poly_range_begin_v` and `sp_poly_range_end_v`. Each has an arm for a Float Range and falls to the Integer Range's reader, which raises for anything else. A String Range had no arm.

Each gains one, asked only of what is no Integer Range, on the way to the raise: the end as it sits in the `sp_StrRange`, boxed by `sp_box_str`, which boxes the NULL of an end left out as nil. That is how `sp_poly_min` and `sp_poly_max` hand back a String Range's end.

No C changes: the two functions are in the runtime (`lib/spinel_rt.h`).

A boxed read now answers the two ends, as `first` and `last` do. A String Range held by an instance variable, a Struct member, a global, a constant or a class variable could lose them on master, where `begin` raised and read nothing: so this sits on the two pieces that keep them, #<fork PR 146> and #<fork PR 148>.

Not changed, and as on master:

- An end changed in place after the Range is made is not seen through `begin` and `end`, as it is not through `first` and `last`. CRuby shares the String.
- `include?`, `member?` and `cover?` on a boxed String Range. Each is its own commit.
- `step` on a boxed String Range raises NoMethodError.

Measured on master 23e9734df74b, against CRuby 3.3.6, with gcc 13.3 and clang 18.1, in a plain run, under `SPINEL_GC_STRESS=1` and `2`, and with `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1` without and with level 1:

- 522 generated programs: `begin` and `end` of a Range read from an Array element, a Hash value, a captured local, a method's boxed return, an instance variable and a local; the Range a String one (inclusive, exclusive, endless, beginless, with mutable ends), an Integer one (and endless), a Float one, and `(1..2.5)`; the answer printed, interpolated, compared, both ends together, and kept across an allocation; and a slot that holds an Integer or a String instead. Right at all five settings: 252 on master, 522 here, the same with both compilers. Of 2,610 runs a compiler: 1,260 right on both, 1,350 not right on master and right here. Right on master and not right here: 0.
- The 270 not right on master are the String Range ones: each raises NoMethodError.
- `make cident REF=23e9734df74b`: 6104 identical, 0 differ, 0 refusal changes.
- Cost, by callgrind, of 300,000 turns of `r.begin.to_i + r.end.to_i` on one boxed slot. With gcc: an Integer Range 33,061,928 instructions for master's 33,661,898, a Float Range 43,861,950 for 43,861,921, a String Range, which raised on master, 124,261,986. With clang: an Integer Range 41,125,497 for 36,025,485, a Float Range 43,225,524 for 42,325,512, a String Range 124,526,344. clang compiles the whole loop another way once a third kind of Range can come back (tag and class as two compares where it made one, the Array's bounds test kept inside the loop); each of the eight placings of the arm measured costs it 12 to 17 instructions a turn on an Integer Range. optcarrot's C is unchanged.
- `tools/refusals.sh` passes (426 records). `make scale-test` gives master's four numbers (1.71x, 4.73x, 6.06x, 4.22x). `ruby tools/gate.rb check` passes.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (equal under CRuby 4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: #<fork PR 146> and #<fork PR 148> (the ends of a String Range in a slot are kept by those two, and this answers them)
