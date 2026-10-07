<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Stated cost: in a program where a class has a `!=` of its own, a boxed `!=`
costs 23 instructions more on an Integer receiver, 26 on a String and 59 on
an object of another class (53 fewer on one of the class). A program with no
such class emits the C it did.

A class's own `!=` was not asked when the receiver was boxed.

```ruby
class Tok; def !=(o) = true; end
xs = [Tok.new, 3]
p xs[0] != xs[0]    # Spinel false, CRuby true
```

`x != y` on a boxed `x` was `!sp_poly_eq(x, y)`, which asks the class's `==`
and never its `!=`; a typed receiver calls the method. The operator table a
boxed receiver's other operators go through (`sp_user_binop_dispatch`) has
an arm for `!=` now, and in a program where a class has a `!=` of its own a
boxed `!=` asks it first (`sp_poly_ne_own`, emitted for such a program
alone). `!sp_poly_eq` answers as before for every other receiver.

Depends on the pull request "An exception read out of an Array is == to
itself as the rescued value", and narrows what it left as it was: there, a
program in which an exception class has a `!=` of its own kept every answer
it had. Now that holds only where a boxed `!=` cannot ask the class: a
class with ivars, a `!=` whose parameter takes one kind of value, or a `!=`
the program never calls. Elsewhere the two boxes of one exception are equal:

```ruby
class MyErr < StandardError; def !=(o) = true; end
k = MyErr.new("n")
ks = [k, 3]
begin; raise k; rescue => e
  p e != ks[0], e != e, e == ks[0]    # Spinel true false false, CRuby true true true
end
```

Not here, each as it was: an operand the parameter does not take (`xs[0] !=
3` where `!=` reads `o.v` and every call seen passed a Tok); a `!=` that
answers a value other than true or false, read for its truth at a boxed call.

Test: `test/boxed_ne_asks_own_method.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
