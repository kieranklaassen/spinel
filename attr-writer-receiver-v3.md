<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`recv.v = value` on a receiver that nothing keeps while the value is built stored the value into another object:

```ruby
class K
  attr_accessor :v
  def initialize(v) = @v = v
end
bad = 0
20_000.times do |r|
  K.new("v").v = (made = Array.new(8) { |i| K.new("k#{i}") }; r)
  bad += 1 unless made.all? { |k| k.v.is_a?(String) }
end
p bad    # 0 in Ruby; 1 on master, 5467 with SPINEL_GC_STRESS=1
```

The writer takes its receiver into a C temp and builds the value after it:

```c
{ __typeof__((sp_K_new(...))) _wb1 = (sp_K_new(...)); _wb1->iv_v = VALUE; sp_gc_wb((void *)_wb1); }
```

Nothing holds `_wb1` while `VALUE` allocates. The receiver is collected, one of the objects the value makes takes its slot, and the store lands in that object. `SPINEL_GC_STRESS=2` does not show it: a freed slot is not handed out again there.

The temp is now rooted (`writer_recv_wants_root`, `src/codegen_stmt.c`) where the value can allocate and the receiver may be left held by nothing:

- a receiver nothing keeps: an object made in place, a call's result (`pool.pop.v = ...`);
- a local or an instance variable the value itself rebinds (`o.v = (o = nil; ...)`);
- a receiver something else keeps (a global, an Array's element, a field) when the value can take it out of its holder (`a[0].v = (a.clear; ...)`).

`self`, a constant, and a held receiver whose value runs nothing (`$g.v = [i]`) compile to master's C. On dafa0d047 the generated C of 7 of the 6,056 programs in `test/*.rb` changes, each by such a root.

`test/attr_writer_receiver_held.rb` and `test/attr_writer_holder_emptied.rb` count the stray stores through thirteen forms of receiver. On master (dafa0d047, gcc and clang) both are wrong in a plain run and at level 1, so they are ordinary tests and not in `GC_STRESS_TESTS`.

Not in this change, each the same before and after:

- A value that runs the program's code with no call written is not counted as able to empty the holder: an interpolation that calls the program's `to_s`, `case x when e`, `1 == e`. `$g.v = "x#{e}"`, where `E#to_s` sets `$g = nil` and makes eight objects, still stores into another object in a plain run.
- A setter with a rest (`def v=(*xs)`) reached through a boxed receiver still aborts at `SPINEL_GC_STRESS=2`: `o.v = "s#{i}"`, where `o` is one of two classes. The arm #7536 added builds the rest Array with the value held by nothing.
- `hd.o.o.v = (hd.o = H.new(nil); ...)` still aborts at level 2. The receiver is held now; the store `hd.o = ...` inside the value gets no write barrier, which is another cause.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (`attr_writer_receiver_held` compared equal under 4.0.7; `attr_writer_holder_emptied` was written from ruby 3.3.6 with that flag and is one line, an Array of four zeros)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on dafa0d047)
- [ ] Depends on: # (nothing)
