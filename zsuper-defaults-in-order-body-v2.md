<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A bare `super` that leaves two defaults to the parent runs them backwards when compiled with gcc, and can lose the first. The cure costs such a call 18 instructions (820 to 838 with two String defaults; callgrind, gcc; 17 with clang), which is what `super()` costs there (836), and 30 where the `super` stands in a loop. Two right programs pay: a default that calls a method which allocates nothing, beside a fresh one (`x = seven, y = "c" * 2`), 12 of 420; and keywords read out of `**o` that every caller gives, where the parent has such a default, 2 of 3,645. `super()`, a plain call, and a bare `super` with one positional default that runs code, with literal defaults or with its positional arguments given emit the C they did.

```ruby
$n = 0
class Base
  def m(x = "a#{$n += 1}", y = "b#{$n += 1}") = [x, y]
end
class Kid < Base
  def m = super
end
p Kid.new.m
```

```
spinel diff: output-diff
  program: order.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-["a1", "b2"]
+["a2", "b1"]
```

With this commit `spinel diff` says `same`. The lost default, with gcc and with clang:

```ruby
class Base
  def two(x = "a" * 2, y = "c" * 2) = [x, y]
end
class Kid < Base
  def two = super
end
k = Kid.new
keep = []
300000.times { keep << k.two }
p keep.count { |x, y| x != "aa" || y != "cc" }
```

master prints `2` in a plain run and CRuby `0`; at `SPINEL_GC_STRESS=2` the mark stops at a freed heap string.

One cause. `emit_zsuper_args` writes the parent's parameters side by side in the call's parentheses, and its three writers of an omitted one (`emit_zsuper_param_fill`, `emit_gathered_param`, `emit_ds_param_extract`) write the default's code there. C runs a call's arguments in any order, and gcc runs the last first. And a method roots its parameters before it allocates, so a call may hand it one fresh value: these writers put two fresh values side by side in the call's parentheses, and the second one's allocation collects the first before the callee is entered.

Where a default writes or may allocate and another parameter runs code too, each such default is now made ahead of the call, in order, in the call's own expression: `({ (_t1 = <x's default>); (_t2 = <y's default>); sp_Base_m(self, _t1, _t2); })`. `_t1` and `_t2` are rooted temps declared in the prelude, as `emit_rooted_conversion` holds a converted read; a scalar default takes a plain temp. The statements stay in front of the call and out of the prelude, so `"#{bump} #{super}"` still runs `bump` first.

Cost of the other forms (gcc, clang): through `def two(*a) = super` 11 and 15; two keywords read out of `**o` 8 and 10, one 4 and 5; two Integer defaults that write, 0. master is wrong in each: in a loop, through `*a` and with two keywords it loses a default in a plain run as above (3, 2 and 2 of 300,000), and with `x: "a" * 2` beside `y: 7` a clang build stops the mark at `SPINEL_GC_STRESS=2` on the first call, because the read of a keyword interns its key. No program of the corpus changes but the new test (`tools/cident.sh`: 6406 identical); optcarrot's generated C is byte-identical.

Not here: a program that defines a finalizer keeps the call as it was, since a rooted temp holds its value past the call and such a program can tell; `def initialize(*a); super; end` reached by `Kid.new` still stops the mark at `SPINEL_GC_STRESS=2`, with literal defaults too; an Array or Hash literal default is built in the prelude, ahead of the defaults before it; a default that reads an earlier defaulted parameter does not build through a bare `super`; a plain call still runs scalar defaults that write in C's order.

Test: `test/zsuper_defaults_in_order_and_held.rb`, added to `GC_STRESS_TESTS`. On master, compiled with gcc, 10 of its 17 lines differ in a plain run; compiled with clang it is right there and stops the mark at `SPINEL_GC_STRESS=2`.

Also run: 187 generated programs (which writer, the kinds of the defaults, `initialize` and class methods, a `super` in a block, a loop, a branch or an interpolation) with gcc, with clang and with `--share-strings`, `SPINEL_GC_STRESS` unset, 1 and 2. 97 print CRuby's answer in all nine runs on master and 176 with this commit; none that is right on master is wrong here, and no run that stopped on master answers wrong here. On master 32 are right in a plain run, wrong with exit 0 at 1 and stopped at 2; 30 of those are right in all nine now. The other 11 are the rows of "Not here".

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
