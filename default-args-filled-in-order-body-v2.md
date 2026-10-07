<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Two defaults a call fills can run out of order: a String default runs ahead of an Integer default written before it, compiled with gcc or with clang.

```ruby
$n = 0
def m(x = ($n += 1), y = "s#{$n += 1}") = [x, y]
p m
```

```
spinel diff: output-diff
  program: defaults.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[1, "s2"]
+[2, "s1"]
```

With this commit `spinel diff` says `same`. The same cause, with gcc only: `def m(x = ($n += 1), y = ($n += 1)) = [x, y]` called `m` prints `[2, 1]` (a clang build `[1, 2]`), and so do two keywords, a default that reads what a later one writes (`x = $n, y = ($n += 1)` prints `[1, 1]`), `K.new` and a class method.

Stated cost: 1 instruction a call where a default that takes a root is among the ones made ahead, also in a program whose defaults cannot tell the order. `def m(x = one, y = label)`, with two methods that write nothing, goes from 82 to 83 compiled with gcc and from 84 to 85 with clang (callgrind): a method call counts as a write, `subtree_has_side_effect` not looking into the method. `new` with two scalar defaults goes from 18 to 19 with gcc. Two scalar defaults of a method cost what they did: 24 to 24 and 27 to 27; three, 33 to 33 and 35 to 35.

Cause: `emit_args_filled_argv` writes a default in its parameter's slot of the call's parentheses, and C runs a call's arguments in any order: gcc runs the last first. A default of a kind that takes a root (a String, an Array, an object) is made in the prelude instead, so it runs ahead of a scalar default written before it, whatever the compiler.

Cure: from the first default that stays in the parentheses while a later one can tell the order (both write, or one writes what the other reads), each default whose order can be told is made ahead of the call, in order, in the call's own expression: `({ sp_int _t1 = <x's default>; _t2 = <y's default>; sp_m(_t1, _t2); })`. A scalar takes a plain temp; a kind that takes a root takes a rooted temp declared in the prelude and assigned there, as `emit_rooted_conversion` holds a converted read. The call's site puts the statements in front of its call, so the change reaches the three sites that now ask for them: a top-level method, a class method or module function called on its constant, and `new`. A call with one default that runs code, with literal defaults, with its arguments given, with a splat or a `**` keeps its C, and so does every other site.

Why the call's own expression and not a prelude temp, as written arguments are sequenced: the prelude runs ahead of the whole statement, so in `"#{bump} #{m}"`, `u, v = bump, m` or `a[bump] = m` the defaults would run before `bump`, and a clang build runs those right today. In the call's own expression they run where the call stands.

No program of the corpus changes but the new test (`tools/cident.sh`: 6419 identical); optcarrot's generated C is byte-identical.

Not here: a site that does not ask (`super()`, a method a subclass overrides called on an instance, a class method called by its sibling) still fills its defaults in C's order; a default the prelude builds (an Array literal) still runs ahead of the defaults before it; and a Range default's own bounds still run in C's order, so `def m(x = ($n += 1), y = (($n += 1)..($n + 3))) = [x, y.to_a]` called `m` goes from `[2, [1, 2, 3]]` to `[1, [2, 3, 4]]` compiled with gcc (CRuby and a clang build: `[1, [2, 3, 4, 5]]`).

Test: `test/default_args_filled_in_order.rb`. On master 25 of its 33 lines differ compiled with gcc, and 7 compiled with clang.

Also run: 65 generated programs (the kinds of the defaults, keywords, `new`, class methods, a block, a rest, each call bare, assigned, in a method, in a block and in a loop) with gcc, with clang and with `--share-strings`, `SPINEL_GC_STRESS` unset, 1 and 2: 13 print CRuby's answer in all nine runs on master and 59 with this commit; none that is right on master is wrong here. The other 6 are the forms of "Not here" and a splat and a `**` call, which keep master's C. And 360 programs that put eight calls in 45 places of an expression (an interpolation, an argument, an Array, a condition, an index), with gcc and clang: none that either compiler runs right on master is wrong here; of the 225 with a call this commit reaches, both compilers print CRuby's answer for 25 on master and 205 here. The 20 left are master's own there: a Range's bounds and an index assignment's operands run in C's order, a receiver is made ahead of what stands before it, and one does not build on either.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
