<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
module Scaled
  def area(k) = k * 2
end
class Tile
  include Scaled
  def initialize(w); @w = w; end
  def area(k) = super(k + @w) + 1
end
p Tile.new(3).area(1)   # 9
```

did not build: `error: cannot convert to a pointer type`.

A class whose instance variables are scalars written only in `initialize`, and that has no subclass, is held by value: its methods take the object itself, not its address. `emit_super` wrote the call into the module's copy with `self` cast to a pointer, as for every other class. Where the calling method has the object by value, it now hands it over as it is.

The same for a `super` between two modules' methods in such a class (`include Scaled; include Doubled`, `Doubled#area` calling `super`), and for one inside a block or a proc. Only that argument changes, and only in C that did not compile.

Not here:
- A `super` from `initialize` into a module's `initialize` in such a class still does not build: `initialize` has the address and the copy takes the object.

Measured on 5d762fb16716 against CRuby 3.3.6, with 2,826 generated one-answer programs (the instance variable an Integer, a Float, `true`, a String, two of them, none, one written outside `initialize` or in a later reopening, a subclass later in the file, a `Struct.new` block, a class under `Struct.new`, a `Data.define` block; fourteen method shapes: no argument, an argument, bare `super`, a keyword, optional and keyword arguments under bare `super`, a rest, a block passed on, a block given to `super`, `super` inside a block, `==`, `to_s`; the class's method into one module, into two, a module's into another's; the receiver direct, a local, a copy; `initialize` into a module's). The C changes in 420, all of them no build on master: 400 are right, 20 (the `initialize` ones) still do not build. The 2,406 others compile to master's C. `tools/cident.sh` against master: 6495 identical, 1 differ (the new test), 0 refusal changes.

Test: `test/super_into_module_by_value.rb`, does not build on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
