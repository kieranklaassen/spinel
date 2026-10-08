<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A wrong answer in a plain run.** A String Range that a global holds, read as the receiver of `cover?` or `===` while the argument binds the global to another Range, answers for two freed ends. On master 16bca089, of 1,000 rounds each, 2 are wrong with `cover?` and 3 with `===` in a plain run, with gcc and with clang; about 930 under `SPINEL_GC_STRESS=1` and 985 at level 2. Here none is, at any level.

**Two stated costs**, both set out below. Making the begin first: programs that change in place the very String the begin returned were right on master with gcc only, and are wrong here. And a Range that only a global, a constant or a class variable holds is still marked by nothing, and the receiver kept here changes which read of such a name meets a freed end: one program that is right on master in a plain run prints a wrong line here, and one that aborts on master under `SPINEL_GC_STRESS=2` prints freed bytes there with exit 0.

Four programs, each run on its own (what one leaves in the heap decides what the next one loses):

```ruby
# 1
$g = ("a".."c")
def rebind(i)
  $g = ("x".."z")
  junk = []
  200.times { |k| junk << (i + k).to_s * 3 }
  (i + 1).to_s
end

bad = 0
1000.times do |i|
  x = (i + 1).to_s
  want = i.to_s <= x && x <= (i + 5).to_s
  $g = (i.to_s..(i + 5).to_s)
  bad += 1 if $g.cover?(rebind(i)) != want
end
p bad             # CRuby: 0. Here: 2

# 2
bad = 0
3000000.times { |i| m = (i.to_s..(i + 3).to_s).max; bad += 1 if m != (i + 3).to_s }
p bad             # CRuby: 18 (("7".."10").max is nil). Here: 346 with gcc

# 3
def lo; puts "lo"; "b"; end
def hi; puts "hi"; "d"; end
p (lo..hi).to_a   # CRuby prints lo, hi. Here: hi, lo with gcc

# 4
def made(a, b)
  (a.to_s.."#{b}")
end
ins = 0
120.times { |i| ins += 1 if made(100 + i, 102 + i).cover?((101 + i).to_s) }
p ins             # 120. Here: 0 under SPINEL_GC_STRESS=2
```

A String Range is two Strings by value, and two things lost them.

1. The two ends are sibling arguments of one C call. Nothing holds the end made first while the other is made, and gcc makes the last argument first. When both ends are made on the spot the begin now goes into a rooted temp ahead of the end (one arm of `emit_range_expr`).
2. A local's two ends are rooted and an instance variable's are marked, but a temp's were not: a Range that was a method's value, an argument on its way to a callee, the receiver of `cover?` or one side of `==` lost its ends to the next allocation. A global's Range read as a receiver is such a temp, and the argument that binds the global to another Range let its ends go. The ends of a String Range temp are now rooted where the temp is bound, with `emit_gc_root_tmp_refs` as the poly dispatch does.

A Range whose ends are literals or plain reads, and one with a local as an end that the other end cannot reach, compile to the C they did.

Three commits, each of which builds and passes its test alone: the two ends made in order, the temp's ends rooted (the global's Range is its test line), and the local that takes no slot.

It stands on one other, named under "Depends on". `each`, its kin and `step` with a block answer their receiver from a temp of their own, and that pull request roots it. Without it a walk's answer over two made ends, which aborts at level 2 on master, reaches its read with ends the walk let go: of 1,504 programs that read such an answer, 64 printed a wrong line there (on master 9274c732). With it beneath, all 1,504 are right at all three levels, on master 759d120f.

