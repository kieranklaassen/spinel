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
```

A String Range is two Strings by value, and two things lost them.

1. The two ends are sibling arguments of one C call. Nothing holds the end made first while the other is made, and gcc makes the last argument first. When both ends are made on the spot the begin now goes into a rooted temp ahead of the end (one arm of `emit_range_expr`).
2. A local's two ends are rooted and an instance variable's are marked, but a temp's were not: a Range that was a method's value, an argument on its way to a callee, the receiver of `cover?` or one side of `==` lost its ends to the next allocation. The ends of a String Range temp are now rooted where the temp is bound, with `emit_gc_root_tmp_refs` as the poly dispatch does.

A Range whose ends are literals or plain reads, and one with a local as an end that the other end cannot reach, compile to the C they did.

On master dafa0d04, against CRuby 3.3.6, plain and under `SPINEL_GC_STRESS=1` and `2`: of 1,134 generated programs (receivers, arguments, consumers, shared Strings, a frozen or dup'd Range; 1,126 build) those right at all three levels go from 260 to 1,006 with gcc and from 310 to 1,034 with clang. The same three commits replay on master 7fbcf219 with no conflict, and the test passes there with both compilers.

**One stated cost, and it is the cost of making the begin first.** A Range's end does not share its String with the name that changes it, so when the end changes in place the very String the begin returned, `(idn(s)..(s << "x"; "zz".dup))`, the Range shows the old content. gcc hid that by running the end first: 16 such programs print CRuby's line on master with gcc only, are wrong there with clang, and are wrong here with both, byte for byte master's clang line. They stay wrong until a Range's end shares its String. Nothing else right on master is lost.

An abort at level 2 on master is a wrong answer with exit 0 here in 9 programs with gcc and 5 with clang: the bytes are those of master's own plain run, already wrong there (the Range written to a global inside a loop, a Range constant in a module body, or one of the 16).

Cost by callgrind, 200,000 turns: `(i.to_s..(i + 3).to_s).cover?((i + 1).to_s)` 111.86M instructions to 120.25M (+7.5%, and master answers 35 of them wrong); with a local as the begin 80.58M to 86.49M (+7.3%); `==` of two such Ranges 182.78M to 202.09M (+10.6%).

**Not here.** A String Range passed to a Proc, taken apart by a multiple assignment, read by `inspect`, read out of a Struct member or back through an attribute reader, or that is the value of `||`, still loses an end at level 2, as on master. An Integer or Float Range's ends still run in the C compiler's order.

**Test.** `test/string_range_fresh_ends.rb`, also in `GC_STRESS_TESTS`. Fails on master in a plain run with gcc and at level 2 with both compilers.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
