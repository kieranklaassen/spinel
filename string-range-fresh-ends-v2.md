<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
bad = 0
3000000.times { |i| m = (i.to_s..(i + 3).to_s).max; bad += 1 if m != (i + 3).to_s }
p bad             # CRuby: 18 (("7".."10").max is nil). Here: 346

def lo; puts "lo"; "b"; end
def hi; puts "hi"; "d"; end
p (lo..hi).to_a   # CRuby prints lo, hi. Here: hi, lo

def made(a, b)
  (a.to_s.."#{b}")
end
ins = 0
120.times { |i| ins += 1 if made(100 + i, 102 + i).cover?((101 + i).to_s) }
p ins             # 120. Here: 0 under SPINEL_GC_STRESS=2

n = 0
3000000.times { |i| n += 1 if (i.to_s..(i + 3).to_s) == (i.to_s..(i + 3).to_s) }
p n               # CRuby: 3000000. Here: 2999672
```

A String Range is two Strings by value. Two things lost them.

1. The two ends are sibling arguments of one C call. Nothing holds the end made first while the other is made, and gcc makes the last argument first. The begin now goes into a rooted temp ahead of the end, when both ends are made on the spot (one arm of `emit_range_expr` in `src/codegen_expr.c`).
2. A local's two ends are rooted and an instance variable's are marked, but a temp's were not. A Range that was a method's value, an argument on its way to a callee, the receiver of `cover?` or one side of `==` lost its ends to the next allocation. The ends of a String Range temp are now rooted where the temp is bound, with `emit_gc_root_tmp_refs` as the poly dispatch does: the operand temps, an argument's temp, the local of an inlined method, the receiver of `include?`, `member?`, `cover?`, `===` and `eql?` when the argument may allocate, and each side of `==` and `!=` beside a side that may allocate.

Rooting a Range takes it whole. One written with a read beside an end that runs something (`(s..(s = t; j.to_s))`), or with two ends each read from a String that was appended to, could already carry a freed end, so such an end goes into a rooted slot where the C compiler makes it, in the C compiler's order. A local that the other end does not name, and cannot reach through a Proc, still holds its String when the Range is made, so it takes no slot: `r = (lo..(i + 3).to_s)` compiles to the C it did, as does a Range whose ends are literals or plain reads.

**Measured merged with master 9b52e40e, CRuby 3.3.6, gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`.**
- 1,134 programs in seven sets (receivers, arguments, consumers, shared Strings, a frozen or dup'd Range); 1,095 build. Right at all three levels: with gcc 260 on master and 975 here, with clang 310 and 1,003.
- A further 1,827 forms of one matrix (ends by consumers; 1,767 build): right at all three levels with gcc 802 on master and 1,576 here, with clang 789 and 1,576. None lost, and no abort or build failure turned into a wrong answer.
- Nothing right on master is lost, but for one stated cost, and it is the cost of making the begin first. A Range's end does not share its String with the name that changes it, so when the end changes in place the very String the begin returned (`(idn(s)..(s << "x"; "zz".dup))`) the Range shows the old content. On master gcc hid that by running the end first. 16 such programs print CRuby's line on master only when built with gcc, are wrong there with clang, and are wrong here with both, byte for byte master's clang line. They stay wrong until a Range's end shares its String.
- An abort at level 2 on master is a wrong answer with exit 0 here in 9 programs with gcc and 5 with clang. One with gcc is among the 16 above. In the others but one the bytes are those of master's own plain run, already wrong there: the two ends run in the C compiler's order, or the Range is written to a global inside a loop, which master answers wrong. The last is a String Range constant in a module body, whose ends nothing marks: master is wrong there at level 1 already.
- Generated C of 6,047 programs (test, benchmark, packages): 5 change. All 5 pass. 3 abort at level 2 on master and pass here (`cell_value_struct_time_capture`, `kw_splat_struct_data_arg_order`, `poly_dispatch_arg_gc_root`); `str_range_endpoints_root` and `nil_write_boxes_range_time_slot` gain the roots of one argument temp.
- The 83 tests whose C touches a String Range: all pass plain on both; `range_overlap_empty_boxed` fails at level 1 on both; at level 2 master fails 18 and this 15, the 3 gained being the programs above.
- `make gc-stress-test` passes with the new test in its list. `make scale-test` prints the same six ratios as master.
- Cost by callgrind, 200,000 turns: `(i.to_s..(i + 3).to_s).cover?((i + 1).to_s)` 111.86M to 120.25M instructions (+7.5%, and master answers 35 of them wrong); a Range from a method passed to a method 120.08M to 128.44M (+7.0%); one end a local, `(lo..(i + 3).to_s).cover?(...)`, 80.58M to 86.49M (+7.3%); that Range stored in a local and read by `last`, 44.68M on both, the C being master's; `==` of two Ranges of fresh ends 182.78M to 202.08M (+10.6%, master 35 wrong); `("a".."z").cover?(s)` and `r.to_a` on a local 248.92M on both.
- `tools/gate.rb check`: exit 0.

**Not here.** A String Range passed to a Proc, taken apart by a multiple assignment, read by `inspect`, read out of a Struct member, read back through an attribute reader and compared (`o.r == (a.to_s..b.to_s)`), or that is the value of `||` read by `===`, still loses an end at level 2, as on master. An Integer or Float Range's ends still run in the C compiler's order.

**Test.** `test/string_range_fresh_ends.rb`, now also in `GC_STRESS_TESTS`. Fails on master in a plain run with gcc and at level 2 with both compilers; passes here plain and at levels 1 and 2 with both, and the same replayed on master 2bd029b7.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
