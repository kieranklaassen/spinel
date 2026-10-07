<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

An exception of a class of the program's own, raised and rescued and then kept
as a boxed value (an element of an Array, a parameter of mixed type), answered
false to `is_a?`, `kind_of?` and `instance_of?` for that class, and never
matched a `when` arm naming it.

```ruby
class MyErr < StandardError; end
kept = []
begin; raise MyErr, "a"; rescue StandardError => e; kept << e; end
p kept.map { |x| x.is_a?(MyErr) }    # Spinel [false], CRuby [true]
```

`emit_poly_isa_test` and the `when` class test compare the boxed value's class
id with the ids of the class and its subclasses. A raised exception is an
`sp_Exception` boxed as `SP_BUILTIN_EXCEPTION`, and it carries its class by
name, so no id matched. For an exception class of the program's own the test
now has a second arm that asks a boxed exception by name, as the arm for a
builtin exception class does.

The class-id arm is as it was: an exception never raised (`MyErr.new` kept in
the Array) is boxed as an object of its class and answers as before, and a
test for a class that is no exception emits the same C.

Left alone: `x.instance_of?(k)` with the class in a variable or written as a
path (`App::MyErr`) is still false for a boxed raised exception, of a builtin
class too; that test goes through `sp_poly_get_class` and is its own fault.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
