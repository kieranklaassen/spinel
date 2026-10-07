<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An Array returned by a call and held by no variable was collected while it was boxed for a rest parameter or for `String#%`. A source the compiler can see is held compiles to the C it had: a variable, a constant or `self`; an `attr_reader`'s or a Struct member's slot read off one; an element of such an Array of Arrays; a conditional, an `||` or an `&&` of two such reads; an Array literal. Any other source is a method call's result and pays 16 to 30 instructions a call. No list cuts that cost: a call's result is held by nothing but the expression it stands in, and whether the method made the Array or returned one that something else holds is not known where it is called. A comparison of a mixed Array with a typed one, the third road, pays 1 instruction built with gcc and saves 1 built with clang.

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

Master (42557a3c0) prints `59` in a plain run, built with gcc or clang. CRuby prints `0`.

`take(*floats(i))` fills the rest parameter with a new Array of boxed values made from the Float Array, and `sp_typed_to_poly` makes it. It allocates the new Array first and reads the old one after, holding the old one nowhere. The old Array is a call's result that no variable holds, so a collection started by that allocation freed it, and its elements were read out of a buffer already given back.

`fmt % ints(i)` reaches the same helper with an Integer, Float or String Array. With 2,000 elements the Integer and Float formats are wrong in 1,000 of 1,000 calls at `SPINEL_GC_STRESS=1`; the String format is wrong in 2 of 1,000 in a plain run and ends in a segmentation fault at level 1. At level 2 two elements are enough: with `def floats(e) = [e + 0.5, e + 1.5]`, `p take(*floats(1))` prints `[]`, and `"%.1f %.1f" % floats(1)` raises "too few arguments (ArgumentError)".

The helper is as it was. `typed_array_src_held` answers whether something else holds the source for the length of the call: a local, an instance variable, a class variable, a global, a constant or `self`; a field read off one of those, which is an `attr_reader` or a Struct member (`pt.co`, also `pts[i].co`); an element of an Array of Arrays read off one (`rows[i]`, `rows[idx(i)]`, where the index's call cannot rebind `rows`); a conditional, an `||` or an `&&` whose arms are such reads; and an Array literal, which sits in a rooted temp. For those the call is master's. A source the list does not prove held is boxed by `sp_typed_to_poly_unheld`, which holds it while the new Array is allocated, as `sp_IntArray_to_poly`, `sp_StrArray_to_poly_fmt` and `sp_FloatArray_to_poly` hold theirs.

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
p mixed == three(1)     # true in Ruby; a segmentation fault on master at SPINEL_GC_STRESS=2
```

The slot that holds the source now holds the copy once it is made. The copy holds the Strings of a source nothing else holds, so the comparison is safe with the two roots it had.

Cost. Callgrind on 42557a3c0, each row a loop of 1,000,000 calls:

| | gcc before | gcc after | clang before | clang after |
|---|---|---|---|---|
| `take(*two(i))`, a call's result | 517,108,967 | 534,483,997 | 512,146,393 | 528,521,617 |
| `"%d %d" % two(i)`, a call's result | 2,393,667,750 | 2,409,666,622 | 2,357,754,832 | 2,387,755,959 |
| `pa == ia`, a mixed Array against an Integer Array | 448,156,671 | 449,156,671 | 446,639,170 | 445,639,170 |
| `pa == sa`, against a String Array | 900,091,682 | 901,091,682 | 853,576,068 | 852,576,068 |
| `pa != fa`, against a Float Array | 589,156,777 | 589,156,777 | 556,640,384 | 555,640,384 |

These compile to the same C before and after, so they cost nothing: `take(*fl)` and `"%d %d" % ia` with a local, an instance variable and a frozen constant; `"%d %d" % [i, 2]`; `"%s %s" % sa` and `"%.1f %.1f" % fa`; `"%d %d" % pt.co` and `take(*pt.fl)` through an `attr_reader` and through a Struct member; `"%d %d" % pts[i & 1].co`; `"%d %d" % rows[i & 1]`, `rows[idx(i)]` and `take(*frows[pick(i)])`; `take(*(i.odd? ? fa : fb))` and `"%d %d" % (fa || fb)`. `rows.first` and `frows.last` are element reads and compile the same too. A Hash's value (`"%d %d" % h[:a]`) is boxed already and does not reach the helper, before or after.

The generated C of one program of the 6,470 under `test/`, `benchmark/` and `packages/*/test/` differs: the new test. Of the others, 25 call the helper or the comparison, each with a source the list calls held: they print the same bytes and end the same way before and after in all eight runs (plain, `SPINEL_GC_STRESS=1`, the same with `SPINEL_GC_VERIFY=1`, and `2`; gcc and clang). optcarrot's C is byte-identical.

**Not in this change**, and as on master:

- A rest Array handed to `new` is not held while the object is allocated. `Box.new(*floats(1))` with `def initialize(*items)` aborts at `SPINEL_GC_STRESS=2` before and after.
- A typed Array on the left of `==` is compared as if it stood on the right: with `pa = [K.new(1), "u1", "v1"]` and a `K#==` that answers true, `strs(1) == pa` prints `true` where Ruby prints `false` (`String#==` never asks `K`), before and after.

Test: `test/typed_array_boxed_source_held.rb`, in `GC_STRESS_TESTS`, six lines, each the number of calls that answered something else: a Float Array into a rest parameter, a Float, an Integer and a String Array formatted, a String Array compared, and the sources the list calls held, boxed where they are read. On master it ends in a segmentation fault in a plain run and at level 1, and raises at level 2, built with gcc or clang.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after)
- [ ] Depends on: # (nothing)
