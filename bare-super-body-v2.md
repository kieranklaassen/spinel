<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `super` that leaves two defaults to the parent runs them backwards when compiled with gcc. Stated cost of the cure, a root (callgrind, instructions a call, gcc and clang): a String default ahead of one that calls a method (`x = "a" * 2, y = seven`) goes from 420 to 432 and from 419 to 433; two of them (`x = "a" * 2, y = "c" * 2`) from 820 to 832 and 819 to 833, where `super()` costs 836; through `def two(*a) = super` 636 to 643 and 610 to 618 with both arguments given, 1215 to 1220 and 1191 to 1197 with none; two keywords read out of `**o` 4 more with gcc and 6 to 11 with clang, given or not. Programs that master runs right are among them: the first, and the ones with every argument given. Nothing else measured pays: two Integer defaults that write (25 to 24, 27 to 27), `super(a)` with two (30 to 25, 26 to 26), a String default beside an Integer one that writes (within 2), and a bare `super` with one default, with literal defaults, with two defaults that only call a method, or with its positional arguments given.

```ruby
$n = 0
class Base
  def m(x = ($n += 1), y = ($n += 1)) = [x, y]
end
class Kid < Base
  def m = super
end
p Kid.new.m
```

```
spinel diff: output-diff
  program: super.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[1, 2]
+[2, 1]
```

With this pull request `spinel diff` says `same`. A clang build of master prints `[1, 2]`. `super()` into that method prints `[2, 1]` too, and `super(a)` into `def m(a, x = ($n += 1), y = "b#{$n += 1}")` prints `["g", 2, "b1"]` with gcc and with clang (CRuby: `["g", 1, "b2"]`).

`emit_super` wrote the defaults a `super` leaves to the parent side by side in the call's parentheses, and C runs those in any order. A plain call no longer does: where two of the defaults it fills can tell their order (`defaults_order_tells`) it makes them ahead of the call, in order, in the call's own expression (`emit_args_filled_ahead`). The four calls `emit_super` writes now do the same. `super()` and `super(a)` take the call's route as it is. A bare `super` fills the parent's parameters by its own writers (`emit_zsuper_param`), so it asks the same rule over the default each parameter takes and makes the ones the rule names ahead: `({ sp_int _t1 = <x's default>; sp_int _t2 = <y's default>; sp_Base_m(self, _t1, _t2); })`. The first commit splits the rule (`defaults_ahead_of`) and the temp (`emit_value_ahead`) out of the call's route for that; it changes no generated C.

A bare `super` differs from a call in one thing. A call makes a default the collector follows in the prelude, rooted; a bare `super` writes every default in the parentheses. So the rule is asked for those too, and one made ahead takes a rooted temp while anything made after it may allocate: a later default made ahead, a slot left in the parentheses whose value may, the block. The last one made takes a plain temp, as it had no root in the parentheses. A rooted temp is let go when the call has returned, so a default lives no longer than it did: after `x = "a" * 3_000_000` through a bare `super`, `GC.start` frees it as on master. A default that makes a by-value object takes no root.

Side by side, such defaults were also collected one under the other: with `x = "a#{$n += 1}", y = "b#{$n += 1}", z = "c#{$n += 1}"` master stops the mark at a freed heap string at `SPINEL_GC_STRESS=2`, with gcc and with clang. Made ahead, they are held.

No program of the corpus changes but the new test (`tools/cident.sh`: 6471 identical); optcarrot's generated C is byte-identical.

Not here, on master and here alike: two defaults that allocate and neither write nor call (`"a#{v}"`, `"c#{v}"`) still stand side by side, and one is collected under the other (wrong at `SPINEL_GC_STRESS=1`, the mark stops at 2); a Range of Strings made ahead takes a plain temp, and its end is collected the same way; a default whose code is written in the prelude, an Array or Hash literal or `(@v += 1)`, still runs ahead of the defaults before it, and so does such an operand beside the call: `def m = super + [bump]` into `def m(x = bump, y = bump)` prints `["u3", "u2", "u1"]` on master with gcc and `["u2", "u3", "u1"]` with clang, and `["u2", "u3", "u1"]` here with both, where CRuby prints `["u1", "u2", "u3"]`; a default that reads an earlier defaulted parameter does not build through a bare `super`; `def initialize(*a); super; end` reached by `Kid.new` stops the mark at `SPINEL_GC_STRESS=2`.

Test: `test/super_defaults_in_order.rb`, added to `GC_STRESS_TESTS`. On master, compiled with gcc, 14 of its 20 lines differ in a plain run; compiled with clang 1 differs; at `SPINEL_GC_STRESS=2` both stop the mark.

Also run: 192 generated programs (where the `super` stands: a method, a class method, a block, a statement, `initialize`, a grandparent, beside a `yield`; positional, rest and keyword parameters, given or left out; what the defaults make: Integers, literals, interpolations, Arrays, Hashes, objects), with gcc, with clang and with `--share-strings`, `SPINEL_GC_STRESS` unset, 1 and 2. 97 print CRuby's answer in all nine runs on master and 157 with this pull request; no run that is right on master is wrong here. One program with a finalizer stops on master at `SPINEL_GC_STRESS=2` and here prints its two lines with the finalizer's first, as master does at 2 for the same method called without `super`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "The defaults a call fills run in the order of the parameters")
