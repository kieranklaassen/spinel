<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A store in the value of another store got no write barrier, so a minor collection freed what it had just stored.

```ruby
class Slot
  attr_accessor :w
  attr_reader :v
  def initialize(v)
    @v = v
    @w = nil
  end
end

class Owner
  def initialize
    @last = Slot.new("last")
  end

  def put(a, b)
    k = Slot.new("k")
    k.w = @last.w = [Slot.new(a), Slot.new(b)]
    nil
  end

  def first
    @last.w[0].v
  end
end

o = Owner.new
lost = 0
600.times do |i|
  o.put("a#{i}", "b#{i}")
  200.times { |j| [Slot.new("c#{j}"), "d#{j}"] }
  lost += 1 if o.first != "a#{i}"
end
p lost
```

Master (3e2df1d7b) prints `11`. CRuby prints `0`.

The barrier pass rewrites an instance variable store that stands at statement position and went on from the end of the statement, so a store inside the value was never looked at. Besides the chained assignment that is a store under a ternary, `||` or `||=`, a whole block (`@seen = @items.each { |it| it.w = v }`), and the stores of a method that yields or of an `initialize` that takes a block. The pass for captured locals had the same hole (`x = y = v` in a lambda). Both scans now go on into the value; a string in there is stepped over, as it was when the statement was skipped whole.

Not in this change: a store that is the value of a statement expression takes the wrapper `SP_WBO(o)->iv_w = v`, whose barrier runs before the value, here as on master. Where that value allocates (`@x = HOLD.w = a + b`), the program aborts under `SPINEL_GC_STRESS=2` on master and can still abort there.

`make cident` against master: besides the new test, four programs change their C, each by the barrier of such a store: `test/bundle_class_21.rb` (2), `test/issue236_chain_empty_literal.rb` (4), `test/set_from_required_file.rb` (1) and optcarrot (2: `@apu = @cpu.apu = APU.new(..)` and `@ppu = @cpu.ppu = PPU.new(..)`, once each at start). optcarrot under callgrind: 2,375,631,063 instructions before, 2,375,672,004 after (+0.0017%), checksum 59662.

Test: `test/gc_minor_nested_store.rb`, in `GC_MINOR_TESTS`, 17 lines; 15 of them fail on master under `SPINEL_GC_MINOR=1`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
