<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Stated cost: in a program with an exception class of its own that passes
the scan below, a class test of a boxed value costs 14 to 77 instructions
more unless the value is an Integer (table below), and the branch under the
test now runs for a raised exception. A branch that asks the value what
master answers wrongly for every exception of the class is reached there:
`v < 1` raises ArgumentError from the boxed comparison where CRuby raises
NoMethodError, as it already does for a `MyErr.new` kept in the Array. Every
other program emits the C it did.

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
the names of that class and of those under it that the program instantiates,
as a dispatch has an arm only for those.

The class-id arm is as it was: an exception never raised (`MyErr.new` kept in
the Array) is boxed as an object of its class and answers as before.

### Where the arm is emitted

The branch the test guards runs on the value, and master never reached it
for a raised exception; a boxed exception has no arm for much of what a
branch can ask of it. So the arm is emitted only in a program where the name
says the answer and nothing asks the value what master answers otherwise
than CRuby, decided by one scan a compile (`prog_class_test_by_name`; the
commit message has the whole list), and every other program emits the C it
did. The scan is wider than it has to be, on purpose:

- the word `is_a?`, `kind_of?`, `instance_of?`, `===` or `exception` as a
  `def` anywhere, a Symbol or a String withholds the cure, and so does a
  `define_method`, `alias_method` or `send` given a name that is not a
  literal;
- a class written `module App; class MyErr` is cured; one written
  `class App::MyErr` is kept under its last name, and any class or module
  written so withholds the cure, as two classes of one last name do, a
  constant written under a class's name, and `const_set`;
- it reads every file the program compiles, a required library's too:
  `require "set"`, `"benchmark"`, `"net/http"` or `"openssl"`, or a use of
  `Gem::Version`, withholds the cure;
- `raise k, "m"` through a variable withholds it where an exception class
  has ivars and an `initialize`: the runtime builds what is raised so at
  the base size, with no constructor, and a method of the class would read
  past it;
- an attribute written through a boxed value (`v.seen = true`) withholds
  it: that dispatch has no arm for a boxed exception;
- so does an exception class with a method a boxed value is not asked: an
  operator, a method that yields, `method_missing`, a conversion CRuby calls
  by itself (`to_str`, `coerce`, `each`, `hash`), a `super` outside
  `initialize`;
- so does a call, on a boxed or untyped receiver, of a method of Exception
  the boxed arm lacks (`backtrace_locations`, `exception`, `set_backtrace`,
  `methods`, `to_enum`, `extend`, the singleton calls), or of `message`,
  `full_message`, `backtrace` or `cause` with a block;
- so does a boxed value stored into an Array of one kind (`[1] << v`): that
  store is a TypeError when it runs.

The lists cover what is asked of the boxed value and what an exception
class's method asks of itself. They do not cover what else a branch does
with the value, which is the cost stated above.

### Cost

In instructions a test over master's (callgrind, 200,000 tests each). One
name is compared in place; several are one function a class, however often
the class is asked. The arm asks first whether the exception's class is the
program's own, so a builtin exception walks no names.

| the boxed value tested | more than master |
|---|---|
| a raised exception of the asked class, nothing under it | 37 |
| the same, the class with two under it | 47 |
| a raised exception of a class two levels under the asked one | 77 |
| a raised exception of another class of the program | 35 to 72 |
| a raised builtin exception | 17 |
| an object that is no exception | 14 |
| an Integer | 0 |

The generated C of 300 exception classes under one, that one tested 300
times, grows by 2.0%; of 300 classes each tested once, by 3.5%.

### `instance_of?` with the class in a variable

The second commit. `x.instance_of?(k)` compared two class ids, so a raised
exception matched no `k`. Where the first commit's scan passes and the
program has an exception class of its own, the id compare has a second arm:
a boxed exception of the program's is asked whether the name it carries is
the name of the class value, which for a class of the program's own is an id
and gives its name by `sp_class_to_s`. A class read off a value (`x.class`)
carries a name and keeps the answer it had, and so does a builtin exception.
There the test costs 4 instructions more on an Integer or an object that is
no exception, 8 on a builtin exception, 54 on a raised exception of another
class of the program's.

### Not in this change

Each is wrong on master the same way and stays so:

- a module the exception class includes (`x.is_a?(Tagged)`, `when Tagged`):
  a module included after the test ran answered false and must keep doing
  so;
- `x.is_a?(Tag)` where `Tag = MyErr` (`when Tag` resolves the alias and is
  cured);
- `x.instance_of?(App::MyErr)` written as a path, and `x.class <= MyErr`
  for a raised subclass;
- a class raised only through a variable (`[MyErr, KeyError].each { |k|
  raise k }`) and built nowhere else: the program is not seen to
  instantiate it, a dispatch has no arm for it, and the test stays false;
- a class with ivars and an `initialize` raised through a variable, and an
  attribute written through a boxed raised exception: two entries of the
  list above.

Depends on the pull request that builds an exception class with attributes
and no `initialize` at its own size ("An attribute of an exception class
with no initialize is nil until set, and is marked once set"): the branch
reads those attributes through the boxed value, and beneath that change it
would read past the object. The first commit of this branch is that pull
request's, unchanged; the two after it are this change.

Test: `test/rescued_own_exception_boxed_class.rb`,
`test/rescued_own_exception_raised_by_value.rb` and, for the second commit,
`test/rescued_own_exception_instance_of_class_value.rb` fail before this
change. Twelve are programs the scan holds back, right before and kept so:
`test/rescued_own_exception_{own_predicate,shadowed_constant,path_class,const_set,built_method_name,raised_by_value_initialize,attribute_written,foreign_path,operator_or_block,implicit_conversion,typed_array_store,block_on_message}.rb`.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head in a Linux container (gcc 13, clang 18, CRuby 3.3.6): the fifteen new tests pass in twelve cells each (gcc and clang, with and without `--share-strings`, `SPINEL_GC_STRESS` 0, 1 and 2), `tools/gate.rb check` passes with each commit staged, `share-strings-test` and `int-min-test` pass, and against its parent the corpus emits the same C for all but three programs under the first commit (two of the new tests and `test/each_with_object_seed_widens.rb`) and one under the second (its test). The `.expected` files match CRuby 3.3.6 run with `--enable-frozen-string-literal`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the new tests hold none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not: the C is master's byte for byte)
- [x] Depends on: the pull request "An attribute of an exception class with no initialize is nil until set, and is marked once set", whose commit is the first of this branch
