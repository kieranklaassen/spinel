<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Doc
  def initialize(s) = @s = s
  def shout = @s.concat("!").upcase!
  def s = @s
end
d = Doc.new(+"ok")
r = d.shout
p r, d.s
```

```
spinel diff: output-diff
  program: doc.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-"OK!"
+nil
 "OK!"
```

A regression of pull request 7778 ("A mutator on a self-returning String mutator's result reaches the variable"): before it `d.shout` answered "OK!". Since it, a bang on the result of `concat`, `insert`, `prepend`, `replace` or `<<` writes its result back to the variable the chain starts from, and that write-back was emitted ahead of the "did it change?" comparison. Where the variable holds a shared String the receiver read points into its buffer, so the new text was compared with itself and every bang that changed the String answered nil. `s.concat("x").upcase!.concat("y")` then raises FrozenError on that nil, and with `--share-strings` `h[:k] = s.concat("x").upcase!` is a segfault.

The comparison now runs before the chain's write-back, as the arm above it does for a receiver that is the handle itself. A bang whose receiver is the variable, or with no chain to write back through, is emitted as it was.

Not here, two answers that stay wrong where the nil was hiding an older fault. Both keep a copy where CRuby keeps the variable's String:

- with `--share-strings`, `a << s.concat("x").upcase!; a[0] << "!"` raised NoMethodError (it pushed the nil) and now leaves `s` without the "!". Current master answers the same for the chain written as a sequence, `a << (s.concat("x"); s.upcase!)`, and the tree before pull request 7778 answered it for the chain itself.
- `[1, 2].map { |i| s.concat(i.to_s).upcase!.to_s }` printed `["", ""]` and now prints `["A-B1", ""]`, CRuby `["A-B12", ""]`; before pull request 7778 the first element was "A-B1" too.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
