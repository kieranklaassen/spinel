<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
bad = 0
3000000.times { |i| m = (i.to_s..(i + 3).to_s).max; bad += 1 if m != (i + 3).to_s }
p bad             # CRuby: 18 (("7".."10").max is nil). Here: 346

def lo; puts "lo"; "b"; end
def hi; puts "hi"; "d"; end
p (lo..hi).to_a   # CRuby prints lo, hi. Here: hi, lo
```

The two ends of a String Range are sibling arguments of one C call. Nothing holds the end made first while the other is made, so a collection in between frees it, and gcc makes the last argument first.

The begin now goes into a rooted temp ahead of the end, when both ends are made on the spot. An end that is a literal or a read of a variable or a constant is left where it stands. One arm of `emit_range_expr` in `src/codegen_expr.c`.

**Measured against master ab9b925a.**
- Generated C of 6,017 programs (test, benchmark, packages): 4 change, all with two interpolated ends. All 4 pass. 3 of them abort under `SPINEL_GC_STRESS=2` on master and pass here (`cell_value_struct_time_capture`, `kw_splat_struct_data_arg_order`, `poly_dispatch_arg_gc_root`).
- The 80 tests whose C touches a String Range pass plain and at level 1 on both. At level 2 master fails 17 and this 14: the 3 gained are the programs above, and the other 14 fail on both alike.

**Not here.** The Range is held while it is made, not while it is read: `("100"..(i + 3).to_s).include?((i + 1).to_s)` can still lose its end at level 2. An Integer or Float Range's ends still run in the C compiler's order.

**Test.** `test/string_range_fresh_ends.rb`. Fails on master in a plain run; passes here plain and under `SPINEL_GC_STRESS=1` and `2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
