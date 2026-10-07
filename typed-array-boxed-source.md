<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An Array returned by a call and held by no variable was collected while it was boxed for a rest parameter or for `String#%`.

```ruby
def floats(i)
  a = []
  k = 0
  while k < 2000
    a << i + k + 0.5
    k += 1
  end
  a
end

def take(*items) = items

bad = 0
i = 0
while i < 1000
  r = take(*floats(i))
  bad += 1 unless r.size == 2000 && r[0] == i + 0.5 && r[1999] == i + 1999.5
  i += 1
end
p bad
```

Master (a2bd89005) prints `59` in a plain run, built with gcc or clang. CRuby prints `0`.

`take(*floats(i))` fills the rest parameter with a new Array of boxed values made from the Float Array, and `sp_typed_to_poly` makes it. It allocated the new Array first and read the old one after, holding the old one nowhere. The old Array is a call's result that no variable holds, so a collection started by that allocation freed it, and its elements were read out of a buffer already given back.

`fmt % ints(i)` reaches the same helper with an Integer, Float or String Array. With 2,000 Strings it ends in a segmentation fault in a plain run; the Integer and Float formats are wrong in 1,000 of 1,000 calls at `SPINEL_GC_STRESS=1`. At level 2 two elements are enough: with `def floats(e) = [e + 0.5, e + 1.5]`, `p take(*floats(1))` prints `[]`, and `"%.1f %.1f" % floats(1)` raises "too few arguments (ArgumentError)".

The helper now holds its source, as `sp_IntArray_to_poly`, `sp_StrArray_to_poly_fmt` and `sp_FloatArray_to_poly` hold theirs. `sp_PolyArray_eq_typed`, its third caller, held the source for the call already; that root moves into the callee.

Cost: one root a conversion. Callgrind, 1,000,000 calls:

| | gcc before | gcc after | clang before | clang after |
|---|---|---|---|---|
| `take(*fl)`, two Floats | 194,895,928 | 210,952,977 | 202,380,367 | 219,437,407 |
| `"%d %d" % ia` | 2,047,317,249 | 2,063,365,012 | 2,023,788,693 | 2,030,836,452 |
| `pa == ia`, a mixed Array against an Integer Array | 448,156,672 | 448,156,672 | 446,639,257 | 451,640,382 |

That is 16 or 17 instructions for a splat into a rest parameter, 7 to 16 for a format, and for a comparison nothing with gcc and 5 with clang.

The helper is in the runtime header, so no program's generated C changes: 0 of the 6,376 programs of `test/`, `benchmark/` and the packages' tests. The 23 of them that call the helper print the same bytes before and after, plain and at `SPINEL_GC_STRESS=1` and `2`, gcc and clang. optcarrot calls it once, for a line it formats.

Not in this change, and as on master: a rest Array handed to `new` is not held while the object is allocated. `Box.new(*floats(1))` with `def initialize(*items)` aborts at `SPINEL_GC_STRESS=2` before and after.

Test: `test/typed_array_boxed_source_held.rb`, in `GC_STRESS_TESTS`, four lines, each the number of 1,000 calls that answered something else: a Float Array into a rest parameter, and a Float, an Integer and a String Array formatted. On master it ends in a segmentation fault in a plain run and at level 1, and raises at level 2, built with gcc or clang; its first line alone prints 37 in a plain run.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on a2bd89005)
- [ ] Depends on: # (nothing)
