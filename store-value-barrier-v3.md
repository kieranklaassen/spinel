<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A store that is read for its value ran its write barrier before the value was built, so a minor collection freed what it had just stored.

```ruby
class Slot
  attr_accessor :s
  def initialize(s) = @s = s
end

def churn(n)
  x = nil
  n.times { |i| x = [Slot.new("c#{i}"), "d#{i}"] }
  x
end

def mk(i)
  churn(200)                   # enough for a collection to fall inside the value
  "a" + i.to_s
end

def fill(h, i)
  h.s = mk(i)
end

hs = []
400.times { hs << Slot.new("h") }
churn(5000)                    # the holders are old from here on
400.times { |i| fill(hs[i], i) }
churn(5000)
bad = 0
400.times { |i| bad += 1 unless hs[i].s == "a" + i.to_s }
p bad
```

Master (5390d3002) built with gcc prints `76` in a plain run. CRuby prints `0`.

`h.s = mk(i)` is the method's value, so the store is the last statement of a C statement expression. The barrier pass puts the barrier after a store only where the store is a statement of its own; here it wrapped the holder, `SP_WBO(_t)->iv_s = sp_mk(i)`, and the barrier ran first. A collection while the value is built starts the remembered set over, so the old holder's young value is recorded nowhere and the next minor mark frees it in the slot. It is the hazard the comment in `gc_wb_insert_seg` describes for a statement, left open there for "a store inside a larger expression".

That position has room for statements, so the store now keeps its value in a temp, the barrier follows the store, and the temp is the expression's value:

```c
({ T *_t = h; __typeof__(_t) _wb1 = _t;
   __typeof__(_wb1->iv_s) _wv1 = (_wb1->iv_s = sp_mk(i));
   sp_gc_wb((void *)_wb1); _wv1; })
```

A store anywhere else inside a larger expression keeps the wrapper. The pass goes on into the value of the store it rewrote, so a store in there keeps its barrier (`y = (k.s = last.s = mk(i))`).

It costs nothing; such a store comes out a little cheaper. Callgrind, 1,000,000 stores: as a method's value 82,664,565 to 80,664,565 instructions, as a local's value 64,664,530 to 63,664,530.

Besides the tests, 17 programs of the corpus change their C, each by this form in place of the wrapper; all 17 print the same bytes before and after, plain and at `SPINEL_GC_STRESS=1` and `2`, gcc and clang. optcarrot changes in two stores (`@apu = @cpu.apu = APU.new(..)` and `@ppu = @cpu.ppu = PPU.new(..)`, once each at start; the barrier temps after them are renumbered): 2,377,824,614 instructions before, 2,377,790,603 after, checksum 59662.

Not in this change: `(*X) = v` on a reference cell as a statement expression's value (`gc_wb_cells`) has the same wrapper. No program found for it.

Test: `test/gc_minor_store_value.rb`, in `GC_MINOR_TESTS`: the store as a method's value, a local's value, an argument, under `||=`, a Range through `self`, and a store in such a store's value. On master it prints 78, 87, 87, 0, 0, 80 holders lost in a plain run built with gcc; clang is right in a plain run and loses 397 of the 400 Ranges at `SPINEL_GC_STRESS=1`; level 2 aborts with both.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (above)
- [ ] Depends on: # (the pull request "A store in another store's value takes its write barrier": this is one commit above it, and the scan into a store's value is its work)
