<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A Float Range's `inspect` could begin with freed bytes:

```ruby
bad = 0
200_000.times { |i| bad += 1 if ((i + 0.25)..(i + 1.25)).inspect != "#{i + 0.25}..#{i + 1.25}" }
p bad    # 0 in Ruby; 1 on master in a plain run, with gcc and with clang
```

Under `SPINEL_GC_STRESS=2` every call is wrong and the program exits 0: `r = (0.25..1.25); p r.inspect` prints `"\xDB\xDB\xDB\xDB..1.25"`.

`sp_frange_inspect` (`lib/sp_cold.c`) makes the text of the first end, then the text of the last end, then joins the two:

```c
const char *lo = ... sp_float_to_s(r.first);
const char *hi = ... sp_float_to_s(r.last);
return sp_sprintf("%s%s%s", lo, r.excl ? "..." : "..", hi);
```

Nothing holds `lo` while `hi` is made. `lo` is rooted now (`SP_GC_ROOT_STR`). An omitted first end is `sp_str_empty` there in place of `""`, so that the rooted slot always holds a String with a header. `hi` needs no root: `sp_sprintf` formats into its own buffer before it allocates.

`to_s`, an interpolation, `p`, `puts` and `print` of a Float Range go through this function, and so does the inspect of an Array or a Struct that holds one.

`test/float_range_inspect_root.rb` compares 300 rounds of `inspect` and of `to_s` with the text built from the two ends, then prints a Float Range held in a local through `inspect`, `to_s`, an interpolation, `puts` and `p`, an exclusive one, the two with an omitted end, and one held in an Array. On master (23e9734df, Linux x86-64, gcc and clang) it passes a plain run, level 1 and level 1 with `SPINEL_GC_VERIFY=1`; at level 2 it counts 600 wrong of 600 and prints freed bytes in seven of its other nine lines, exit 0. With this change it prints its expected output under all four, with both compilers. It is added to `GC_STRESS_TESTS`.

Measured with both compilers built on 23e9734df, which this branch is one commit on, each program with gcc and clang at plain, level 1, level 1 with verify and level 2:

- 156 programs: nine kinds of ends (two Floats, exclusive, a Float and an Integer either way round, each end omitted, a literal, a negative and a large end, an infinite end) through seventeen callers (`inspect`, `to_s`, an interpolation, a local, an Array, a Hash, a Struct, a boxed value, `+`, a method, `p`, `puts` and `print`, some in two forms), and the message of `rand` given an empty Float Range. None that is right on master under a setting is wrong there with this change. 97 that print freed bytes at level 2 on master, exit 0, are right under all eight. 49 are right before and after: an omitted end, where one of the two texts is not made, and a Range from an Integer to a Float, which is another type and is printed by `sp_range_str`. Nine hold the Range in a Hash and were compared with their own plain run, because the CRuby at hand (3.3.6) prints a Hash the older way: six of them print freed bytes at level 2 on master, and with this change all nine print the plain run's bytes at every level. The last one is under "Not in this change".
- Generated C: no file under `src/` changes, so the C of every program in `test/`, `benchmark/`, the package tests and optcarrot is what it was; the function is in the runtime library.
- Cost (callgrind, 200,000 calls, gcc): `((i + 0.25)..(i + 1.25)).inspect` 411,215,707 to 415,552,798, 22 instructions a call of about 2,060; with the first end omitted 308,112,497 to 312,915,062, 24. `(i..(i + 1.25)).to_s`, which does not come here, 363,399,613 before and after.

Found on the collector stress lane. Complex, Rational and Integer Range `inspect` were tried beside it and are right at level 2.

Not in this change:

- `Random.new.rand((i + 2.5)..(i + 1.5))`, an empty Float Range, raises nothing where Ruby raises ArgumentError: the same before and after. `rand` and `Random.rand` raise as Ruby does; the message of `Random.rand` was built from freed bytes at level 2 and is right now.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it is ten lines of Float Range text and holds no Hash)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: no file under `src/` is touched)
- [ ] Depends on: # (nothing)
