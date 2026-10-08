<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
module Slow;  LIMIT = 1; end
module Fast;  LIMIT = 2; end
module Tuned
  include Slow
  include Fast
end
module Logged
  include Slow
end
class Job
  include Tuned
  include Logged
  def limit = LIMIT
end
p Job.ancestors.first(5)   # [Job, Logged, Tuned, Fast, Slow]
p Job.new.limit            # 1; CRuby prints 2
```

A name several bodies define is looked up through the ancestors of the body that reads it (`qc_ancestor_lookup`), and that walk takes each included module with all it includes before the next one: `Logged` and its `Slow` before `Tuned`. CRuby keeps one list a class, and a module the class or a superclass holds already is not put in again: `Slow` stays behind `Fast`, as the `ancestors` line says. The same happened for a module the superclass includes (`class Worker < Base; include Defaults`, where `Base` includes `Defaults` and writes the name itself), and for a class two modules both name (`Box.new`).

`qualify_colliding_consts` and `qualify_colliding_classes` now build CRuby's list of the modules behind each body (`qc_order_build`): the include statements are run in the order they stand, as `rb_include_module` merges a module's list into a class's, and a read through the ancestors takes the first write on that list.

The list is built only where the statements give it. Two include arguments share a name (without that the two orders are one). Every include is a plain statement of a class or module body in the program's own file, and the statements ahead of the last one only define: nothing of the program has run. The program has no `prepend`, no hook (`included`, `inherited`, `const_added`), no `class_eval`, `const_set` or `remove_const`, and no include on a receiver, in a block or in a method. No include goes to a module that is mixed in already (CRuby adds it to every class holding the module), to a reopened builtin or to a `BasicObject` subclass. Every other program, and a read in a `class << self` body, is answered by the walk: master's C.

Not here:
- `Job::LIMIT`, the same read as a path, still raises NameError.
- A read in a `class << self` body still looks in what the class mixes in; CRuby does not.
- A program whose includes are spread among statements that run (a `puts` between two class bodies) keeps the walk's order.

This stands above "A constant's lookup walks each included module once" (the same function; the walk keeps its mark). Compile time, instructions of `spinel -S` under callgrind, on that commit and here:

| program | below | here |
|---|---|---|
| a diamond of includes, 22 levels | 63,664,851 | 64,743,980 |
| 26 levels | 77,209,712 | 78,518,340 |
| 30 levels | 92,115,172 | 93,561,218 |
| 300 modules each including one module, all in one class | 1,192,840,836 | 1,201,194,040 |
| 500 modules in a chain | 2,276,875,270 | 2,277,314,299 |
| 500 modules in one class | 2,905,922,996 | 2,906,896,707 |
| 500 classes writing the name, no include | 1,379,253,050 | 1,379,523,864 |

The C of all seven is unchanged. The diamonds take 0.01 s of user time at each size, as below; master takes 2.23 s at 22 levels.

Measured on 8dc5522541bb against CRuby 3.3.6 with 9,301 generated one-answer programs (include graphs with diamonds, repeats, superclasses, reopenings, namespaces, nested classes, `Struct.new`, and the things that leave a program alone: a statement that runs, a hook, a `prepend`, a required file). The C changes in 1,949: 689 go from wrong to right, 1,232 are right on both, 28 stay wrong with master's output, and none goes from right to wrong or from stopped to a wrong answer. In the 153 programs checked for it, the list built equals CRuby's `ancestors` for every class and module. `tools/cident.sh` against the commit below: 6447 identical, 1 differ (the new test), 0 refusal changes.

Test: `test/const_read_include_order.rb`, all 3 lines different on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
