<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A yield in a method the program reaches only through a child's `super` kept the type of the first call site's block: the program below prints a wrong answer, and others like it segfault or do not build. Cost: compile time, and only in a program with such a method. The pass that reads the children's call sites runs for a method that no call names and a `super` lands on; every other method is one table lookup. Four programs of 250 classes that call `super` into one parent that yields compile in 0.16% to 0.72% more instructions, their C unchanged; three of 250 classes without such a parent compile in the instructions they did (numbers below).

```ruby
class Reader
  def read(key)
    value = fetch(key) { |k| yield k }
    [value, key]
  end
  def fetch(key) = yield(key)
end
class Cached < Reader
  def read(key) = super
end
p Cached.new.read(2) { |k| nil }     # [nil, 2]
p Cached.new.read(3) { |k| k.to_s }  # [nil, 3]; CRuby prints ["3", 3]
```

The same in an `initialize`, through `super(key)`, `super(key, &b)` and two links of bare `super`. With a String site, a nil one and then an Integer one the `initialize` form segfaults; other pairs of blocks stop the C build, are refused, or raise TypeError.

A method that yields is spliced into each call site. Where the sites' blocks answer different types, `infer_yield_node` types the yield poly wherever its value is kept, so that each site boxes its own. `yield_value_diverges` decides that from the method's own call sites, and a method the program reaches only through a child's `super` has none: the yield kept the first site's type and the other sites' values were stored as that.

Where the method's own sites give no type and every `super` that lands on it hands on the block its own method was called with, `yield_value_diverges` now reads the sites of the methods beneath it, in one pass over the calls named like it. Each call is placed on the method it calls (a receiver of one class, or `new` on a constant) and gives its block's type; the types are joined up the `super`s the two ways the method's own sites are, the first site's and all of them, and the yield is poly where the two differ.

The method is typed as before where the pass cannot say: a call named like it that cannot be placed or has no block written at it, a `super` that writes a block (`super(key) { |k| ... }`) or passes another proc, which hands up that one and not the caller's, or a `super` out of a method of another name. Every other method is asked as before and its C is unchanged.

Compile time, one compile to C under callgrind, before and after:

| program of 250 classes | before | after | |
|---|---|---|---|
| each calls `super` into one parent that yields; one site each, one type | 10,004,369,393 | 10,030,456,132 | +0.26% |
| one site each, of two types in turn | 9,696,057,093 | 9,713,536,255 | +0.18% |
| two sites a class, of two types | 19,073,745,536 | 19,210,184,617 | +0.72% |
| two sites a class, of two types, the value of the yield not kept | 16,636,900,804 | 16,663,304,462 | +0.16% |
| no such parent (three programs) | 3,209,268,071 | 3,208,752,767 | |
| | 8,500,950,789 | 8,499,850,851 | |
| | 9,115,534,986 | 9,100,725,918 | |

The four above run right before and after and their C is the same: the cost is the pass reading each site's block, which is what `yield_value_diverges` does for a method called by name. Where each `super` lands is looked up once and kept while the tables stand.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
