<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
module Net;  class Error < StandardError; end; end
module Disk; class Error < StandardError; end; end
begin
  raise Net::Error, "down"
rescue => e
  p e.is_a?(Net::Error)   # false; CRuby prints true
end
```

`kind_of?` and `instance_of?` did the same, and so did the bare `Error` inside `module Net`, with a second class of the name or without one. An exception answers by its class's Ruby name (`"Net::Error"`), and the arm compared the text of the argument's path: for a leaf two modules share, `qualify_colliding_classes` has renamed it, so the path read `"Net::Net__Error"`, and a bare name read `"Error"`. No exception carries either.

The exception arm now asks the class table for the name, as the `when` arm does (`exc_when_cls_name`), where the path as written is that class: read from the program's level, or from a class or module body the call stands in. Every other argument compares as its text, as before:

- in a program that writes a constant named as one of its classes or modules, or holding one (`Error = Plain` or `Error = Class.new(StandardError)` beside `Net::Error`, `Net = Disk`, a `const_set`): the name may be bound to another class than the table's;
- a path read from a body, when two modules have its first name (`Net` and an included `Mixin::Net`): Ruby may find the other through an include or a superclass;
- in a method an `include` copied into a class: the body it was written in is not kept with the copy;
- a builtin exception's name, and a path under one of CRuby's namespaces (`Errno::ENOENT`).

Not here:
- A class reached only through a superclass or an included module (`Error` in `class Sub < Base` for `Base::Error`) compares as text, as do the cases above; where master answered wrong for them it still does.
- An exception of a class made by `Class.new(Net::Error)` still answers false for `is_a?(Net::Error)`.

Compile time, instructions of `spinel -S` under callgrind, master and here: two modules of 2,000 classes each and 4,000 questions naming them, 10,119,658,188 and 10,143,402,188 (+0.23%); the same size with every question naming a top-level class, where the C does not change, 5,349,667,465 and 5,350,979,539 (+0.02%).

Measured on 42557a3c0e7c against CRuby 3.3.6 with 4,979 generated programs that each print rows of answers (the name bare, as a path and rooted; asked from the program's level, a module, a nested class, a block, a lambda, `class << self`, `class A::B`, a copied method; beside a constant, a second module, an included module or a superclass holding the name; beside a constant made by `Class.new`, at the program's level, in an inner module, a class, a superclass). The C changes in 997: 877 answers go from wrong to right, none from right to wrong, the 51 programs that stop on master stop the same way and 8 stay wrong with master's output. `tools/cident.sh` against master: 6471 identical, 1 differ (`test/exc_is_a_same_leaf.rb`), 0 refusal changes.

Tests: `test/exc_is_a_same_leaf.rb`, 5 of its 6 lines different on master; `test/exc_is_a_bare_name_constant.rb` and `test/exc_is_a_class_new_constant.rb` hold the programs left alone and pass on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
