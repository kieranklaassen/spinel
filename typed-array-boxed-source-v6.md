<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** An Array returned by a call and held by no variable was collected while it was boxed for a rest parameter or for `String#%`. A source the compiler can see is held compiles to the C it had; the list is below. Any other source is rooted while it is boxed, and the root costs 13 to 21 instructions a call (callgrind; every row is in the table below). That is a call's result, and it is also these, which master ran right: `pt.send(:fl)`, a hand-written `def fl = @fl`, `fa.itself`, `fa.freeze`, a Struct member by name (`st[:fl]`), `pts.first.fl` on an Array of objects, `@fa ||= [...]`, and an element `rows[i]` in a program where some class defines `[]`. A comparison of a mixed Array with a typed one, the third road, runs 1 instruction more built with gcc and 1 less built with clang.

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

Master (3ab4539fc) prints `59` in a plain run, built with gcc or clang. CRuby prints `0`.

`take(*floats(i))` fills the rest parameter with a new Array of boxed values made from the Float Array, and `sp_typed_to_poly` makes it. It allocates the new Array first and reads the old one after, holding the old one nowhere. The old Array is a call's result that no variable holds, so a collection started by that allocation freed it, and its elements were read out of a buffer already given back.

`fmt % ints(i)` reaches the same helper with an Integer, Float or String Array. With 2,000 elements the Integer and Float formats are wrong in 1,000 of 1,000 calls at `SPINEL_GC_STRESS=1`, and the String format ends in a segmentation fault in a plain run. At level 2 two elements are enough: with `def floats(e) = [e + 0.5, e + 1.5]`, `p take(*floats(1))` prints `[]`, and `"%.1f %.1f" % floats(1)` raises "too few arguments (ArgumentError)".

The helper is as it was. `typed_array_src_held` answers whether something else holds the source for the length of the call:

- a local, an instance variable, a class variable, a global, a constant or `self`;
- a field read off one of those, which is an `attr_reader` or a Struct member (`pt.co`, also `pts[i].co`), and the class's own reader called with no receiver (`co` in a method of the class), unless a subclass defines a method of that name;
- an element read off one (`rows[i]`; `rows[idx(i)]` where the index's call cannot give `rows` another Array; a constant's element under an index that only reads);
- a conditional, a `case`, an `||` or an `&&` whose every arm is one such read, and a `begin` around one;
- an Array literal, which sits in a rooted temp.

For those the call is master's. `rows[i]` is on the list only while no class of the program defines `[]`. Where one does, the call may be the program's own method, and what that answers is a call's result:

```ruby
class Array
  def [](i) = floats(i + $base)
end
rows = [floats(0), floats(1)]
r = take(*rows[1])      # master: 1 wrong answer in 300 calls in a plain run, 239 at SPINEL_GC_STRESS=1
```

