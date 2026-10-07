<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A store in the value of another store got no write barrier, so a minor collection freed what it had just stored. In a plain run, with no setting, 5,814 of 1,000,000 such stores read back wrong.

```ruby
class Box
  attr_accessor :w
  def initialize(n) = @w = n
end
class Acc
  def initialize = @x = nil
  def set(h, a, b) = (@x = h.w = a + b)
  def x = @x
end
holds = Array.new(64) { Box.new(nil) }
acc = Acc.new
bad = 0
i = 0
while i < 1000000
  acc.set(holds[i % 64], "a#{i}", "b")
  j = i - 63
  bad += 1 if j >= 0 && holds[j % 64].w != "a#{j}b"
  i += 1
end
p bad
```

Master (9274c732e) prints `5814`, built with gcc and with clang. CRuby prints `0`.

The barrier pass rewrites an instance variable store that stands at statement position and went on from the end of the statement, so a store inside the value was never looked at. Besides the chained assignment (`@x = h.w = a + b` above, `k.w = @last.w = [a, b]`) that is a store under a ternary, `||` or `||=`, a whole block (`@seen = @items.each { |it| it.w = v }`), and the stores of a method that yields or of an `initialize` that takes a block. The pass for captured locals had the same hole (`x = y = v` in a lambda). Both scans now go on into the value; a string in there is stepped over, as it was when the statement was skipped whole.

Not in this change: a store that is the value of a statement expression takes the wrapper `SP_WBO(o)->iv_w = v`, whose barrier runs before the value, here as on master. Where that value allocates (`@x = HOLD.w = a + b`), the program aborts under `SPINEL_GC_STRESS=2` on master and can still abort there, and the program above, built with clang, still counts 31,211 under `SPINEL_GC_STRESS=1` (798,034 on master; 0 with gcc).

`make cident` against master: 6415 identical; besides the new test, four programs change their C, each by the barrier of such a store: `test/bundle_class_21.rb` (2), `test/issue236_chain_empty_literal.rb` (4), `test/set_from_required_file.rb` (1) and optcarrot (2: `@apu = @cpu.apu = APU.new(..)` and `@ppu = @cpu.ppu = PPU.new(..)`, once each at start). optcarrot under callgrind: 2,376,496,269 instructions before, 2,376,422,450 after, checksum 59662.

Test: `test/gc_minor_nested_store.rb`, in `GC_MINOR_TESTS`, 17 lines; master is wrong in 15 in a plain run.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
