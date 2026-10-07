<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Stated cost: the answer goes by the class Spinel raised, and five raise
sites raise another class than CRuby does. For the class Spinel raises
there, `instance_of?(k)` answered false, which was right by accident, and
answers true now, as `instance_of?` with the class written out already
does:

```ruby
kept = []
begin; File.read("/etc/passwd/x"); rescue Exception => e; kept << e; end
k = RuntimeError
p kept.map { |x| x.instance_of?(k) }    # CRuby [false]; was [false], now [true]
```

| the raise | Spinel raises (`k`) | CRuby raises |
|---|---|---|
| `File.read("/etc/passwd/x")`, a path through a file | RuntimeError | Errno::ENOTDIR |
| `case {a: 1}; in {b:}; end` | NoMatchingPatternError | NoMatchingPatternKeyError |
| `"a".setbyte(5, 1)`, a frozen literal | FrozenError | IndexError |
| `Timeout.timeout(0.01) { sleep 1 }` | NameError | Timeout::Error |
| `raise UncaughtThrowError, "m"` | UncaughtThrowError | ArgumentError |

A boxed exception asked `instance_of?` with its class as a value (a local, a
parameter, an instance variable, an element, or a path such as
`App::Missing`) answered false.

```ruby
kept = []
begin; raise ArgumentError, "m"; rescue => e; kept << e; end
k = ArgumentError
p kept.map { |x| x.instance_of?(k) }    # Spinel [false], CRuby [true]
```

That arm compares `sp_poly_get_class`'s id with the class value's, and
`sp_poly_get_class` has no id for a boxed exception, which carries its class
by name: it answers Object. `is_a?(k)` beside it goes through
`sp_poly_is_a`, which reads the name. For a boxed exception the arm now asks
`sp_poly_is_a_dyn` for the exact class, where the class value is one with an
id and no name of its own, as a constant's is. Every other value takes the
id compare it took.

A class read off an object (`k = other.class`) takes that compare too. Such
a class value carries a name on the heap that nothing roots, so the name
may not be read once the exception it came from is gone.

Cost, in instructions a test over master's (callgrind, 200,000 tests each):
a boxed raised exception about 200, hit or miss (the class's name is looked
up and compared); a boxed String, a boxed Integer and an object of the
program's own class never raised, 3.

Not here: the test with a class read off an exception is master's, and
wrong there in its own ways. `k = other.class` answers false for an
exception of that same class, and true for an object of the first class
the program defines.

Test: `test/boxed_exception_instance_of_class_value.rb`,
`test/boxed_exception_instance_of_class_read_off.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
