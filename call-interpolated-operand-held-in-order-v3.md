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

`emit_operands_in_order` binds each operand that runs code to a rooted temp, in the order written, but only a call form; at an interpolated String it gave up and left the operands as arguments of one C call. Here the map's statements are hoisted ahead of that call, so the lambda ran before `"#{x}-"` was made.

Cost, paid only by a call this change binds: one root an operand, eleven instructions (callgrind, 200,000 turns). `"a#{one(i)}b".include?("#{i % 7}")` goes from 52,728,624 to 54,928,643; `ms(i).include?("s#{one(i)}")` from 53,924,108 to 58,324,115 (two roots, 22 a call); `"#{dir}/a".start_with?(ms(i))` from 69,445,589 to 74,259,095 (two, 24). A call it does not bind keeps master's C.

With a call on each side, C picks the order:

```ruby
$log = []
def a(n) = ($log << "a#{n}"; "s#{n}t")
def b(n) = ($log << "b#{n}"; n)
a(1).include?("s#{b(2)}")
puts $log.join(" ")   # a1 b2 in CRuby; b2 a1 here, built with gcc
```

And whichever of the two is made first is held by nothing while the other runs: `label(n).include?("s#{k(n)}")` lost its String to `label`'s allocations (wrong 20 times of 20, gcc). The other operand need not be a call. Beside a String made in place:

```ruby
def k(n)
  s = ""
  30000.times { |i| s = "q#{i % 1000}" }
  n % 10
end
wrong = 0
20.times { |n| wrong += 1 unless "a#{k(n)}b".include?("#{n % 10}") }
p wrong   # 0 in CRuby; 20 here, built with gcc
```

The argument was made first and `k`'s allocations freed it. `"a#{n % 10}".center(9, "*#{k(n)}")` loses its receiver the same way built with clang.

An interpolated String is now bound as a call is, to its own rooted temp where it is written, when the receiver is of a kind whose methods run no code of the program's (`ty_runs_no_code`) and either two operands run code, or it runs code beside an operand made in place, or it is written ahead of an operand that runs code and reads what that one can move or change (`@s.sub("x#{@n}", "y#{bump}")` reads `@n` first).

Everything else is master's C, through `emit_operands_before_unbound` as before: an interpolated String beside readers and locals only (it is the one operand that runs), a bare reader of self beside it, an arm that already holds its operands itself, one after the other (`String#+`, a typed `unshift`, `join`) unless a later operand hoists statements ahead of the call, as the `map` above does, and a call with anything else ahead of a bound operand that can change what it reads: arithmetic (`ms(1).center(@i + 5, "#{bump}")`: left in the call, it would be read after `bump`), or a bare variable that operand assigns (`s.start_with?("z#{val(n)}", l.call)` with `l` assigning `s`: the arm reads the String its method appended to in its own order). The test's last lines are two such calls: they print what they printed on master.

Compile time: whether an arm holds its operands itself is known only once they are rendered, and a call declined for that is emitted again by master's path. Such a call is remembered and not asked twice, so a chain does not render its receiver twice a level. Seven shapes at depth 18 and 30 (chains of a typed `unshift`, of `sub`, of `include?`, of `String#+`; nests of `join`, of `between?` and of a bare reader) compile in master's time: the slowest, a 30-long `String#+` chain, 0.12 s on master and 0.14 s here.

Not in this change, each as on master: a call with no receiver (`Integer("1#{f(1)}", f(10))` runs `f(10)` first, built with gcc), a receiver that is a Hash or an object (`mh["k#{f(1)}"]`), an interpolated Regexp or Symbol, and two operands made in place (`ms(1).sub("s#{n}", "q#{n}")`: the second can free the first, under stress only).

Measured, with the changes this stands on, on 988 programs, gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`. Of 101 written against a String that runs a call beside one made in place (59 calls, most of them a String method with the pair in either order; 36 for the order of what each reads; 6 beside a bare reader), gcc's plain run has 52 right on master and 98 here; under stress 2, 41 and 95 with gcc, 44 and 97 with clang. Of 94 written against two operands that run code and a String ahead of the call, gcc's plain run has 69 right on master and 90 here; under stress 2, 54 and 85 with gcc, 56 and 85 with clang. Of the 92 written against the operand ahead of a call, gcc has 78 and 85, under stress 2 69 and 82; the 701 of the change below stand as there. No program right on master is wrong here, and none that aborted or raised answers wrong.

`make cident REF=upstream/master` on a2bd890054b6: `6342 identical, 36 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`: the 31 of the changes this stands on, the new test and four programs in test/. Three are a call's result beside a String that runs a call: `r.inspect.gsub("_#{Process.pid}", "")` in test/io_closed_stream.rb and test/syscall_errno.rb and `e.message.gsub` of the same in test/dir_entries_children.rb (`r.to_s.gsub("x#{ARGV.length}", "")` is that shape too; the line is in the test). The fourth is `"#{f.ljust(6)} " + [...].map { }.join("|")` in test/time_year_format.rb. All 36 pass. No program under benchmark/ or packages/ changes and optcarrot's generated C is byte-identical. `test/call_interpolated_operand_held_in_order.rb`, also in the `SPINEL_GC_STRESS=2` list, fails on master in all eight runs (gcc and clang: wrong plain, under stress 1 and under minor+verify, an abort under stress 2) and passes in all eight here.

## `make gate` (on this branch merged with current master)

```
not run here: make gate itself (its Tests:, scale-test and gate: lines come from the run on the branch merged with master)
run here, on a2bd890054b6 with this commit and the two it stands on:
tools/gate.rb check, the commit staged: exit 0
cident: 6342 identical, 36 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against a2bd89005)
infer-test: pass
gc-stress-test: pass
nil-check: 0 programs whose C differs with the flag
reject-test: pass
refusals: pass (534 records)
test/call_interpolated_operand_held_in_order.rb: 8 of 8 (gcc and clang: plain, SPINEL_GC_STRESS=1, SPINEL_GC_STRESS=2, SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1)
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag, not run under 4.0 here; the test prints no Hash, whose inspect changed after 3.3)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # ("A call's result is held while the String or empty Hash beside it is made": this is one commit on top of it)
