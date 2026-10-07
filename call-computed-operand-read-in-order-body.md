<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class T
  def initialize = @i = 0
  def bump = (@i += 1; "a")
  def ms(n) = "s#{n}t"
  def go = ms(1).center(@i + 5, bump)
end
puts T.new.go   # as1ta in CRuby; as1taa here, built with gcc or clang
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-as1ta
+as1taa
```

The width was read after `bump` had added to `@i`. `emit_operands_in_order` binds the operands that run code, `ms(1)` and `bump`, to temps in the order written; what it does not bind stays in the call and is read after all of them. A bare `@i` there is bound too, when another operand can reassign it; `@i + 5` was not. So `nums.insert(@i + 1, ibump)` inserted one place further on, and `tens.fetch(@i + 1, ibump)` looked up the next key.

Arithmetic over numbers, or a conditional of it, written ahead of a bound operand that can change a variable it reads (`read_rebound_by`: an ivar, a class variable or a global the later operand can assign, a local it can rebind) is now bound where it stands: the temp of an Integer, a Float or a boolean, with no root. Only in a call the function binds already, and only for a builtin's arm on a String, a number, a Symbol, a Range, an Array or a Hash, which passes its operands to C as they stand. A method of the program orders its own arguments (`take3(val(1), @i + 5, bump)` is right on master and keeps its C), and a `&.` call is left as it is.

No cost: 200,000 turns of `ms(n).center((@i & 0) + 5, tick)` take 211,092,455 instructions on master and 211,092,441 here (callgrind), and of `nums.fetch((@i & 0) + 9, itick)` 8,166,603 and 8,166,589.

An arm that renders such an operand its own way does not read the temp; the call is then emitted again without it, as on master, and remembered, so an enclosing call that emits it again does not ask twice. A chain and a nest of the call above 30 deep compile in master's time (best of three: the chain 0.046 s on both, the nest 0.010 s and 0.009 s).

Not in this change, each as on master. Wrong built with gcc or clang: the same expression in parentheses (`ms(1).center((@i + 5), bump)`), an interpolated String ahead of two calls (`ms(1).sub("#{@i + 1}", bump)`), a keyword's value (`val(1).step(by: @i + 1, to: ibump + 5)`) and the argument of a `&.` call. Right built with clang and wrong with gcc: a call with one operand that runs code, where nothing is bound and C picks the order (`x[@i + 1] = ibump`, `"q".center(@i + 5, bump)`).

Measured on 150 programs written against it, gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`: gcc's plain run has 58 right on master and 141 here; clang's 62 and 145; under stress 2, 57 and 140 with gcc, 61 and 144 with clang. No program right on master is wrong here, and none that aborted or raised answers wrong.

`make cident REF=upstream/master` on a2bd890054b6: `6375 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`: the new test. optcarrot's generated C is byte-identical. `test/call_computed_operand_read_in_order.rb` prints a wrong answer on master in all eight runs (gcc and clang: plain, under stress 1 and 2, under minor+verify) and passes in all eight here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag, not run under 4.0 here; the test prints no Hash, whose inspect changed after 3.3)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
