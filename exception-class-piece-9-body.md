<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A program that names a class of its own `SumState` or `Addrinfo` did not
build: the C compiler stopped.

```ruby
class SumState
  def initialize(total) = @total = total
end
SumState.new(1)
# error: conflicting types for 'sp_SumState'; have 'struct sp_SumState_s'
```

The runtime has C types of those two names: the accumulator of `Array#sum`
and `Enumerable#sum`, and the socket address carrier.
`sp_name_collides_runtime` gives a program's class another C name where it
meets one of the runtime's (`Tms`, `SockOpt`, `Random` are there already),
and these two were not on its list. Of the runtime's type names that are
no Ruby class's, they are the two that were missing.

`Addrinfo` under `require "socket"` is the socket class, as before: a
reopening of it is refused by name, and a class of that name in a module of
the program's (`Net::Addrinfo`) now builds beside it.

Test: `test/class_named_as_runtime_type.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
