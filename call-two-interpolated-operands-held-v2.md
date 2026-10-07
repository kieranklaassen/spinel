<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
n = 1
p "as#{n}b".include?("s#{n}")   # true in CRuby; false here under SPINEL_GC_STRESS=2
```

Cost first: one rooted temp, eleven to fourteen instructions a call. callgrind on 759d120fd207, gcc 13.3, 200,000 turns, master against this: `"a#{i % 10}b".include?("#{i % 7}")` 52,729,579 to 54,929,582; `s.sub("s#{i % 3}", "q#{i % 10}")` 143,144,508 to 145,976,043, and the same with a reader's value or an Array element for `s` (143,143,406 to 145,974,941; 148,173,189 to 151,003,530). Where the arm runs another call of its own beside the last String, that one is bound too, a second root: `s.dup.concat("s#{i % 3}", "q#{i % 10}")` 213,110,589 to 219,537,222, thirty-two a call, two of them the second change below's.

It is paid only by a call that has two interpolated Strings among its operands, a receiver of a kind whose methods run no code of the program's (`ty_runs_no_code`), and an arm that keeps the first across the making of the second. Every other call is master's C: one interpolated String; any other receiver; an arm that holds each String itself as it makes it (`"a#{n}" + "b#{n}"`, `s.count("a#{n}", "b#{n}")`, a typed `unshift`); an arm that is done with each String before the next is made (`s.start_with?("q#{n}", "s#{n}")` is `f(s, a) || f(s, b)`: 66,076,371 on both; `between?`; a typed `push` of two); and adjacent literals (`("ta" "g").equal?("t" "ag")`), which fold to a static String and make nothing.

The fault shows only in a stress run: built with gcc or clang, the line above prints false under `SPINEL_GC_STRESS=2`, and `s.sub("s#{n}", "q#{n}")` aborts there. The two Strings are made where they stand, arguments of one C call, each held by nothing: making the second can collect the first. Neither runs code, so `emit_operands_in_order` saw nothing to order and declined. Now an interpolated String with another made after it is bound to a rooted temp, in the order written, and the last is still made in the call. A reader's value or an element read beside the two runs nothing and stays in the call.

How: whether a String needs the root shows only in the arm's C (does the call keep the first while the second is made, does it run another call beside the last), so the call's text is read once it is rendered, by three small text helpers, and a call that reading changes is emitted a second time and remembered; that is most of the 199 lines in `src/codegen_call.c`.

Not in this change, each as on master, under stress only: a String made in a conditional's or `||` arm or in parentheses (`s.sub(c ? "s#{n}" : "z", "q#{n}")`), a `&.` call, a String beside a Symbol made from one (`"q#{n}".to_sym.to_s + "s#{n}"`), and a String written ahead of the one call that runs beside it (`(c ? a : b).sub("s#{n}", f(2))`, built with clang).

Measured on the commit's own base, gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`. Of 154 programs written against it (the pair as receiver and argument or as two arguments of 40 String methods, beside a local, a call's result and a third made String; 34 more on an Array, a Hash, a number, an object and calls with no receiver), 90 are right under stress 2 on master and 152 here with gcc, 92 and 152 with clang; in a plain run all 154 are right here. Of the 1,389 programs of the changes this stands on, 743 are right under stress 2 on master and 1,326 here with gcc (1,220 on the change below), 800 and 1,332 with clang (1,227). No program right on master or on the change below is wrong here, and none that aborted or raised answers wrong. On 759d120fd207, of the 479 programs whose C this change alters, 46 are right under stress 2 on master and 476 here with gcc, 45 and 474 with clang; none is lost.

Chains and nests of such calls 8, 18 and 30 deep compile in the time of the change below (the slowest 0.07 s); on a nest of calls that are given back the compiler runs 0.9% more instructions for the same C.

`make cident REF=upstream/master` on 759d120fd207: `6394 identical, 38 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`: the 37 of the changes this stands on and the new test; all 38 pass. Against the change below, two programs change their C: the new test and `test/frozen_literal_identity.rb`, with one call more bound (`"#{n}".equal?("#{n}")`). optcarrot's generated C is byte-identical. `test/call_two_interpolated_operands_held.rb`, also in the `SPINEL_GC_STRESS=2` list, aborts on master under stress 2 with either compiler and passes there plain, under stress 1 and under minor+verify; it passes in all eight runs here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag, not run under 4.0 here; the test prints no Hash, whose inspect changed after 3.3)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # ("An interpolated String operand is made in the order written and held": this is one commit on top of it)
