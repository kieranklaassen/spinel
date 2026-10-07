<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A String an object's method answers, stored where its element is then changed in place, is refused at compile time when the method can answer `@s` or its argument: it crashed. The cost: of 2,805 generated programs, 10 that are right on master are refused by this (43 under `--share-strings`); each is refused by master as well once its method is written as the reader it is (`def m = @x`). One of them is shown at the end.

```ruby
class C
  def initialize = (@s = +"a")
  def pick(f) = f ? @s : "n"
  def show = @s
end
c = C.new
a = []
a << c.pick(true)
a[0] << "!"
p a, c.show
```

died with a segmentation fault; CRuby prints `["a!"]` and `"a!"`. The element is `@s` itself, and a String is not shared through such a call yet. With a reader, `def pick = @s`, the same program is refused at compile time (`test/reject/string_array_reader_value.rb`); a method that is more than a reader slipped past, and its `const char *` was boxed as the handle it is not.

A call on an object is now refused at that store, in the two sentences the compiler already has: the reader's when a value of its method is an instance variable's String (`@s`, also as the value of `@s = v` or `@s << x`), and the one for a method returning its parameter (`t = c.id(s)` with `t << "!"`) when a value is a parameter and the argument a variable. A method that may answer nil is left alone, as is every other call. So is a method that ends in `@s` and answers nothing else, whatever its parameters (`def pick(f) = @s`): where the slot holds a handle its call already hands that handle out, and `test/object_method_ivar_tail_shared.rb` keeps that.

Not here: the receiverless `a << id(s)` still stores a copy, so an append through the element does not reach `s`. The same String through a local or a Struct member is a quiet wrong line on master and stays one: with `def pick(f) = f ? @s : "n" + "x"`, `u = c.pick(true); u << "?"; p u, c.show` prints `"a?"` and `"a"` where CRuby prints `"a?"` twice, and `a = St.new(c.pick(true)); a.m << "!"` does the same. And the crash is wider than `@s`: a new String an object's method answers, stored and changed in place (`def pick = "y" + "y"`, `a << c.pick; a[0] << "!"`), still dies with a segmentation fault, since no value of that method is an instance variable or a parameter.

One of the right programs now refused:

```ruby
class H
  def initialize; @x = +"ab"; @k = [@x]; end
  def chg = @k[0] << "?"
  def m(f)
    return "n" unless f
    @x
  end
end
h = H.new
h.chg
q = []
q << h.m(true)
q[0] << "y"
p q
```

It prints `["ab?y"]` on master as in CRuby, and it is right by its argument alone: with `h.m(false)` CRuby raises FrozenError and master prints `["ab?y"]` all the same, since the handle of the closing `@x` is handed out whatever the method returned. Written with the reader, `def m = @x` and `q << h.m`, master refuses it in the sentence this change uses.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
