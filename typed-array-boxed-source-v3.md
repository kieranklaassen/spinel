<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An Array returned by a call and held by no variable was collected while it was boxed for a rest parameter or for `String#%`. Only such a source pays for the cure, 16 to 30 instructions a call. A source that a variable, a constant or a literal holds compiles to the C it had. A comparison of a mixed Array with a typed one, the third road, pays 1 instruction built with gcc and saves 1 built with clang.

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

Master (d02a49fb7) prints `59` in a plain run, built with gcc or clang. CRuby prints `0`.

`take(*floats(i))` fills the rest parameter with a new Array of boxed values made from the Float Array, and `sp_typed_to_poly` makes it. It allocates the new Array first and reads the old one after, holding the old one nowhere. The old Array is a call's result that no variable holds, so a collection started by that allocation freed it, and its elements were read out of a buffer already given back.

`fmt % ints(i)` reaches the same helper with an Integer, Float or String Array. With 2,000 Strings it ends in a segmentation fault in a plain run; the Integer and Float formats are wrong in 1,000 of 1,000 calls at `SPINEL_GC_STRESS=1`. At level 2 two elements are enough: with `def floats(e) = [e + 0.5, e + 1.5]`, `p take(*floats(1))` prints `[]`, and `"%.1f %.1f" % floats(1)` raises "too few arguments (ArgumentError)".

The helper is as it was. Where the source is a local, an instance variable, a class variable, a global, a constant, `self` or an Array literal (which sits in a rooted temp), something else holds it and the call is master's (`typed_array_src_held`). Any other source, a call's result, is boxed by `sp_typed_to_poly_unheld`, which holds it while the new Array is allocated, as `sp_IntArray_to_poly`, `sp_StrArray_to_poly_fmt` and `sp_FloatArray_to_poly` hold theirs.

`sp_PolyArray_eq_typed` compares a mixed Array with a boxed copy of a typed one. It held the source and left the copy held by nothing, and an element's own `==` allocates in the middle of the comparison:

```ruby
class Loud
  def ==(other)
    junk = []
    40.times { |k| junk << "j#{k}" }
    true
  end
end

def three(i) = ["s#{i}", "t#{i}", "u#{i}"]

mixed = [Loud.new, "t1", "u1"]
p mixed == three(1)     # true in Ruby; aborts on master at SPINEL_GC_STRESS=2
```

The slot that holds the source now holds the copy once it is made. The copy holds the Strings of a source nothing else holds, so the comparison is safe with the two roots it had.

Cost. Callgrind, 1,000,000 calls, on d02a49fb7:

| | gcc before | gcc after | clang before | clang after |
|---|---|---|---|---|
| `take(*fl)`, a local of two Floats | 194,895,928 | 194,895,928 | 202,380,322 | 202,380,322 |
| the same, an instance variable | 196,952,586 | 196,952,586 | 202,440,257 | 202,440,257 |
| `"%d %d" % ia`, a local | 2,047,317,249 | 2,047,318,377 | 2,023,788,653 | 2,023,788,653 |
| the same, a frozen constant | 2,047,304,087 | 2,047,304,087 | 2,023,775,385 | 2,023,775,385 |
| `"%d %d" % [i, 2]`, a literal | 2,394,777,793 | 2,394,780,049 | 2,378,864,862 | 2,378,864,862 |
| `"%s %s" % sa`, a local | 1,287,661,248 | 1,287,660,120 | 1,211,119,039 | 1,211,117,912 |
| `"%.1f %.1f" % fa`, a local | 5,958,738,924 | 5,958,738,924 | 5,887,200,446 | 5,887,200,446 |
| `take(*two(i))`, a call's result | 517,110,095 | 534,483,997 | 512,147,525 | 528,522,749 |
| `"%d %d" % two(i)`, a call's result | 2,393,673,435 | 2,409,670,051 | 2,357,760,472 | 2,387,759,345 |
| `pa == ia`, a mixed Array against an Integer Array | 448,158,891 | 449,156,635 | 446,641,447 | 445,641,447 |
| `pa == sa`, against a String Array | 900,092,774 | 901,092,774 | 853,576,091 | 852,576,091 |
| `pa != fa`, against a Float Array | 589,160,125 | 589,160,125 | 556,643,788 | 555,642,661 |

The seven rows with a held source compile to the same C as before; where their counts differ it is by 1,127 to 2,256 instructions in the whole run, not by the call.

No program of `test/`, `benchmark/` and the packages' tests changes its generated C (6,403 programs): each of the 23 that reach the helper hands it a held source or compares. Those 23 print the same bytes before and after, plain and at `SPINEL_GC_STRESS=1` and `2`, gcc and clang. optcarrot formats one line through it, from a held source.

Not in this change, and as on master: a rest Array handed to `new` is not held while the object is allocated. `Box.new(*floats(1))` with `def initialize(*items)` aborts at `SPINEL_GC_STRESS=2` before and after. And a typed Array on the left of `==` is compared as if it stood on the right: with `pa = [K.new(1), "u1", "v1"]` and a `K#==` that answers true, `strs(1) == pa` prints `true` where Ruby prints `false` (`String#==` never asks `K`), before and after.

Test: `test/typed_array_boxed_source_held.rb`, in `GC_STRESS_TESTS`, five lines, each the number of calls that answered something else: a Float Array into a rest parameter, a Float, an Integer and a String Array formatted, and a String Array compared. On master it ends in a segmentation fault in a plain run and at level 1, and raises at level 2, built with gcc or clang.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on d02a49fb7)
- [ ] Depends on: # (nothing)
