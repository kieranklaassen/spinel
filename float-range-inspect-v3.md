<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A Float Range's `inspect` could begin with freed bytes:

```ruby
bad = 0
200_000.times { |i| bad += 1 if ((i + 0.25)..(i + 1.25)).inspect != "#{i + 0.25}..#{i + 1.25}" }
p bad    # 0 in Ruby; 1 on master, with gcc and with clang
```

Under `SPINEL_GC_STRESS=2` every call is wrong and the program exits 0: `r = (0.25..1.25); p r.inspect` prints `"\xDB\xDB\xDB\xDB..1.25"` on master.

`sp_frange_inspect` (`lib/sp_cold.c`) makes the text of the first end, then the text of the last end, then joins the two:

```c
const char *lo = ... sp_float_to_s(r.first);
const char *hi = ... sp_float_to_s(r.last);
return sp_sprintf("%s%s%s", lo, r.excl ? "..." : "..", hi);
```

Nothing holds `lo` while `hi` is made. `lo` is rooted now (`SP_GC_ROOT_STR`). An omitted first end is `sp_str_empty` there in place of `""`, so that the rooted slot always holds a String with a header. No file under `src/` changes.

`test/float_range_inspect_root.rb` compares `inspect` and `to_s` with the text built from the two ends, then prints a Float Range through `inspect`, `to_s`, an interpolation, `puts` and `p`. On master (dafa0d047, gcc and clang) it is right in a plain run and at level 1, and prints freed bytes at level 2 with exit 0. It is added to `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it is ten lines of Float Range text and holds no Hash)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: no file under `src/` is touched)
- [ ] Depends on: # (nothing)
