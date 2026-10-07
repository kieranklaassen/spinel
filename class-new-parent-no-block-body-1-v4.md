<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Stated width: the cure is withheld for the whole program where it defines
`is_a?`, `kind_of?`, `instance_of?`, `===` or `exception` anywhere or names
one as a Symbol, or binds a constant twice; 118 of a family's 3,405 programs
stay wrong for that reason alone (below).

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
id with the ids of the class and of those under it. A raised exception is an
`sp_Exception` boxed as `SP_BUILTIN_EXCEPTION`, and it carries its class by
name, so no id matched. For an exception class of the program's own the test
now has a second arm that compares the name a boxed exception carries with
the names of that class and of those under it.

The class-id arm is as it was: an exception never raised (`MyErr.new` kept in
the Array) is boxed as an object of its class and answers as before.

### Where the arm is emitted

The name says the answer only where the test is the builtin one and a
class's name means one class wherever it is written. So the arm is emitted
for such a program alone, decided by one scan a compile
(`prog_class_test_by_name`), and every other program emits the C it did:

- none that defines, aliases or undefines `is_a?`, `kind_of?`,
  `instance_of?`, `===` or `exception`: a `def` of that name anywhere, on
  either side, or the name as a Symbol or a String (`alias`, `undef`,
  `alias_method`, `define_method`);
- none with a constant bound twice: two classes of one leaf name
  (`A::Error` and `B::Error`), a constant written under a class's name, a
  class alias written twice, a constant written any way but `NAME = value`.

This is wider than it has to be, on purpose: an instance `def ===` on any
class, or the word `is_a?` as a Symbol, withholds the cure for the whole
program, and so do two namespaces that each have an `Error`. In a family of
3,405 one-case programs the guard declines 789: in 17 the arm would have
made a right answer wrong, in 118 it would have made a wrong one right, and
the rest answer the same either way.

### Cost

In instructions a test over master's (callgrind, 100,000 tests each). The
names compared are the program's own classes, so a miss costs those
comparisons and no walk up the builtin hierarchy; nothing is allocated.

| the boxed value tested against `MyErr` | more than master |
|---|---|
| a raised `MyErr` (master answers false) | 39 |
| a raised exception of another class, the program's or a builtin | 35 |
| the same, `MyErr` with five classes under it (six names) | 61 |
| a `MyErr` never raised (the class-id arm answers) | 2 |
| a value that is no exception | 5 |

Compiling 300 exception classes with 300 tests costs 1.3% more instructions
where the arm is emitted and 0.05% more where it is not.

The corpus test whose C changes is `test/each_with_object_seed_widens.rb`:
it tests a boxed value against an exception class of its own and gains the
arm.

### Not in this change

Each is wrong on master the same way and stays so:

- a module the exception class includes (`x.is_a?(Tagged)`, `when Tagged`).
  It needs more than a name on the list: a module included after the test
  ran answered false and must keep doing so;
- `x.is_a?(Tag)` where `Tag = MyErr` (`when Tag` resolves the alias and is
  cured);
- `x.instance_of?(App::MyErr)` written as a path, and `x.class <= MyErr`.

Test: `test/rescued_own_exception_boxed_class.rb`,
`test/rescued_own_exception_own_predicate.rb`,
`test/rescued_own_exception_shadowed_constant.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
