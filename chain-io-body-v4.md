<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

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

`process_include_body` no longer copies such a method where a superclass includes the module by the time the class's own `include` is reached and the method asks nothing of its receiver: no instance variable, no `self`, no call without a receiver (`module_function_self_dependent`). It runs the same in the copy the superclass holds. Every other method is copied as before, because the copy is typed by the class's own methods: a module's `walk` over an `each_item` the subclass overrides needs it.

The class still records the module, so `is_a?`, `include?` and `rescue Plus` answer as before. Where the class includes the module first and its superclass is reopened to include it later, CRuby has the module in the chain twice, and so does this.

Not here:

- A method that calls `super` and also asks its receiver something still runs once for each copy.
- `ancestors` still lists the module in front of the superclass too (`[Child, Plus, Parent, Plus, Root]`; CRuby has `[Child, Parent, Plus, Root]`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
