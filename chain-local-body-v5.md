<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
module Doubled
  def total(a)
    twice = a * 2
    twice + super(a)
  end
end
class Plain
  prepend Doubled
  def total(a)
    a + 100
  end
end
p Plain.new.total(3)    # does not build: 'lv_twice' undeclared; CRuby prints 109
```

A local written in a method of a prepended module had no slot, with a `super` in the method or without one, and the C did not build. Where the local's type was needed first, the program was refused instead ("unsupported comparison" for a loop counter).

`process_prepend_body` copies the module's method in front of the class after `register_locals` has run, and the locals the copy writes were never interned. The include and extend clones call `register_locals` again for this, and `register_prepends` now does too when it made a copy.

A program that did not build for this and also meets another prepend fault now builds and shows that fault, as the same program without the local does today: a module named twice in `prepend`, or prepended by a class and included by its subclass, runs once too often, and `prepend A, B` puts B in front. Two later pull requests cure those. A program that also relies on `method_missing` in the prepended class's chain raises NoMethodError by name where it did not build, as the same program without the local raises today.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
