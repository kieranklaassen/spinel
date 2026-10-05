<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Before:

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

After: `2`.

A class whose superclass includes a module has it in its chain once, behind that superclass, and its own `include` of the module adds nothing. The module's methods were copied into the subclass all the same, in front of the copies the superclass holds, so a method of the module that calls `super` ran once for each copy, and a block it gives to `super` ran in each.

How: `process_include_body` leaves a module alone that a superclass includes by the time the class's own `include` is reached, directly or through a module that includes it. The class still records the module, so `is_a?`, `include?` and `rescue Plus` answer as before. Where the class includes the module first and its superclass is reopened to include it later, CRuby has the module in the chain twice, and so does this.

Left as on master, each wrong today and with the same C: `Child.ancestors` lists the module at both classes; a module that reaches the subclass through another module (`module Wrap; include Plus; end` included in Child) still runs twice; so does `extend Plus` in both classes.

Measured on master fa08b100 with gcc 13 against CRuby 3.3.6, 5,880 programs (12 arrangements of the module in a class and in classes under it, 7 parent bodies, the module's method calling `super` in 7 ways, 5 forms of the class's own method, with and without a direct call of the parent): the C of 2,940 changes. 198 wrong answers and 12 build failures are right now, 504 are right before and after, 2,226 do not build before or after, and no program that is right on master is lost.

Generated C against master fa08b100 (`make cident`): 6,111 programs identical, 1 differs (`test/include_superclass_has_module.rb`), no refusal changes. optcarrot's C is identical. On 9c4eec71 the commit picks without conflict; the test fails there (7 of 16 lines) and passes with it.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
