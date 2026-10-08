<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Stated cost: in a program where a class of its own has a `!=` of its own, a
boxed `!=` costs 24 instructions more on an Integer receiver, 27 on a String
and 60 on an object of another class (53 fewer on one of the class). A
program with no such class emits the C it did.

A class's own `!=` was not asked when the receiver was boxed.

```ruby
class Tok; def !=(o) = true; end
xs = [Tok.new, 3]
p xs[0] != xs[0]    # Spinel false, CRuby true
```

`x != y` on a boxed `x` was `!sp_poly_eq(x, y)`, which asks the class's `==`
and never its `!=`; a typed receiver calls the method. The operator table a
boxed receiver's other operators go through (`sp_user_binop_dispatch`) has
an arm for `!=` now, and a boxed `!=` asks it first (`sp_poly_ne_own`,
emitted for such a program alone); `!sp_poly_eq` answers as before for every
other receiver. It is asked only where the boxed compare was that generic
one: an operand with an arm of its own, nil or a Bignum, keeps the arm. And
"of its own" is a `!=` written under that name in a class or module of the
program's, in the chain of a class the program instantiates: one written on
`Object`, `Numeric`, `Kernel` or `Comparable`, at top level or by an alias
is not asked, and such a program emits the C it did.

A rescued exception read by a bare rescue is boxed too. For a `MyErr` whose
`!=` says true, `e != ks[0]` and `e != e` are true as in CRuby (they were
true and false).

Not here, each as it was: `xs[0] != nil` and `xs[0] != big`, by the arms
above; an operand the parameter does not take (`xs[0] != 3` where `!=` reads
`o.v` and every call seen passed a Tok); a `!=` that answers a value other
than true or false, read for its truth at a boxed call; a rescued exception
as the receiver where its class has an instance variable or its `!=` was
only ever passed one class.

Test: `test/boxed_ne_asks_own_method.rb`. Right before and kept so:
`test/boxed_ne_on_object_left_alone.rb`, `test/boxed_ne_on_numeric_left_alone.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
