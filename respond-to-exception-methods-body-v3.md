<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Stated width: the answer changes only in a program where nothing can change
what `respond_to?` says or leave the call it guards without an arm (the four
conditions below). Every other program keeps the C it had, and the false it
had. In a family of 2,938 one-case programs the conditions hold 1,014 back:
399 need it (with the conditions dropped, 381 print a wrong line and 18 do
not build), 184 would have been right, 217 are right either way and 214
wrong either way.

`respond_to?` was false for every method Exception gives, on an instance of
a class the program puts under a builtin exception.

```ruby
class MyErr < StandardError; end
e = MyErr.new("q")
puts(e.respond_to?(:message) ? e.message : "no message")
# Spinel "no message", CRuby "q"
```

That is a typed instance (`MyErr.new`, `rescue MyErr => e`) and one boxed
without having been raised. Exception's methods are the runtime's and stand
in no method table. `class_implicit_responds`, the one list the typed fold
and the check for a boxed receiver both read, had the names Comparable,
Enumerable and a Struct bring and not Exception's. It has `message`,
`full_message`, `detailed_message`, `backtrace` and `cause` now.

`prog_exception_names_plain` reads the program once a compile, and the five
names join the list only when:

- no def, Symbol or String spells `respond_to?`, `respond_to_missing?`,
  `method_missing`, a hook (`inherited`, `included`, `extended`,
  `prepended`, `method_added`), `private`, `protected`, `module_function`,
  `undef_method`, `remove_method`, `send`, `__send__`, `public_send` or an
  eval, and no call evaluates a block as another object;
- a call that takes a method name (`private`, `undef_method`,
  `alias_method`, `define_method`, `attr_reader`, `send`, `method`, ...) is
  given literal names only, none of them Exception's own; `undef` and
  `alias` name none; no Symbol held in a variable is passed as a block or to
  `inject`;
- no def of one of the five stands in a program with a bare `private`,
  `protected` or `module_function`;
- each of the five is called on a receiver other than self, with no block,
  and with no argument but the keywords a rendering takes.

So a subclass that hides `message`, a class with a `respond_to?` of its own
and a guarded call that has no arm (a bare `message` in the class's own
method, `method(:message)`, `instance_eval`) all answer what they answered.

Only those five names: they are the ones such an instance can be called
with both typed and boxed. `backtrace_locations`, `exception` and
`set_backtrace` still answer false where CRuby says true, because the call
is not there yet on one or the other, and a true would lead a guarded call
into NoMethodError.

Compile time: the scan is one pass over the nodes, made the first time such
a `respond_to?` is compiled. On a program of 8,007 lines it is 0.024% of
the compile (callgrind: 67,289,280,583 instructions against
67,272,815,106).

Not here, each as on master:

- the names a builtin parent adds (KeyError's `key` and `receiver`);
- a raised exception kept as a boxed value, which answers from the
  runtime's own list.

Depends on the pull request that lets `full_message` and
`detailed_message` take the keywords asking for the bare call's text: a
guarded `e.detailed_message(highlight: false) if
e.respond_to?(:detailed_message)` reaches a call that answers only above
it.

Test: `test/exception_class_responds_to_exception_methods.rb`,
`test/exception_class_responds_to_hidden_name.rb`,
`test/exception_class_responds_to_guarded_bare_call.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
