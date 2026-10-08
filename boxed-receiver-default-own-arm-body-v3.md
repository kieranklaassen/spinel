<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Symbol
  def note(k = [self]) = "n #{k.inspect}"
end

[:abc].each { |x| puts x.note }
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-n [:abc]
+n [:note]
```

The default read the receiver before the dispatch had bound it: a zero Symbol here, a null object for `k = [@iv]` in a class of the program (a crash). A default that runs something ran for a receiver of any class: with `def note(k = [tick])` in `Tk` and `def note` in `Other`, `[Other.new, Other.new, Tk.new].each { |x| puts x.note }` ran `tick` three times. With `def note(k = first)` in Range the C did not build (the receiver's temp `undeclared`).

Cost: a call master ran right pays at most 3 instructions. Callgrind over 200,000 calls of `x.note` on a boxed receiver that only `Tk` reaches, each right on master, gcc and clang: `def note(k = [tick])` 66,445,354 to 66,645,353 and 67,326,207 to 67,126,212 (+1 and -1 a call); `def note(a = [tick], b = [tock])` +2 and +3; `def note(k = [[tick], "x"])` +2 and +1; `def note(k = [self.class])` 0 and +2; `def note(k = [to_s, 1])` -4 and 0. A default that hoists nothing (`k = tick`) or only builds (`k = [1, 2]`, and `b` in `def note(a = tick, b = [2])`) keeps master's C.

`emit_poly_user_arm0` writes the defaults a zero-argument call leaves out with `emit_arg_or_default`, and what a default hoists (an Array literal's construction, a call's temp) went to the statement's prelude: ahead of the statement the dispatch stands in, where the receiver's temp is not assigned yet, or, where the temp is declared inside the dispatch's own expression, not declared; and outside the `switch`.

The arm now takes what each default hoists by itself. Where that text names the receiver's temp, or the default has an effect (`subtree_has_side_effect`), it is written inside the arm's `case`, in a block, and the default's value is handed to the call through a temp declared ahead of the statement, where the default's own temp was. So the `switch` still names a temp of its function, and `pd_hoist` leaves it inline, as it did.

Not in this change, each on master and here. A method added to Object is the switch's `default` arm, another emitter: `k = [tick]` there runs for a receiver of any class and `k = [self.class]` does not build. A default that reads an earlier parameter does not build through a boxed receiver (`def note(a = [self], b = a.size)`: `'lv_a' undeclared`). Two left-out defaults that both run something keep master's order: `def note(a = tick, b = [tick])` answers `2 [1]`. A default that only builds is read ahead of the receiver expression (`k = [$g]` beside a receiver that writes `$g`). A default that reads self on a receiver whose type is known is another site (`[7].each { |x| puts x.note }` against `class Integer; def note(k = self)` prints `n main`). And one build failure becomes a raise: `class String; def note(k = [self, size])` did not build (`'_t10' undeclared`) and now raises `undefined local variable or method 'size' for main (NameError)`, as the same default does on master when the call gives an argument before it (`def note(a, k = [self, size])`, `x.note(1)`). Another becomes a wrong line: with `class IO; def note(k = [fileno, tick])` and a `tick` that prints, `[$stdout, Other.new, $stderr].each { |x| puts x.note }` did not build, and now writes the second `tick` to standard output where CRuby writes it to standard error, as master does with that default written in the body (`def note(k = nil)`, `k || [fileno, tick]`).

`test/boxed_dispatch_default_in_arm.rb` prints 15 lines and joins `GC_STRESS_TESTS`; master's C for it does not build. No other test's generated C changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
