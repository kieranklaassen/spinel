<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`respond_to?` was false for every method Exception gives (`message`,
`backtrace`, `cause`, ...) on an instance of a class the program puts under
a builtin exception: a typed one (`MyErr.new`, `rescue MyErr => e`) and one
boxed without having been raised.

```ruby
class MyErr < StandardError; end
e = MyErr.new("q")
puts(e.respond_to?(:message) ? e.message : "no message")
# Spinel: no message; CRuby: q
```

Those methods are the runtime's and stand in no method table.
`class_implicit_responds`, the one list the typed fold and the check for a
boxed receiver both read, had the names Comparable, Enumerable and a Struct
bring and not Exception's. It has `message`, `detailed_message`, `backtrace`
and `cause` now for a class under a builtin exception, unless the class took
the name away (`undef_method`) or made it private.

Only those four: they are the ones such an instance can be called with both
typed and boxed.

Not here:

- `full_message`, `backtrace_locations`, `exception` and `set_backtrace`
  answer false where CRuby says true, because the call is not there yet (on
  a typed value for the first two, on a boxed one for all four), and a true
  would lead a guarded call into NoMethodError.
- `respond_to?(:message, true)` for a name made private is still false, and
  so is a bare `respond_to?(:message)` inside the class's own method.
- The names a builtin parent adds (KeyError's `key` and `receiver`).
- A raised exception kept as a boxed value answers as before, from the
  runtime's own list.
- A class whose own `initialize` hands `super` an interpolated String loses
  that message under `SPINEL_GC_STRESS=2`; a call guarded by
  `respond_to?(:message)` now reaches it there, as the bare call does.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
