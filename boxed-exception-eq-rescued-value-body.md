<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Stated cost: 3 instructions on a `==` of two boxed objects of different
classes; nothing on any other comparison (numbers below).

A rescued exception of a class of the program's own was not `==` to itself
once it had been through an Array.

```ruby
class MyErr < StandardError; end
begin
  raise MyErr, "a"
rescue MyErr => e
  p e == [e, 3][0]    # Spinel false, CRuby true
end
```

One exception reaches a comparison boxed two ways: a value typed as the
program's class is boxed with the class's id, and the value a rescue reads
is boxed as an Exception. `sp_poly_eq` answered false as soon as the two ids
differed, so the same object was unequal to itself. `e != xs[0]` was true,
and for `k = MyErr.new("n")` kept in an Array before `raise k`, `include?`,
`index`, `count`, `-`, `|` and a `when` arm all missed the rescued value.

Where the ids differ, one of them is the Exception's and the two pointers
are the same, `sp_poly_eq` now answers true, or what the class's own `==`
answers where it has one.

The rescued value as the receiver (`rescue => e; e == ks[0]`, `equal?`,
`eql?`, `!=`) has an arm of its own, which asked the boxed operand for the
Exception's id before anything else. It takes the same pointer under any id
too, in a program with an exception class of its own that leaves the method
called alone.

Two objects stay unequal either way, as they were.

Cost: 3 instructions more on a `==` of two boxed objects of different
classes, an Array against a Hash among them (callgrind, 200,000
comparisons: 38,768,100 to 39,368,836). Two boxed Integers, two boxed
Strings, an Integer against a String and two objects of one class cost what
they did, to the instruction.

Not here, each as on master:

- a Hash key: `h = { k => 1 }` then `h[e]` for the same exception rescued is
  nil;
- `xs.include?(e)` where the class's own `==` answers false: CRuby's
  `include?` asks identity first and says true.

Test: `test/exception_boxed_two_ways_equal.rb`,
`test/exception_boxed_two_ways_own_eq.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
