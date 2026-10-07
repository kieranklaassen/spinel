<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Img
  def initialize(x, y = "c" * 2, z = "d" * 2)
    @v = [x, y, z]
  end
  def ok?(i) = @v[0] == i && @v[1] == "cc" && @v[2] == "dd"
end
class Other
  def initialize(x) = (@x = x)
  def ok?(i) = @x == i
end
kl = [Img, Other][0]
bad = 0
keep = []
i = 0
while i < 300_000
  o = kl.new(i)
  keep << [o, i] if i % 7 == 0
  bad += 1 unless o.ok?(i)
  i += 1
end
bad2 = 0
keep.each { |o, n| bad2 += 1 unless o.ok?(n) }
p bad, bad2, keep.size            # 0, 0, 42858 in CRuby; 1, 0, 42858 on master
```

`spinel diff` on master: output-diff, `1` for `0`; on this branch: same. That is a plain run, gcc and clang alike. Under `SPINEL_GC_STRESS=2` a single `kl.new(1)` aborts ("the mark reached a freed slot"), and so do `kl.new("z" * 2)` into `def initialize(x)` and two lines of `test/class_value_new_rest_posts.rb` (`L[4].new(10)`, the empty `**kw`).

Cost by callgrind, a million `new`: two defaults that allocate 1,092,292,657 to 1,122,500,798 (30 instructions a call); an empty `**kw` 1,077,610,794 to 1,090,306,984 (13); a fresh argument to a boxed receiver 300,598,516 to 303,627,876 (3); the two defaults through a class's own `self.new` 939,510,403 to 965,575,222 (26). An arm that builds nothing (arguments in locals, defaults that are numbers) is the same C.

`k.new(...)` on a Class value is a switch with one constructor call an arm. Three kinds of value stood fresh, held by nothing, inside or ahead of that call: the argument temps of a boxed receiver (the Class-typed form roots its own); a default the call leaves out, spelled in the arm's call; and the empty Hash of a `**kw`. The next one's allocation, or the constructor's own allocation of the object, collected them.

A fresh argument of the boxed form is now rooted as the Class-typed form's is. A value the arm builds is bound to a rooted local in the arm's prefix, as the arm's rest already is (`ctor_arm_hold`): in the two positional arms, in the arm of a class's own `self.new`, and in `raise k`. Only a default that may allocate, into a parameter whose type takes a root, is bound; an arm whose defaults read an earlier parameter binds every value already and is as it was.

`make cident` against the pull request below: the two tests of the pair and six corpus tests differ. Each has a class value `new` whose arm builds a default, an empty `**kw` or a fresh argument, and that value is now a rooted local of the arm. All six print the same in a plain run; `test/class_value_new_positional_ctor_param.rb` aborts under `SPINEL_GC_STRESS=2` below this and is right here.

Not here, the same on master:

- a rest handed to `new` (`def initialize(x, *r)`, `k.new(1, "a" * 2)`, `k.new` with nothing for the rest): the rest Array itself is not held. That is "A rest array handed to new is held while the object is allocated".
- a default a spread does not reach (`k.new(*xs)`, `k.new(**h)`): "A default a spread does not reach is held while the next argument is built".

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (the pull request "A class-value new runs the defaults of the class it builds": this binds values in the arm's prefix that one makes)
