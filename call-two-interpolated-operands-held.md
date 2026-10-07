<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
n = 1
p "as#{n}b".include?("s#{n}")   # true in CRuby; false here under SPINEL_GC_STRESS=2
```

Cost first: one rooted temp, eleven instructions a call (callgrind, 200,000 turns of `"a#{i % 10}b".include?("#{i % 7}")`: 52,728,624 on master, 54,928,630 here; of `s.sub("s#{i % 3}", "q#{i % 10}")`: 143,143,553 and 145,975,091, fourteen). It is paid only by a call that has two interpolated Strings among its operands, a receiver of a kind whose methods run no code of the program's (`ty_runs_no_code`), and an arm that takes the Strings as they stand. Every other call is master's C: one interpolated String, any other receiver, an arm that holds each String itself as it makes it (`"a#{n}" + "b#{n}"`, `s.count("a#{n}", "b#{n}")`, a typed `unshift`), and adjacent literals (`("ta" "g").equal?("t" "ag")`), which fold to a static String and make nothing.

The fault shows only in a stress run: built with gcc or clang, the line above prints false under `SPINEL_GC_STRESS=2`, and `s.sub("s#{n}", "q#{n}")` aborts there. The two Strings are made where they stand, arguments of one C call, each held by nothing: making the second can collect the first. Neither runs code, so `emit_operands_in_order` saw nothing to order and declined. Now an interpolated String with another made after it is bound to a rooted temp, in the order written, and the last is still made in the call.

Not in this change, each as on master, under stress only: a reader's value beside the two (`o.name.sub("s#{n}", "q#{n}")`), a String made in a conditional's arm (`s.sub(c ? "s#{n}" : "z", "q#{n}")`), `(+s).concat("s#{n}", "q#{n}")` and a String beside a Symbol made from one (`"q#{n}".to_sym.to_s + "s#{n}"`).

Measured, gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`. Of 154 programs written against it (the pair as receiver and argument or as two arguments of 40 String methods, beside a local, a call's result and a third made String; 34 more on an Array, a Hash, a number, an object and calls with no receiver), 90 are right under stress 2 on master and 149 here with gcc, 92 and 149 with clang; in a plain run all 154 are right here. The 988 programs of the changes this stands on keep their answers or gain: under stress 2 with gcc, 895 of them are right on the change below and 939 here. No program right on master is wrong here, and none that aborted or raised answers wrong.

Chains and nests of such calls 18 and 30 deep compile in master's time (a 30-long chain of `sub`, 0.03 s on both; the slowest, a 30-deep nest of `count`, whose C is master's, 0.07 s on both).

`make cident REF=upstream/master` on a2bd890054b6: `6342 identical, 37 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`: the 36 of the changes this stands on, 35 of them with their C byte for byte and `test/frozen_literal_identity.rb` with one call more bound (`"#{n}".equal?("#{n}")`), and the new test; all 37 pass. optcarrot's generated C is byte-identical. `test/call_two_interpolated_operands_held.rb`, also in the `SPINEL_GC_STRESS=2` list, aborts on master under stress 2 with either compiler and passes there plain, under stress 1 and under minor+verify; it passes in all eight runs here.

## `make gate` (on this branch merged with current master)

```
not run here: make gate itself (its Tests:, scale-test and gate: lines come from the run on the branch merged with master)
run here, on a2bd890054b6 with this commit and the three it stands on:
tools/gate.rb check, the commit staged: exit 0
cident: 6342 identical, 37 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against a2bd89005)
infer-test: pass
gc-stress-test: pass
nil-check: 0 programs whose C differs with the flag
reject-test: pass
refusals: pass (534 records)
test/call_two_interpolated_operands_held.rb: 8 of 8 (gcc and clang: plain, SPINEL_GC_STRESS=1, SPINEL_GC_STRESS=2, SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1)
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag, not run under 4.0 here; the test prints no Hash, whose inspect changed after 3.3)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # ("An interpolated String operand is made in the order written and held": this is one commit on top of it)
