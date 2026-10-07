<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
module Defaults
  def timeout = 5
end
module Fast
  def timeout = 1
end
module Client
  include Defaults
  include Fast
end
module Logging
  include Defaults
end
class Job
  include Client
  include Logging
end
p Job.ancestors.first(5)   # [Job, Logging, Client, Fast, Defaults]
p Job.new.timeout          # 5; CRuby prints 1
```

`include` copies the module's methods into the class, and a later copy of a name takes the place of an earlier one. `Logging` holds a copy of `Defaults#timeout`, so `include Logging` put it over `Fast#timeout`. CRuby leaves out a module the class or a superclass holds already: `Defaults` keeps its place behind `Fast`, as the `ancestors` line says. The same happened for the module itself named again behind one that includes it (`include Titled; include Named`), and for a module a superclass includes, where the copy went over the superclass's own method:

```ruby
module Shape
  def area = 0
end
class Figure
  include Shape
  def area = 1
end
class Circle < Figure
  include Shape
end
p Circle.new.area   # 0; CRuby prints 1
```

`register_includes` now works out CRuby's order of the modules behind each class (`inc_own`), once, when some include names a module held already. Where such an include reaches a class, a name is copied from the def that order gives the class, from the body that defines it. The scopes, the shadow names and the `super` chains are made as before; only the def behind a copy changes.

The order is worked out only where the statements give it: every include and every def is a plain statement of a class or module body in the program's own file, the statements before the last include only define, and the program has no `prepend`, no `extend` but `extend self`, no hook, no `define_method`, `undef` or `class_eval`. A name is corrected only where the def in front calls no `super`, and no reader, writer, alias, `module_function` or def made after the first statement that runs stands on the way. A module keeps the copies it has: what it holds is copied on, and is corrected in the class. Everything else compiles to master's C.

Not here:
- A method that calls `super`, the class's own or the module's in front: the `super` chain through a module held twice is master's.
- `Circle.ancestors` above prints `[Circle, Shape, Figure]` on master and still does.
- A program outside the lines above (a def inside a `Struct.new` block, an include after the first statement that runs, an include in a required file) answers as on master.

Compile time, user seconds of `spinel -S` on master and here: 400 modules in a chain with the first included again, 17.6 and 15.8; 500 modules sharing one of 20 methods, all in one class, 1.2 and 1.1; 1,000 subclasses each including again a module of their superclass, 1.3 and 1.1. A program that names no module twice pays one walk of its class bodies.

Measured on 9274c732eaa2 against CRuby 3.3.6, with 22,950 generated one-answer programs (include graphs with reopenings, namespaces, `include A, B`, readers, aliases, `module_function`, `extend self`, exception classes, operators, `method_missing`, `initialize`, private and protected, late defs, classes holding a module's parts in another order). The C changes in 7,009: 2,769 go from wrong to right, 3,674 are right on both, 562 stay wrong or stopped with master's output, 4 stay wrong with another (a constant read through the includes, a protected method), and none goes from right to wrong or from stopped to a wrong answer. In the 1,456 programs checked for it, the order worked out equals CRuby's `ancestors` for every class and module. `tools/cident.sh` against master: 6418 identical, 1 differ (the new test), 0 refusal changes.

Test: `test/include_module_already_included.rb`, 6 of its 13 lines different on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
