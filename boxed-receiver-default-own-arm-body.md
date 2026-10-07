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

The default read the receiver before the dispatch had bound it: a zero Symbol here, a null object for `k = [@iv]` in a class of the program (a crash). A default that runs something ran for a receiver of any class: with `def note(k = [tick])` in `Tk` and `def note` in `Other`, `[Other.new, Other.new, Tk.new].each { |x| puts x.note }` ran `tick` three times. With `def note(k = first)` in Range the C did not build (`'_t10' undeclared`).

Cost: a call whose default runs something, reached on master only by receivers of that one class, was right there and now pays 22 instructions with gcc and 14 with clang (callgrind, 200,000 calls: 65,645,125 to 70,045,121 and 67,126,369 to 69,925,623); one whose default calls a method that never reads its receiver (`k = [to_s, 1]` against `def to_s = "tk"`), 14 and 11. That is the call of the function `pd_hoist` makes of any dispatch whose text stands alone, which this one now does. No other call's C changes: a default that only builds (`k = [1, 2]`) keeps master's.

`emit_poly_user_arm0` writes the defaults a zero-argument call leaves out with `emit_arg_or_default`, and what a default hoists (an Array literal's construction, a call's temp) went to the statement's prelude: ahead of the statement the dispatch stands in, where the receiver's temp is not assigned yet, or, where the temp is declared inside the dispatch's own expression, not declared; and outside the `switch`.

The arm now collects what its defaults hoist. Where that text names the receiver's temp, or a left-out default has an effect (`subtree_has_side_effect`), it is written inside the arm's `case`, in a block of its own. Anything else stays ahead of the statement, as it was.

Not in this change, each on master and here: a default that reads an earlier parameter does not build through a boxed receiver (`def note(a = [self], b = a.size)`: `'lv_a' undeclared`); a default that reads self on a receiver whose type is known (`[7].each { |x| puts x.note }` against `class Integer; def note(k = self)` prints `n main`) is another site. A call that gives an argument and leaves a later default out (`x.note(1)` against `def note(a, k = [self])`) was right.

`test/boxed_dispatch_default_in_arm.rb` prints 11 lines and joins `GC_STRESS_TESTS`; master's C for it does not build.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
