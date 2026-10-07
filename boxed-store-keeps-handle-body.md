<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

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

`emit_boxed` now hands such a node to `sp_poly_strbuf_lift`, which a boxed argument already goes through for a parameter its callee appends to: a String becomes the handle the mark asked for, any other value (an Integer, nil) passes as it is. No mark is added and no rule about what is shared changes.

The program printed `["bb"]` until pull request 7452 ("An append through a method's element reaches the Array it holds"), did not build after it, and has printed `["ba"]` since pull request 7462 ("A String handle demanded of a value that later widens is no handle").

Cost, by callgrind on a loop of `c.head.succ!`: 906 instructions a turn where the wrong one took 585; master's own store of a String handle, `c.put(+"ay").succ!`, takes 1,018. Eleven corpus tests gain the call where a marked value is read out of a container or a boxed local; `sp_poly_strbuf_lift` is inline, and on a value that is already a handle, or no String, it is one tag test. Their answers are unchanged.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
