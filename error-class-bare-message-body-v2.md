<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class ValErr < StandardError
  def shout = message.upcase
end
begin
  raise ValErr, "m"
rescue ValErr => e
  p e.shout
end
```

compiled, and raised NameError (undefined local variable or method 'message') when `shout` ran. CRuby prints `"M"`, and so did `self.message`. In two positions it was not even the NameError: `message.bytes.sum` printed `nil` and `@memo ||= message` stored `0`.

A receiverless call is resolved against the Ruby methods of self's class, and `Exception#message` is not one of them. A builtin exception's reopening already gives such a call its self; a class the program derives from an exception was not given it.

The bare `message` now takes self as its receiver in an instance method of such a class. It is left as it was where the program answers the name itself (a method or a reader called `message` in the class, an ancestor or a descendant, a descendant's own `to_s` or an undef of either, a free function of either name), and inside a block, whose self may be another object.

With its receiver the call answers what `self.message` answers today, right or not: `message.frozen?` is false where CRuby says true, `message.equal?(message)` is true after a bare `raise ValErr`, and a message built in `initialize` (`super(what + " not found")`) can be read after it is freed under `SPINEL_GC_STRESS=2`. An `initialize` that does not call `super`, or reads `message` before it does, gets `""` where CRuby has the class name. The generated C for these is the C of the `self.message` spelling, byte for byte.

Not changed: a bare `backtrace`, `cause`, `full_message` or `detailed_message` in such a class is still the NameError.

Test: `test/exception_subclass_bare_message.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
