<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
lo = "1"
z = ((lo + "0")..(lo + "49999")).each { |s| s + "!" }
puts z.first   # CRuby: 10. Here: 75560!
puts z.last    # CRuby: 149999. Here: 75559!
```

That is a plain run with gcc; with clang the two lines come the other way round. `each`, `each_with_index`, `reverse_each`, `each_entry`, `each_slice`, `each_cons` and `step` with a block answer their receiver, and `emit_iter_value_expr` holds it across the walk in a temporary: the receiver itself for `step`, and for the others the binding `iter_recv_bind_once` makes ahead of the statement when the receiver acts. Both root the temporary where `needs_root` says so. A String Range is held by value and `needs_root` is false for it, so the Strings of a Range with an end made on the spot were held by nothing while the block ran. After a collection the answer's `first` and `last` are freed slots, and the next Strings made take them.

Both temporaries now root the two ends of a String Range, by `emit_gc_root_tmp_refs`, as a local of that kind is rooted. Five lines in `src/codegen_iter.c`.

`step` with a block lost its ends before. The others came to it when "Answer Object's methods on a String or Float Range about the Range itself" made their value the Range, where it had been the member Array: the program above printed 10 and 149999 until then.

**Cost.** Only a walk whose value is read pays, two roots a walk. Instructions a turn by callgrind, a gcc build then a clang build: `z = ((lo + "0")..(lo + "5")).each { |s| s }` +16 (+0.3%), +28 (+0.5%); the same with `step(2)` +19 (+0.3%), +27 (+0.5%); `z = r.step(2) { |s| s }` over a Range a local holds +23 (+0.4%), +27 (+0.5%). The same walks with their value dropped, and `each` over two literal ends with its value read, compile to the C they did. Of the 6,202 programs in `test/`, the generated C of 5 changes, each a `step` with a block whose value is read.

**Measured on master 759d120f against CRuby 3.3.6, with gcc, plain and under `SPINEL_GC_STRESS=1` and `2`.** 1,536 programs: the seven walks and `tap`, over a Range whose ends are made six ways (both by `+`, by interpolation, by `dup`, by a method call; one a literal and the other made, either way round), the answer read eight ways (a local, a method's value, a receiver, an argument, an Array element, `cover?`, in a loop, an instance variable), the block allocating or not, over 6 members and over 10,000. 1,504 build.
- In a plain run 32 are wrong on master, all over 10,000 members, and 30 of them are right here. The 2 left are `each_with_index` over two ends made by a method call: the begin is freed while the end is made (below).
- Right at all three levels: 242 on master, 512 here, which is every program with one end made. None that is right at a level is wrong or stops at that level here, and none that stopped prints a wrong line.
- With both ends made on the spot, 992 still abort at level 2 as on master ("the mark reached a freed slot"): the begin is freed while the end is made, before there is a Range to hold. That is "A String Range made on the spot keeps its ends, made in order, until it is read", a pull request of its own. With both, all 1,504 are right at all three levels. It needs this one beneath it: alone, on master 9274c732, it turned 64 of those aborts into a wrong line at level 2.
- 32 do not build, before and after: `(mk(lo, "0")..mk(lo, "5")).step(2) { }`, the ends from a method call, is a C error.

**Not here.**
- A block that binds the local holding the Range anew: `z = r.each { |s| r = ("x".."y") }` answers the new Range where CRuby answers the one walked, before and after. `each` reads a receiver that does not act a second time for its answer.
- `tap` is in the matrix beside the walks; its C does not change.

**Test.** `test/string_range_walk_answer.rb`, 16 lines, also in `GC_STRESS_TESTS`. Every Range in it has one end made, and most of its blocks collect (`GC.start`) and make Strings. On master a plain run prints "15!" for its second line, with gcc and with clang, and at level 2 it aborts before its first line.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