A source the list does not prove held is boxed by `sp_typed_to_poly_unheld`, which holds it while the new Array is allocated, as `sp_IntArray_to_poly`, `sp_StrArray_to_poly_fmt` and `sp_FloatArray_to_poly` hold theirs.

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
p mixed == three(1)     # true in Ruby; a fault on the mark path on master at SPINEL_GC_STRESS=2
```

The slot that holds the source now holds the copy once it is made. The copy holds the Strings of a source nothing else holds, so the comparison is safe with the two roots it had. CONTRIBUTING asks that `lib/spinel_rt.h` changes be additive only: `sp_typed_to_poly_unheld` is added, and these two lines of `sp_PolyArray_eq_typed` change because the copy has to go into a slot the function already roots.

Cost. Callgrind on 3ab4539fc, each row a loop of 1,000,000 calls; "a call" is the difference divided by the calls:

| the source | gcc before | gcc after | a call | clang before | clang after | a call |
|---|---|---|---|---|---|---|
| `take(*two(i))`, a call's result | 518,109,019 | 535,484,049 | 17.4 | 511,146,438 | 528,521,662 | 17.4 |
| `"%d %d" % two(i)`, a call's result | 2,499,151,673 | 2,515,150,544 | 16.0 | 2,476,295,858 | 2,491,296,985 | 15.0 |
| `take(*pt.send(:fl))` | 197,015,228 | 218,072,351 | 21.1 | 202,501,214 | 218,558,333 | 16.1 |
| `take(*pt.fl)`, `def fl = @fl` | 197,020,593 | 218,077,716 | 21.1 | 202,506,568 | 218,563,680 | 16.1 |
| `take(*fa.itself)` | 195,836,593 | 216,893,644 | 21.1 | 203,320,983 | 217,378,028 | 14.1 |
| `take(*fa.freeze)` | 199,836,594 | 220,893,639 | 21.1 | 205,320,970 | 220,378,012 | 15.1 |
| `take(*st[:fl])`, a Struct member by name | 197,090,480 | 218,147,606 | 21.1 | 202,576,483 | 218,633,601 | 16.1 |
| `take(*pts.first.fl)`, an Array of objects | 204,085,794 | 220,143,056 | 16.1 | 204,573,106 | 220,630,369 | 16.1 |
| `take(*(@fa \|\|= [1.5, 2.5]))` | 204,037,005 | 220,094,194 | 16.1 | 205,523,620 | 222,580,818 | 17.1 |
| `take(*frows[i & 1])`, a class defines `[]` | 207,085,729 | 227,142,993 | 20.1 | 211,574,846 | 226,632,105 | 15.1 |
| `"%d %d" % rows[i & 1]`, a class defines `[]` | 2,052,442,970 | 2,070,490,730 | 18.0 | 2,034,916,356 | 2,028,964,116 | -6.0 |
| `pa == ia`, a mixed Array against an Integer Array | 480,156,719 | 481,156,719 | 1.0 | 465,639,263 | 464,639,262 | -1.0 |
| `pa == sa`, against a String Array | 420,087,217 | 421,087,217 | 1.0 | 417,570,847 | 416,570,847 | -1.0 |
| `pa != fa`, against a Float Array | 451,155,696 | 451,155,696 | 0.0 | 427,639,343 | 426,639,343 | -1.0 |

With the result assigned (`t = "%d %d" % two(i)`) the row is 13.0 with gcc and 19.0 with clang. The `send`, the hand-written reader, `itself`, `freeze` and the Struct member by name are calls the list does not look into; `pts.first` on an Array of objects is not the element read `rows.first` is; `@fa ||= x` is an assignment. Each is held in fact, and each stays off the list because proving it needs more than the read itself.

These compile to the same C before and after, so they cost nothing: `take(*fl)` and `"%d %d" % ia` with a local, an instance variable and a constant; `"%d %d" % [i, 2]`; `"%d %d" % pt.co` and `take(*pt.fl)` through an `attr_reader` and through a Struct member; `take(*fl)` and `"%d %d" % co` inside a method of the reader's class, and `take(*pt.fl)` there with `pt` a reader of self; `"%d %d" % rows[i & 1]` and `rows[idx(i)]`; `take(*(i.odd? ? fa : fb))`, `"%d %d" % (fa || fb)`, and a `case`, an `unless`/`else`, an `if`/`elsif`/`else` and a `begin` of such reads. `rows.first` and `frows.last` on an Array of Arrays compile the same too where no class defines `first`, `last` or `[]`: master rewrites them to `rows[0]` and `frows[-1]`. A Hash's value (`"%d %d" % h[:a]`) is boxed already and does not reach the helper, before or after.

The generated C of none of the 6,506 other programs under `test/`, `benchmark/` and `packages/*/test/` changes, and optcarrot's is byte-identical. 8 of them call the helper, each with a source the list calls held, and 18 run the comparison (one does both). Those 25 answer the same before and after in seven lanes each, built with gcc and with clang: plain, `SPINEL_GC_STRESS=1`, the same with `SPINEL_GC_VERIFY=1`, level 2, `SPINEL_GC_MINOR=0` and `1`, and level 1 with the generational check. 24 pass in all of them; `test/socket_getaddrinfo_family_socktype.rb` aborts with the verifier and at level 2 on master and here.

**Not in this change**, and as on master:

- A rest Array handed to `new` is not held while the object is allocated. `Box.new(*floats(1))` with `def initialize(*items)` aborts at `SPINEL_GC_STRESS=2` before and after.
- A typed Array on the left of `==` is compared as if it stood on the right: with `pa = [K.new(1), "u1", "v1"]` and a `K#==` that answers true, `strs(1) == pa` prints `true` where Ruby prints `false` (`String#==` never asks `K`), before and after.
- Where the receiver of `%` allocates, the format is held by nothing while the source is boxed: at `SPINEL_GC_STRESS=2`, `"#{i & 1} #{FMT}" % ints(i)` raises "too few arguments" on master built with gcc and prints freed bytes in 300 of 300 calls built with clang. With this change the gcc build was right in its four runs, and the clang build prints the same freed bytes.

Tests, both in `GC_STRESS_TESTS`. `test/typed_array_boxed_source_held.rb` prints seven lines, each the number of calls that answered something else: a Float Array into a rest parameter, a Float, an Integer and a String Array formatted, a String Array compared, the sources the list calls held, boxed where they are read, and three sources it must not call held: a call's result behind a reader (`pair_of(i).fl`), in an arm of a conditional (`i.odd? ? floats(i) : fb`) and on one side of an `||` (`floats(i) || fb`). On master it ends in a segmentation fault in a plain run and at level 1, and raises at level 2, built with gcc or clang; the three last sources alone are wrong there too, the two conditionals in a plain run and the reader's at level 2. `test/typed_array_boxed_source_own_index.rb` is the program above with its own `Array#[]`, into a rest parameter and into `%`: master prints 1 and 22 wrong answers of 300 in a plain run, 239 and 300 at level 1, and raises at level 2.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #

The `.expected` files were written from ruby 3.3.6 with `--enable-frozen-string-literal`. No value is past 2^31. optcarrot's generated C did not change. This depends on no other pull request.
