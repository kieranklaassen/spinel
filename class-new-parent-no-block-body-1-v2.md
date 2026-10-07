<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An exception of a class of the program's own, raised and rescued and then kept
as a boxed value (an element of an Array, a parameter of mixed type), answered
false to `is_a?`, `kind_of?` and `instance_of?` for that class written by its
name, and never matched a `when` arm naming it.

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
test for a class that is no exception emits the same C. So does a program
that defines `is_a?`, `kind_of?` or `instance_of?` itself, or `===` on the
class asked or on one above it: there the answer is the program's to give.

Cost: a test of a boxed raised exception against the program's class now
walks its ancestors by name, as the test against a builtin exception class
does: 320 instructions a test for a class with no subclass and 1,133 with
five (callgrind; `is_a?(KeyError)` of the same values is 1,169 on master),
and 5 more a test for a value that is no exception.

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
