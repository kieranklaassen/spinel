<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
module Plus
  def count
    super + 1
  end
end
class Root
  def count
    1
  end
end
class Parent < Root
  include Plus
end
class Child < Parent
  include Plus
end
p Child.new.count    # 3; CRuby prints 2
```

A class whose superclass includes a module has it in its chain once, behind that superclass, and its own `include` of the module adds nothing. The module's methods were copied into the subclass all the same, in front of the copies the superclass holds, so a method of the module that calls `super` ran once for each copy.

`process_include_body` now leaves a module alone that a superclass includes by the time the class's own `include` is reached. The class still records the module, so `is_a?`, `include?` and `rescue Plus` answer as before. Where the class includes the module first and its superclass is reopened to include it later, CRuby has the module in the chain twice, and so does this.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
