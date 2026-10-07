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

Exception's methods are the runtime's and stand in no method table.
`class_implicit_responds`, the list the typed fold and the check for a boxed
receiver both read, had Comparable's, Enumerable's and a Struct's names and
not Exception's. It has `message`, `full_message`, `detailed_message`,
`backtrace` and `cause` now: the five such an instance can be called with
both typed and boxed.

Stated width: the answer changes only in a program where nothing can change
what `respond_to?` says, give one class's name to another, or leave the
guarded call without an arm (`prog_exception_names_plain`, one pass a
compile; the commit message has the list). Every other program keeps its C
and its false, also where CRuby says true: one `Alias = MyErr`, `class
Foo::Bar`, superclass `Errno::ENOENT`, two classes of one last name, or a
def named `new` anywhere holds back every exception class of the program
(84 of a family of 224 class layouts, each right without the hold).

Not here, each as on master: the names a builtin parent adds (KeyError's
`key`); a raised exception kept as a boxed value, which answers from the
runtime's own list.

Depends on the pull request that lets `full_message` and `detailed_message`
take keywords: a guarded `e.detailed_message(highlight: false) if
e.respond_to?(:detailed_message)` reaches a call that answers only above it.

Test: `test/exception_class_responds_to_exception_methods.rb` fails on
master. Six beside it (`_hidden_name`, `_guarded_bare_call`, `_own_new`,
`_path_class`, `_path_superclass`, `_aliased_class`) are programs the scan
holds back, right on master and kept so.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
