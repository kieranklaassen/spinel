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

The call was emitted as `sp_str_include(sp_label(n), <the interpolated String>)`: two arguments of one C call, which C evaluates in either order. gcc made the String first; `label`'s allocations collected, and the String, held by nothing, was freed and its slot given to one of `label`'s own. clang makes the call's result first and can lose that one to the sibling's allocation: `any(1).dup.merge({})` aborts under `SPINEL_GC_STRESS=2` built with either.

`emit_operands_in_order` declined a call with one observable operand: it "has no sibling to be ordered against or collected by". That is not so beside an operand that runs no code but is made where it stands: an interpolated String, an empty Hash or Array, a Hash or an Array in an arm (`o || {}`). Beside one, an observable operand that is not a plain read is now bound to its rooted temp, the function's own path, and the sibling is made last. That is Ruby's order too: `bump.include?("#{@n}")` read `@n` before `bump` ran, built with gcc.

Everything else keeps master's C: a reader or a local beside such an operand, a literal with members (it is built ahead of the statement, rooted), an empty one the arm folds away (`r == []` is a length test, a typed `h.merge({})` a copy), an arm that opens by holding the operand itself (`Hash#fetch`), a receiver an enclosing emitter already holds (a `&.` call's is its guard's rooted temp), and most operands written ahead of the call. Ruby makes those first, so one is made after the call only when it is built of literals and of variables that hold an Integer, a Float, a Symbol, true, false or nil and that the call cannot rebind or reassign. `"#{s}-" + s.concat("x")` reads `s` first, `"#{o}"` runs `o`'s `to_s`, `"#{10 / z}"` can raise, a block can assign a constant: each stays in C's order, as does every interpolation in a program that reopens Integer, Float, Symbol, NilClass, TrueClass or FalseClass.

Not in this change: two operands made in place, beside a call or alone (`ms(1).sub("s#{n}", "q#{n}")`, `"a#{n}b".include?("s#{n}")`: the second can free the first), and a String made ahead of the call from a String or an Array (`dir = "ab1x"; "#{dir}/a".start_with?(root(1))` answers false for true under `SPINEL_GC_STRESS=2`); a receiver that is `(any(1) || {})`, an interpolated Symbol, a Range boxed where it stands, and a merge that converts the bound Hash beside its own `{}` (`mh(n).merge(nil || {})`). Each aborts or answers wrong only in a stress run, as on master; the first is wrong there under `SPINEL_GC_STRESS=1` too, built with gcc, and here under `2` only.

Measured on 793 programs, gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`: 701 with a call beside an operand made in place (27 String, 14 Array and 10 Hash methods and 16 calls taking `{}` or `[]`) and 92 written against the operand ahead of the call. Of the 701, gcc's plain run has 668 right on master and 681 here; under stress 2, 377 and 633 with gcc, 416 and 634 with clang. No program right on master is wrong here, and none that aborted or raised answers wrong.

Cost: the bound call pays the root, eleven instructions (callgrind, 200,000 turns of `hits += 1 if ms(i).include?("#{i % 10}")`: 69,229,253 on master, 71,436,683 here). The same loop over a reader, over a local, and with a literal argument keeps master's C.

`make cident REF=upstream/master` on 5390d3002886: `6327 identical, 30 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`: the new test and 29 programs in test/, each with a call of this shape; all 30 pass. No program under benchmark/ or packages/ changes and optcarrot's generated C is byte-identical. `test/call_result_held_beside_made_operand.rb`, also in the `SPINEL_GC_STRESS=2` list, prints 20 for 0 on master built with gcc and aborts there under stress 2 with either compiler; it passes with gcc and clang, plain, under `SPINEL_GC_STRESS=1` and `2`, and under `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints no Hash, whose inspect changed after 3.3)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
