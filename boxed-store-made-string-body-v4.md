<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A fix with a stated cost. The store below is given the handle its Array asked for, and that costs: a loop of `c.head.succ!` takes 915 instructions a turn where the wrong one took 590, and a program that stores such a String and changes it no more pays too: with `c.xs[0].succ!` once before the loop, `c.head` takes 762 where it took 536 (callgrind). Only where the program changes an element of that Array in place: any other program has no mark there and keeps its C. It is the handle a store of a typed String into the same Array (`@xs[0] = @n.succ`) already makes.

```ruby
class C
  attr_reader :xs
  def initialize = @xs = [+"az"]
  def head
    @xs[0] = @xs[0].succ
    @xs[0]
  end
end
c = C.new
c.head.succ!
p c.xs
```

```
spinel diff: output-diff
  program: head.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-["bb"]
+["ba"]
```

`@xs` holds its Strings as shared handles, and the value stored back is marked for one. But it comes from a call on a boxed element, so it is boxed itself, and `emit_boxed` wrote the bare box: a plain String in an Array of handles, which no later change reaches. `c.head << "x"` and a store of `@xs[0] + "q"` or `@xs[0].upcase` lose their change the same way.

`emit_boxed` now hands such a node to `sp_poly_strbuf_lift`, which a boxed argument already goes through for a parameter its callee appends to: a String becomes the handle the mark asked for, any other value (an Integer, nil) passes as it is. Only where the store's own right side makes the String, so that the program has no other name for it (`boxed_value_unnamed`): a call of `succ`, `upcase`, `+` or another String method that answers a new String, under a name no class of the program defines. No mark is added and no rule about what is shared changes.

With `--share-strings` the store loses its change the same way and is mended the same way. test/share/share_strings_boxed_store_beside_route.rb has it there beside a route that hands on a handle (`q ||= s.then { |v| v }`), which keeps the arm it had in `emit_boxed`.

Not here: a value the program names too. `x = @xs[0].succ; @xs[0] = x` is stored as it was: lifted, the Array would hold the handle and `x` the String it was made from, two Strings where CRuby has one, and `x.equal?(@xs[0])`, true today, would turn false. `c.head.succ!` after that store still prints `["ba"]`. So does the program above with a conditional value (`@xs[0] = c ? @xs[0].succ : @xs[0].dup`), on a global Array, on a local Array a lambda writes, on a Struct member (`@pt.v = @pt.v.succ`), with `@xs[0] += "q"` or with `@xs << @xs[0].succ`: their C is unchanged.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
