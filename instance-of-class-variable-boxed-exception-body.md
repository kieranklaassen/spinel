<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

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
`sp_poly_is_a_dyn` for the exact class, as the arm for a receiver of a
builtin type does; every other value takes the id compare it took.

Not here: an exception of the program's own class that was never raised
(`MyErr.new` kept in the Array) is boxed as an object of its class, and
asked with a class read off an exception (`k = other.class`) it still
answers false. Under `SPINEL_GC_STRESS=2` a class read off a raised
exception does not keep its name, and `instance_of?(k)` with it answers
false there as before.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
