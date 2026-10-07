<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Keep
  attr_reader :blk
  def initialize(a, &b)
    @blk = b
    @a = a
  end
end
ks = []
200_000.times { |i| ks << Keep.new(i) { |x| x + i } }
s = 0
ks.each { |k| s += k.blk.call(1) }
p s    # 20000100000 in CRuby; 20000100004 on master
```

`spinel diff` on master: output-diff, `20000100004` for `20000100000`, with gcc and with clang; on this branch: same. That is a plain run. Under `SPINEL_GC_STRESS=2` one `Keep.new(2) { |x| x * 3 }` aborts, and at `SPINEL_GC_STRESS=1` `Agg.new(&make(i)).v` prints `2` for `7` and exits 0.

Cost by callgrind, a million `new`: a block alone (`Agg.new { }`) 491,979,285 to 496,079,166 (4 instructions a `new`); beside a gathered rest 6; beside a call or beside locals 3; a lambda into a yielding initialize 4; `Agg.new(&pr)` with `pr` a local, the same C.

A block handed to `new` is a proc built at the call site, inside the constructor call's parentheses: `sp_Keep_new(lv_i, sp_proc_new_meta(...))`. Nothing roots it there. The constructor allocates the object before initialize stores the block, and that allocation collects the proc; so does an argument built beside it (C leaves the order between the two open). A `&` of a lambda, of `proc { }`, of `method(:m)`, of a Symbol or of a call that answers a proc is fresh the same way, and so is a proc handed to a yielding initialize (`sp_X_new_blk`).

The proc now goes to a rooted temp, as a method call's block does (`emit_ctor_block_held`, which `emit_ctor_block_slot` and `emit_ctor_new_with_proc` call). A literal block or lambda runs none of the program's code, so it is built ahead of the call; any other built value is assigned to its temp where it stands, so nothing runs earlier than it did. A bare name (`&pr`, the temp a dispatch on a Class value hoisted, no block) is written as it was.

`make cident`: 38 corpus tests hand `new` a block and differ. Under `SPINEL_GC_STRESS=2` master aborts on 34 of them; 30 of those are right on this branch, as are the 4 master has right.

Not in this change, each the same abort on master under `SPINEL_GC_STRESS=2`: a rest left empty or filled from a splat beside the block (`Bag.new { }`, `Bag.new(*xs) { }`, `Bag.new(*xs, &pr)` into `initialize(*r, &b)`). There the rest's array is freed while the constructor allocates the object. This pull request holds the block, before the constructor is entered and through it; "A rest array handed to new is held while the object is allocated" holds the rest inside it, and the two compose.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
