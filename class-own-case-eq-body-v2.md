<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`Klass === x` answered `x.is_a?(Klass)` for a class that defines `===` itself.

```ruby
class Even
  def self.===(o) = o.is_a?(Integer) && o.even?
end
p([4, 3, "x"].map { |v| Even === v })
p(Even === Even.new)
```

Master (42557a3c) prints `[false, false, false]`, `true`. CRuby prints `[true, false, false]`, `false`.

`emit_call_class_value_arms` folds `Klass === x` to `sp_poly_is_a` for every class of the program, and `infer_class_module_call` types the call a boolean. The class's own `===` was compiled and never called. The ordering operators beside it already stand aside for a class's own method (`def self.<(o)`), and the class-method dispatch calls it. `===` now does the same in both places, so the call has the method's own type. `class_recv_own_eqq` finds the method: `def self.===`, `class << self`, a module's own, one that `extend` brings, an inherited one.

The method is asked where its parameter is boxed: the calls pass more than one kind of value, or a boxed one. Where every written call passes one type (`Even === 4` and nothing else) the parameter has that type and the fold stays, master's C. The body compiled for one type can stop where CRuby answers (`o.equal?(self)` for a Symbol raises NoMethodError today), and a program the fold answered right would stop with it.

A `===` that calls `super` with no `===` of the program above it means Module#===, which only the fold answers. Such a class keeps the fold, as on master.

A class with no `===` of its own is not touched: its C is master's.

Not here:

- `case x when Klass` and `in Klass` still fold, as do `grep(Klass)` and `any?(Klass)`: each a pull request of its own.
- The class's `===` is now run, so a fault inside its body is reached where the fold answered. One is known, Class#dup: `o.dup` of a boxed value that holds a class hands back the class itself, so `def self.===(o) = o.dup.equal?(self)` asked with its own class answers `true`. The fold answered `false`, as CRuby does: 2 lines of the programs tried. The same body under a plain name (`def self.ask(o)`) answers `true` on master.

No program of the corpus changes its C (`tools/cident.sh`: 1 differ, the new test).

Test: `test/class_own_case_eq.rb`, 35 lines; 13 differ on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
