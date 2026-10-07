<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

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

Stated width: the answer changes only in a program where nothing can change
what `respond_to?` says, give one class's name to another, or leave the call
it guards without an arm. `prog_exception_names_plain` reads the program
once a compile for that (the commit message lists what it looks for), and
every other program keeps the C it had and the false it had, also where
CRuby says true: a class under `Errno::ENOENT` or `App::Error`, a class with
a `respond_to?` or a `new` of its own. In a family of 2,938 one-case
programs the scan holds 1,014 back: 399 need it (without it 381 print a
wrong line and 18 do not build), 184 would have been right, 217 are right
either way, 210 wrong either way, and 4 are wrong with it and do not build
without it.

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
`test/exception_class_responds_to_guarded_bare_call.rb`,
`test/exception_class_responds_to_own_new.rb`,
`test/exception_class_responds_to_path_class.rb`,
`test/exception_class_responds_to_path_superclass.rb`,
`test/exception_class_responds_to_aliased_class.rb`. The first fails on
master; the other six are programs the conditions hold back, right on
master and kept so.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
