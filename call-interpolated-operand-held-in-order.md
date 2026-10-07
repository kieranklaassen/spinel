<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
x = 1
l = ->(v) { x = 5; "a" }
p "#{x}-" + [1].map(&l).join   # "1-a" in CRuby; "5-a" here
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"1-a"
+"5-a"
```

`emit_operands_in_order` binds each operand that runs code to a rooted temp, in the order written, but only a call form; at an interpolated String it gave up and left the operands as arguments of one C call. Here the map's statements are hoisted ahead of that call, so the lambda ran before `"#{x}-"` was made. With a call on each side, C picks the order:

```ruby
$log = []
def a(n) = ($log << "a#{n}"; "s#{n}t")
def b(n) = ($log << "b#{n}"; n)
a(1).include?("s#{b(2)}")
puts $log.join(" ")   # a1 b2 in CRuby; b2 a1 here, built with gcc
```

And whichever of the two is made first is held by nothing while the other runs: `label(n).include?("s#{k(n)}")` lost its String to `label`'s allocations (wrong 20 times of 20, gcc), and `"#{dir}/a".start_with?(root(1))` answers false under `SPINEL_GC_STRESS=2` with either compiler.

An interpolated String is now bound as a call is, to its own rooted temp where it is written, when the receiver is of a kind whose methods run no code of the program's (`ty_runs_no_code`) and either two operands run code or the String is written ahead of the one call and reads what that call can move or change.

Everything else is master's C, through `emit_operands_before_unbound` as before: an interpolated String beside readers and locals only (it is the one operand that runs), a bare reader of self beside it, and an arm that already holds its operands itself, one after the other (`String#+`, a typed `unshift`, `join`) unless a later operand hoists statements ahead of the call, as the `map` above does.

Not in this change, each as on master: a call with no receiver (`Integer("1#{f(1)}", f(10))` runs `f(10)` first, built with gcc), a receiver that is a Hash or an object (`mh["k#{f(1)}"]`), an interpolated Regexp or Symbol, and two operands made in place (`ms(1).sub("s#{n}", "q#{n}")`: the second can free the first, under stress only).

Measured, with the change this stands on, on 887 programs, gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`. Of 94 written against this change, gcc's plain run has 69 right on master and 90 here; under stress 2, 54 and 85 with gcc, 56 and 85 with clang. Of the 92 written against the operand ahead of a call, gcc has 78 and 85, under stress 2 69 and 82; the 701 of the other change stand as there. No program right on master is wrong here, and none that aborted or raised answers wrong.

Cost: a bound call pays its roots (callgrind, 200,000 turns): `ms(i).include?("s#{one(i)}")` goes from 53,921,637 to 58,321,649 instructions, 22 a call for two roots; `"#{dir}/a".start_with?(ms(i))` from 69,443,113 to 74,256,619, 24 a call. A call this change does not bind keeps master's C.

`make cident REF=upstream/master` on 5390d3002886: `6323 identical, 35 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`: the 30 of the change this stands on, the new test and four programs in test/ (`r.inspect.gsub("_#{Process.pid}", "")` in two and `e.message.gsub` of the same in a third, a call's result beside a String that runs a call; `"#{f.ljust(6)} " + [...].map { }.join("|")` in the fourth); all 35 pass. No program under benchmark/ or packages/ changes and optcarrot's generated C is byte-identical. `test/call_interpolated_operand_held_in_order.rb`, also in the `SPINEL_GC_STRESS=2` list, fails on master in all eight runs (gcc and clang: wrong plain, under stress 1 and under minor+verify, an abort under stress 2) and passes in all eight here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints no Hash, whose inspect changed after 3.3)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # ("A call's result is held while the String or empty Hash beside it is made": this is one commit on top of it)