On master 16bca089 with that one beneath, against CRuby 3.3.6, plain and under `SPINEL_GC_STRESS=1` and `2`, with gcc: of 1,939 programs (a String Range written 38 ways, with made ends, a local, a constant or a global beside a made end, a frozen, dup'd, nested or open end, in 51 uses, and 112 that take the Range from a method, a Proc or a collection or change an end inside the Range; 1,913 build) those right at all three levels go from 855 to 1,712. None that is right at a level is wrong or stops at that level here. Of 600 more (Range.new and the literal, each end made five ways, in eight uses; measured on master 9274c732) all are right in a plain run before and after; at level 2, 175 that stopped are right and 25, a Range made in a `when`, are wrong before and after.

**The first stated cost is the cost of making the begin first.** A Range's end does not share its String with the name that changes it, so when the end changes in place the very String the begin returned, `(idn(s)..(s << "x"; "zz".dup))`, the Range shows the old content. gcc hid that by running the end first: of 11 programs that alias an end this way, 5 print CRuby's line on master with gcc only, are wrong there with clang, and are wrong here with both, byte for byte master's clang line. A second reading wrote 11 more of the kind, 16 in all, and each is the same. They stay wrong until a Range's end shares its String.

**The second stated cost is the Range that only a global, a constant or a class variable holds.** Nothing marks its two ends while only the name holds them (not this change, see "Not here"), so a read of the name after enough allocation meets freed ends, on master and here. Which read meets them depends on what else is alive, and the receiver this change keeps is two more Strings alive:

```ruby
$g = ("a".."c")
def rebind(i)
  $g = ((i + 7).to_s..(i + 9).to_s)
  j = []
  200.times { |k| j << (i + k).to_s * 3 }
  (i + 1).to_s
end
c1 = 0
c2 = 0
c3 = 0
300.times do |i|
  $g = (i.to_s..(i + 5).to_s)
  c1 += 1 if $g.cover?(rebind(i))
  c2 += 1 if $g.cover?((i + 8).to_s)
  c3 += 1 if $g.first == (i + 7).to_s
end
p c1, c2, c3      # CRuby: 290, 296, 300
```

Master prints CRuby's three lines in a plain run, with gcc and with clang; this prints 290, 295, 299 with both. The first count is the receiver this change keeps; the other two read the Range `rebind` bound to the global, which nothing marks. With a local holding the receiver (`r = $g; c1 += 1 if r.cover?(rebind(i))`) master prints the same 290, 295, 299, and with 1,000 rounds the program is wrong on master too. Under `SPINEL_GC_STRESS=1` it is wrong on both, and at level 2 both abort.

And one abort becomes a wrong line. `module M; R2 = ("m" + 1.to_s.."m" + 3.to_s); end`, then 100 Strings made, then `puts M::R2.first, M::R2.last`: right on master and here in a plain run and wrong on both at level 1; at level 2 master aborts and this prints two lines of freed bytes with exit 0, with gcc and with clang.

Beside these two kinds nothing right on master is lost.

An abort at level 2 on master is a wrong answer with exit 0 here in 2 of the 1,939 programs and in one of those 5, with gcc. The 2 are `(x..(x = "q" + i.to_s; b.to_s)).include?(y)` and its `member?`, a begin read from a local that the end binds anew: the line is the one master prints in a plain run and at level 1, already wrong there. With clang master is right there in a plain run and at level 1, and here they are right at all three levels. The constant's Range of the second stated cost is a third, and its line is not one master prints; the Struct member under "Not here" is a fourth.

Cost by callgrind, 200,000 turns, on master 16bca089, with gcc (with clang in brackets): `(i.to_s..(i + 3).to_s).cover?((i + 1).to_s)` 112.45M instructions to 119.46M, +6.2% (120.45M to 128.28M, +6.5%), and master answers 35 of them wrong; with a local as the begin, `(lo..(i + 3).to_s).cover?((i + 1).to_s)`, 81.16M to 85.12M, +4.9% (86.74M to 91.70M, +5.7%); `==` of two such Ranges 182.76M to 201.49M, +10.2% (194.29M to 212.85M, +9.6%), 35 wrong on master. A global as the receiver where nothing binds it anew, `$g.cover?(i.to_s)`, 51.34M to 56.74M, +10.5%, 27 instructions a turn (49.26M to 54.87M, +11.4%, 28 a turn). `(a..z).cover?("m")` with two locals and `("b".."y").cover?("m")` cost what they did, to the instruction.

**Not here.** A String Range passed to a Proc, taken apart by a multiple assignment, read by `inspect` or read out of a Struct member still loses an end at level 2. There master aborts for the Proc, `inspect` and the Struct member and prints a wrong count for the multiple assignment; here the Proc and `inspect` still abort, the multiple assignment still prints a wrong count, and the Struct member's abort is a wrong count with exit 0 (`s = S.new((a.to_s.."#{b}")); s.r.cover?(x)` in 120 turns counts 105). All four are right in a plain run and at level 1, before and after. A String Range in a global, a constant or a class variable is still not marked while nothing reads it, a fix of its own. Until that is in, a program that allocates between the write of `$r` and its read can print a wrong line in a plain run too, on master and here (the program of the second stated cost is one); one that printed a wrong line on master at level 2 aborts there here: the temp is rooted with ends that were already freed. That is wrong to loud. The constant's Range of the second stated cost and the Struct member above go the other way, loud to wrong. An Integer or Float Range's ends still run in the C compiler's order.

**Test.** `test/string_range_fresh_ends.rb`, also in `GC_STRESS_TESTS`. Fails on master in a plain run with gcc, at level 1 with clang (the global's line), and aborts at level 2 with both.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here before that, on these three commits over master `fb0de073421a` with the pull request they depend on beneath them (Linux x86-64, gcc 13.3 and clang 18.1, CRuby 3.3.6): the build from nothing, the test and the walk's test at five collector settings with both compilers, with and without `--share-strings`, `tools/gate.rb check` for each commit, `make share-strings-test` and `make cident` against their parent; and on the same three commits over master `16bca08960d1`, the programs and cost figures this text gives for that master.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: "A String Range answered by its walk keeps its ends across the walk" (the walks answer their receiver from a temp of their own, and without that pull request beneath a walk's answer reaches its read with ends the walk let go)
