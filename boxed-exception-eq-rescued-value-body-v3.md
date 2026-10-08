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
`index`, `count` and a `when` arm all missed the rescued value.

Where the ids differ, one of them is the Exception's and the two pointers
are the same, `sp_poly_eq` now answers true, or what the class's own `==`
answers where it has one.

The rescued value as the receiver (`rescue => e; e == ks[0]`, `equal?`,
`eql?`, `!=`) has an arm of its own, which asked the boxed operand for the
Exception's id before anything else. It takes the same pointer under any id
too, in a program with an exception class of its own that leaves the method
called alone.

A program that defines a `!=` anywhere keeps the answers it had:

```ruby
class Object
  def !=(o) = true
end
class MyErr < StandardError; end
k = MyErr.new("n")
ks = [k, 3]
begin
  raise k
rescue => e
  p e != ks[0]    # true, as CRuby
end
```

A boxed `!=` is `!sp_poly_eq` and asks no method, so the two boxes being
unequal is what lets the line answer true, wherever the method is written:
on the class, on `Object`, `Kernel`, `BasicObject` or `Exception`.
`sp_poly_eq` cannot see which operator asked, and nothing is asked about
where the method lands: in a program with an exception class of its own
where a `def`, a Symbol or a String spells `!=`, or spells `define_method`,
`define_singleton_method` or `alias_method`, or one of those three is
called with a name that is no literal, the generated `main` sets
`sp_ne_defined` and both arms stand aside. Every `==` and `!=` of that
program answers as on master.

Two objects stay unequal either way, as they were.

Cost: 3 instructions more on a `==` of two boxed objects of different
classes, an Array against a Hash among them (callgrind, 200,000
comparisons: 38,771,421 to 39,371,421). Two boxed Integers, two boxed
Strings, an Integer against a String and two objects of one class cost what
they did, to the instruction.

Not here, each as on master:

- `-`, `|`, `&` and `uniq` ask `eql?` of each pair (`sp_poly_eql_strict`)
  and take the two boxes for two values: `(ks - xs).size` is 1;
- a Hash key: `h = { k => 1 }` then `h[e]` for the same exception rescued is
  nil;
- `xs.include?(e)` where the class's own `==` answers false: CRuby's
  `include?` asks identity first and says true.
- the operand not boxed: with `k` a local typed as the class and no Array
  between, `rescue => e; p e == k` is false, and so are `e.equal?(k)`,
  `e.eql?(k)`, `k.equal?(e)`, `e != k` (true), `e == s.v` for a Struct
  member, and `e == x` under `rescue Base => e` where `x` is boxed with a
  subclass's id;
- two exceptions of one class and message raised at one line: CRuby calls
  them `==` (class, message and backtrace are equal); read out of an Array
  they are unequal;
- a class's own `!=` on a boxed operand: `ks[0] != ks[0]` does not ask it,
  with or without a raise.

Test: `test/exception_boxed_two_ways_equal.rb`,
`test/exception_boxed_two_ways_own_eq.rb`. A program that defines a `!=`,
right before and kept so: `test/exception_boxed_two_ways_own_ne.rb` and
`test/exception_boxed_two_ways_ne_on_{object,kernel,basic_object,exception}.rb`,
`test/exception_boxed_two_ways_ne_by_alias_method.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
