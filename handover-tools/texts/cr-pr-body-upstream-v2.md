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

A name several bodies define is looked up through the ancestors of the body that reads it (`qc_ancestor_lookup`), and that walk takes each included module with all it includes before the next one: `Logged` and its `Slow` before `Tuned`. CRuby keeps one list a class, and a module the class or a superclass holds already is not put in again: `Slow` stays behind `Fast`. The same happened for a module the superclass includes, and for a class two modules both name.

`qualify_colliding_consts` and `qualify_colliding_classes` now build CRuby's list of the modules behind each body (`qc_order_build`): the include statements are run in the order they stand, as `rb_include_module` merges a module's list into a class's, and a read through the ancestors takes the first write on that list.

The list is built only where the statements give it: two include arguments share a name; every include is a plain statement of a class or module body in the program's own file, and the statements ahead of the last one only define; no `prepend`, hook, `class_eval`, `const_set` or `remove_const`; no include to a module mixed in already, to a reopened builtin or to a `BasicObject` subclass. Every other program, and a read in a `class << self` body, is answered by the walk: master's C.

Not here:
- `Job::LIMIT`, the same read as a path, still raises NameError.
- A read in a `class << self` body still looks in what the class mixes in; CRuby does not.
- A program whose includes are spread among statements that run keeps the walk's order.

This stands above "A constant's lookup walks each included module once" (the same function).

Compile time, the compiler's instructions under callgrind against that commit, the C the same in every row. A program with two include arguments of one name whose statements only define pays for the lists, whether a read then uses them or not: +0.70% (300 modules each including one module, all in one class) to +1.74% (a diamond of includes 22 levels deep). One that is left to the walk pays for two flat scans and one pass over its statements: +0.18% with a `puts` ahead of the last class, +0.07% with a hook or a `prepend`. A program with no two such arguments: +0.01%.

Measured on 8dc5522541bb against CRuby 3.3.6 with 9,301 generated one-answer programs (include graphs with diamonds, repeats, superclasses, reopenings, namespaces, nested classes, `Struct.new`, and what leaves a program alone). The C changes in 1,949: 689 go from wrong to right, 1,232 are right on both, 28 stay wrong with master's output, none goes from right to wrong. In the 153 programs checked for it, the list equals CRuby's `ancestors` for every class and module. `tools/cident.sh` against the commit below: 1 differ, the new test.

Test: `test/const_read_include_order.rb`, all 3 lines different on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: the pull request "A constant's lookup walks each included module once"
