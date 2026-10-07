<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

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

The call was emitted as `sp_str_include(sp_label(n), <the interpolated String>)`: two arguments of one C call, which C evaluates in either order. gcc made the String first; `label`'s allocations collected, and the String, held by nothing, was freed and its slot given to one of `label`'s own. clang makes the call's result first and can lose that one to the sibling's allocation: `any(1).dup.merge({})` aborts under `SPINEL_GC_STRESS=2` built with either.

`emit_operands_in_order` declined a call with one observable operand: it "has no sibling to be ordered against or collected by". That is not so beside an operand that runs no code but is made where it stands: an interpolated String, an empty Hash or Array, a Hash or an Array in an arm (`o || {}`). Beside one, an observable operand that is not a plain read is now bound to its rooted temp, the function's own path, and the sibling is made last. That is Ruby's order too: `bump.include?("#{@n}")` read `@n` before `bump` ran, built with gcc.

Everything else keeps master's C: a reader or a local beside such an operand, a literal with members (it is built ahead of the statement, rooted), an empty one the arm folds away (`r == []` is a length test, a typed `h.merge({})` a copy), an arm that opens by holding the operand itself (`Hash#fetch`), and an operand written ahead of the call that reads what the call can move (`"#{@n}" + bump` stays in C's order).

Not in this change: two operands made in place, beside a call or alone (`ms(1).sub("s#{n}", "q#{n}")`, `"a#{n}b".include?("s#{n}")`: the second can free the first); a receiver that is `(any(1) || {})`, an interpolated Symbol and a Range boxed where it stands. Each aborts or answers wrong under `SPINEL_GC_STRESS=2`, as on master.

Measured on 701 programs, gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2` (run on 06064727; their generated C is byte-identical on 2f204adb, on master and here): 179 written by hand and 522 generated (27 String, 14 Array and 10 Hash methods and 16 calls taking `{}` or `[]`; the receiver a method's result, a chain, a reader, a local or an interpolated String). Of the 179, gcc's plain run has 158 right on master and 171 here; under stress 2, 108 and 162 with gcc, 129 and 163 with clang. Of the 522, 510 are right in a plain run on both; under stress 2, 269 and 471 with gcc, 287 and 471 with clang. No program right on master is wrong here, and none that aborted or raised answers wrong.

Cost: the bound call pays the root, eleven instructions (callgrind, 200,000 turns of `hits += 1 if ms(i).include?("#{i % 10}")`: 69,229,232 on master, 71,436,656 here). The same loop over a reader, over a local, and with a literal argument keeps master's C.

`make cident REF=upstream/master` on 2f204adb: `6307 identical, 33 differ, 0 refusal changes`: the new test, 30 programs in test/ and 2 in packages/, each with a call of this shape; all 33 pass. In one, an arm that held the call's result itself (`errors.push("#{msg} bad")`) now reads the bound temp: the root moves, none is added. No program under benchmark/ changes and optcarrot's generated C is byte-identical. `test/call_result_held_beside_made_operand.rb`, also in the `SPINEL_GC_STRESS=2` list, prints 20 for 0 on master built with gcc and aborts there under stress 2 with either compiler; it passes with gcc and clang, plain, under `SPINEL_GC_STRESS=1` and `2`, and under `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints no Hash, whose inspect changed after 3.3)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
