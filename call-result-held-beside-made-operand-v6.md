<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def label(n)
  s = ""
  30000.times { |i| s = "q#{i % 1000}" }
  "s#{n % 1000}t"
end

wrong = 0
20.times { |n| wrong += 1 unless label(n).include?("s#{n % 1000}") }
p wrong   # 0 in CRuby; 20 here, built with gcc
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-0
+20
```

Cost: a call this change binds pays one root, eleven instructions a turn (callgrind, 200,000 turns of `hits += 1 if ms(i).include?("#{i % 10}")`: 69,231,735 on master, 71,439,159 here; twelve with `ms` answering `"ms" + n.to_s`, 131,570,038 and 134,004,417). The same loop over a reader, over a local, and with a literal argument keeps master's C.

The call was emitted as `sp_str_include(sp_label(n), <the interpolated String>)`: two arguments of one C call, which C evaluates in either order. gcc made the String first; `label`'s allocations collected, and the String, held by nothing, was freed and its slot given to one of `label`'s own. clang makes the call's result first and can lose that one to the sibling's allocation: `any(1).dup.merge({})` aborts under `SPINEL_GC_STRESS=2` built with either.

`emit_operands_in_order` declined a call with one observable operand: it "has no sibling to be ordered against or collected by". That is not so beside an operand that runs no code but is made where it stands: an interpolated String, an empty Hash or Array, a Hash or an Array in an arm (`o || {}`). Beside one, an observable operand that is not a plain read is now bound to its rooted temp, the function's own path, and the sibling is made last. That is Ruby's order too: `bump.include?("#{@n}")` read `@n` before `bump` ran, built with gcc.

Everything else keeps master's C: a reader or a local beside such an operand (a reader of self written bare too: `label` is one field read), a literal with members (it is built ahead of the statement, rooted), an empty one the arm folds away (`r == []` is a length test, a typed `h.merge({})` a copy), an arm that opens by holding the operand itself (`Hash#fetch`), a receiver an enclosing emitter already holds (a `&.` call's is its guard's rooted temp), and most operands written ahead of the call. Ruby evaluates those first, so one is left until after the call only when it is a bare variable the call cannot rebind or reassign or a constant the program never assigns (the same object either way), or is built of literals and of variables that hold an Integer, a Float, a Symbol, true, false or nil and that the call cannot rebind or reassign. `"#{s}-" + s.concat("x")` reads `s` first, `"q#{n}".center(@i + 5, bump)` adds to `@i` first, `"#{o}"` runs `o`'s `to_s`, `"#{10 / z}"` can raise, a block can assign a constant, and `s.start_with?("z#{n}", l.call)` reads the String its method appended to before `l` assigns `s`: each stays as it was, as does every interpolation in a program that reopens Integer, Float, Symbol, NilClass, TrueClass or FalseClass.

The test's last lines are those calls: four print what they printed on master, and `make infer-test` reads the C of five more (a `&.` receiver, a reader, a reader of self, a folded `[]`, an arm that holds its receiver) for a rooted temp.

Not in this change: two operands made in place, beside a call or alone (`ms(1).sub("s#{n}", "q#{n}")`, `"a#{n}b".include?("s#{n}")`: the second can free the first), and a String made ahead of the call from a String or an Array (`dir = "ab1x"; "#{dir}/a".start_with?(root(1))` answers false for true under `SPINEL_GC_STRESS=2`); a receiver that is `(any(1) || {})`, an interpolated Symbol, a Range boxed where it stands, and a merge that converts the bound Hash beside its own `{}` (`mh(n).merge(nil || {})`). Each aborts or answers wrong only in a stress run, as on master. C's order, as on master, right built with clang and wrong with gcc: `"q#{n}".center(@i + 5, bump)`, and a String parameter its method appended to passed ahead of a call that assigns it (`"abcabc#{n}".tr(s, l.call)`).

Measured on 793 programs, gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`: 701 with a call beside an operand made in place (27 String, 14 Array and 10 Hash methods and 16 calls taking `{}` or `[]`) and 92 written against the operand ahead of the call. Of the 701, gcc's plain run has 668 right on master and 681 here; under stress 2, 377 and 633 with gcc, 416 and 634 with clang. Of the 92, the plain runs are master's (78 right with gcc, 85 with clang); under stress 2, 69 and 73 with gcc, 76 and 78 with clang. No program right on master is wrong here, and none that aborted or raised answers wrong.

`make cident REF=upstream/master` on a2bd890054b6: `6346 identical, 31 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`: the new test, the test of the change this stands on (its C is the same with and without this commit) and 29 programs in test/, each with a call of this shape; all 31 pass. No program under benchmark/ or packages/ changes and optcarrot's generated C is byte-identical. `test/call_result_held_beside_made_operand.rb`, also in the `SPINEL_GC_STRESS=2` list, prints 20 for 0 on master built with gcc and aborts there under stress 2 with either compiler; it passes with gcc and clang, plain, under `SPINEL_GC_STRESS=1` and `2`, and under `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1`.

## `make gate` (on this branch merged with current master)

```
not run here: make gate itself (its Tests:, scale-test and gate: lines come from the run on the branch merged with master)
run here, on a2bd890054b6 with this commit and the one it stands on:
tools/gate.rb check, the commit staged: exit 0
cident: 6346 identical, 31 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against a2bd89005)
infer-test: pass
gc-stress-test: pass
nil-check: 0 programs whose C differs with the flag
reject-test: pass
refusals: pass (534 records)
test/call_result_held_beside_made_operand.rb: 8 of 8 (gcc and clang: plain, SPINEL_GC_STRESS=1, SPINEL_GC_STRESS=2, SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1)
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag, not run under 4.0 here; the only Hash the test prints is an empty one, `{}` before and after the change to Hash#inspect)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # ("A computed operand is read in the order written": this is one commit on top of it)
