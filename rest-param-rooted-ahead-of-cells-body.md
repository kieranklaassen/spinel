<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a stated cost.** A method that captures its rest parameter pays one frame slot, 4 instructions a call (0.8% on the loop measured below), also where the call already held the Array. No other method pays: its C is master's, or the root of its rest only moves ahead of a cell.

A lambda that captures its method's rest parameter could come back holding another call's Array. A plain run shows it:

```ruby
class K
  def hold(n, *args, &block) = lambda { args << n }
end
k = K.new
keep = []
i = 0
while i < 1000000
  f = k.hold(i)
  f.call
  keep << f if i % 4 == 0
  i += 1
end
wrong = []
keep.each_with_index do |f, j|
  r = f.call.inspect
  wrong << r if r != "[#{j * 4}, #{j * 4}]"
end
p wrong.size, wrong.first
```

```
spinel diff: output-diff
  program: rest.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-0
-nil
+6
+"[874, 868]"
```

A call roots the rest Array it packs in its own frame, because the callee can allocate before it stores the Array anywhere the collector sees (`emit_rest_pack_kwh`). Two short forms are handed over as the bare call that makes them: an empty rest (`hold(i)`) and a lone splat (`top(i, *ints)`). For those the method is the first to hold the Array, and a method with a captured local allocates before it does: a captured local lives in a cell, and `emit_scope_decls_ends` makes the cells in the order of the locals.

```c
/* def hold(n, *args, &block) = lambda { args << n }, on master */
_gcf.p[0] = SP_GC_ENTRY_PTR(lv_block);
sp_int *_cell_n = (sp_int *)sp_gc_alloc(sizeof(sp_int), NULL, NULL);        /* lv_args is held by nothing */
_gcf.p[1] = SP_GC_ENTRY_PTR(_cell_n);
*_cell_n = lv_n;
sp_PolyArray * *_cell_args = (sp_PolyArray * *)sp_gc_alloc(sizeof(sp_PolyArray *), NULL, sp_cell_scan_ptr);
_gcf.p[2] = SP_GC_ENTRY_PTR(_cell_args);
*_cell_args = lv_args;
```

A collection that falls on either cell frees the rest, and the next Array made takes its place. A captured rest was not rooted at all before it moved into its own cell; an uncaptured one was rooted where its turn came, after the cells of the locals before it. Under `SPINEL_GC_STRESS=2` the mark stops on the freed Array.

The rest is now rooted before the first cell made ahead of it or for it:

```c
_gcf.p[0] = SP_GC_ENTRY_PTR(lv_block);
_gcf.p[1] = SP_GC_ENTRY_PTR(lv_args);
sp_int *_cell_n = (sp_int *)sp_gc_alloc(sizeof(sp_int), NULL, NULL);
```

Only the rest needs it. The call holds every other argument it makes (`emit_arg_rooted`), so a captured parameter that is not the rest keeps its C, and a method with no captured local keeps its C.

This is two commits. The first moves the switch that roots a parameter by the form its type takes out of `emit_scope_decls_ends` into `emit_param_root`, so the walk can call it early; it changes no generated C. The second is the fix.

**Measured against CRuby 3.3.6 on master 9274c732.** 700 generated programs: ten callees (a lambda that reads the rest, returned by an instance method, a top-level method and a class method; an instance method that captures another parameter and returns the rest; four constructors; two methods that capture nothing) by five signatures (`*a`; `*a, k: 3` with and without the keyword given; `*a, &b`; `*a, z`) by seven ways to write the rest (none, a lone splat of an Integer, String, Float, mixed or empty Array, two plain arguments) by two leading values.

| of the 280 that capture outside a constructor | master | this branch |
|---|---|---|
| right in a plain run, under `SPINEL_GC_STRESS=1` and under 2 | 112 | 280 |
| `SPINEL_GC_STRESS=1`: wrong and silent | 48 | 0 |
| `SPINEL_GC_STRESS=2`: the mark stops | 168 | 0 |

The 140 that capture nothing are right on both. Of the 280 constructors, 40 are right on both and 240 stop under `SPINEL_GC_STRESS=2` on both (see below); none of the 700 moves from a stop to a wrong answer. 754 more programs hand a value made in the argument list (a String sum, an interpolation, an Array, a mapped Array, a Hash, an object, a Bignum) to a captured parameter that is not the rest, through eight callees and eight ways to write the call: 753 are right on master and here at every level, and one raises the same TypeError on both.

**Cost.** One frame slot in a method that captures its rest: `def hold(n, *a) = -> { [n, a] }` called 200,000 times with two plain arguments runs 99,211,308 instructions on master and 100,039,447 here (callgrind, gcc), 4 a call in a call that allocates two cells, an Array and a lambda. The allocation that frees the rest is the method's own cell, and the method cannot tell whether its call held the Array; a hold on the calling side would have to be written at every place that makes a bare rest. `def hold(s) = -> { s }` and a method with no captured local are master's C; a rest that only follows a captured parameter has its root moved, not added.

**Not here.** A constructor allocates its object before `initialize` runs, with the rest still held by nothing, so `Keep.new(i)` whose `initialize(n, *args)` keeps the rest stops the same way under `SPINEL_GC_STRESS=2`. That allocation is not in `initialize`.

**Generated C.** `make cident`, the first commit against master 9274c732: `6418 identical, 0 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The second against the first: `6414 identical, 5 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The five are the new test and four tests in the tree whose methods capture a rest or make a cell ahead of it (`byref_gather_lead_block_super`, `splat_map_lambda_into_rest`, `super_in_proc_forwards_block`, `zsuper_in_proc_captures_params`): each gains the root and renumbered frame slots, nothing else. Two of them, `splat_map_lambda_into_rest` and `super_in_proc_forwards_block`, stop under `SPINEL_GC_STRESS=2` on master and pass here. Whether optcarrot's generated C changes is not known: there is no checkout of it where this was written.

**Test.** `test/rest_param_held_across_cells.rb`, also in `GC_STRESS_TESTS`: a captured rest, a rest after a captured parameter, lone splats of Integers, Strings and Floats, a class method, a keyword and a post parameter, a method-level `rescue`, and the same methods reached through `send`, `public_send` and a Method object. On master it stops under `SPINEL_GC_STRESS=2`. Here it prints the same plain, at both stress levels with and without `SPINEL_GC_VERIFY=1`, built with clang, and under `--share-strings`; `make gc-stress-test` passes. The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written. The test prints Integers, Strings, Floats, Symbols and Arrays.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
