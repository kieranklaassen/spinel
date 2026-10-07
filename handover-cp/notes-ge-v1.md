# Notes, letter GE: `super` in a class's own freeze and frozen? is Object's (v1)

Class: fix. One commit. No refactor commit, no cost piece. A right program that raises (the deep-freeze idiom), or does not build (`def frozen? = super`).

## The commits

- On master 2801817b82e1 (the measured tree): commit ed1d2f45ca40590ee905958153103001cc785c79, tree 1bbedb7e9386.
- Picked onto master a2bd890054b6: commit 7bd79c4e014bbacb5251c000d1f20954ac46cb19, tree 60d634b80def. Built; the test passes with gcc and clang at SPINEL_GC_STRESS unset, 1 and 2; `ruby tools/gate.rb check` (the piece staged) exits 0.
- Picked onto master 5a752fceb48c (the tip at 11:55 and 11:58 UTC 10-07): commit 2b3faad288def2ac85a9776da436aac5d2e68ee7, tree db80523445ac. Built there; the test passes with gcc and clang at SPINEL_GC_STRESS unset, 1 and 2; `ruby tools/gate.rb check` (the piece staged) exits 0. The move from 2801817b to 5a752fce touches none of the functions the piece touches (emit_super, infer_type, an_phase_value_types, and src/compiler.c and src/compiler.h not at all): in the four files it changes desugar_str_range_methods, elem_miss_call, reassert_rbs_param_seeds, an_phase_infer_fixpoint (src/analyze.c), infer_block_iter_call (src/analyze_infer.c), unsettled_container_cls, emit_nilbool_conv_raise_w, emit_int_expr_ex, emit_int_expr_conv (src/codegen.c). The family, the corpus and the cost were measured on 2801817b and are carried.
- Numstat: src/analyze.c 10 in; src/analyze_infer.c 9 in, 2 out; src/codegen.c 18 in; src/compiler.c 23 in; src/compiler.h 1 in; test/super_freeze_builtin.rb 124 in; test/super_freeze_builtin.rb.expected 27 in.

## What it changes

Three sites ask one question, `comp_super_object_freeze` (new, src/compiler.c, beside `comp_super_is_class_new`): is this `super` in an instance method named freeze or frozen? that no ancestor defines (no prepend shadow, no method in the parent chain), handing nothing on (a bare super in a method with no parameters and no block parameter, or `super()`), with no block? It answers 1 for freeze, 2 for frozen?.

- `infer_type`, the SuperNode arm (src/analyze_infer.c), beside the respond_to? and is_a? lines: the super is typed the class's object (freeze) or a bool (frozen?) where self is an object of the class (`infer_builtin_self` answers an object type; a reopened String, Integer, Object, Array keeps unknown).
- `emit_super` (src/codegen.c): ONE block of 18 lines set in just above the final "No superclass method anywhere" raise, below the is_a? arm. It emits `((sp_K *)sp_gc_freeze((void *)self))` or `sp_gc_is_frozen((void *)self)`, the text the builtin call makes for a typed object (emit_object_call), boxed where the slot is. It runs only where the analysis typed the call so and the class is not laid out by value. No other line of emit_super is touched: not the fallbacks above it, not the three `self->msg =` store lines of the exception arm.
- `an_phase_value_types` (src/analyze.c, 224 lines before, 234 after): where such a freeze sits in a method the program can reach (`reachable`), the class is marked `freeze_observed`, as the same loop marks the class of a bare `freeze` in an instance method, so its instance variable stores take the frozen guard. Unlike the bare call it does not take the class out of the by-value layout: a by-value object has no header, and the super there is left to the raise, as on master.

Not touched: emit_poly_call, emit_call_body, infer_call_inner (the three over 1,000 lines), the nil helpers, emit_super_inline, emit_call_freeze_dup_arms, emit_poly_call0_arms.

## Why the mark

Without it the piece would freeze objects whose own class does not check the flag: `alias seal freeze` or `send(:freeze)` reach the override with no call that names freeze, so master's analysis never marks the class, and `v.seal; v.store(3)` would write to a frozen object in silence where master raised NoMethodError at the super. With the mark the class that holds the override guards its stores however the override is reached (test: Vault). The `reachable` condition keeps a program that defines the override and never names it at master's C (probes vd1, vd2: byte for byte).

## Measured

Trees: m9 = master 2801817b; fs2 = the commit. CRuby 3.3.6 with --enable-frozen-string-literal is the answer; gcc and clang; SPINEL_GC_STRESS unset, 1, 2. Every program prints a value or the class of a raise on each line.

### The family (fam5/gen.rb as `gen-ge-super.rb`; 514 programs)

Who holds the override (a plain class; a child of a class with none; parent and child both; the parent only; the parent with the writing method in the child; a child whose parent defines its OWN freeze and frozen?, so super must reach those; an included module; one module in two classes; a prepended module beside the class's own; a Struct; a Data; an exception class; a singleton method; define_method) x which (freeze, frozen?, both) x how the super is written (bare, `super()`, its value kept in a local, followed by self, `super && ...`, `!super`) x how it is reached (by name on a typed local; `send(:freeze)` and `public_send(:frozen?)`; an alias of each override with no call naming freeze; from another method of the class; never; on the object read out of a mixed Array).

| | right | wrong | died on an uncaught raise | no build |
|---|---|---|---|---|
| master | 120 | 254 | 15 | 125 |
| fix | 382 | 127 | 0 | 5 |

By program: no build -> right 85; wrong -> right 165; died -> right 12; right -> right 120 (105 with master's C, 15 where only the body of an override the program never calls changes); wrong -> wrong 89 (6 with master's C); no build -> wrong 35; died -> wrong 3; no build -> no build 5 (a prepended module's `r = super`: 'lv_r' undeclared, on master and here).

- Rule (a): 0. No program right on master is wrong, refused or unbuilt on the fix.
- By line, where both trees built and ran: 1,165 right on both, 732 wrong on master and right on the fix, 95 wrong on both and THE SAME LINE, 0 others.
- Under clang: every row is the gcc row (403 programs with changed C), and all 1,592 output files (stress unset, 1, 2) are byte for byte gcc's. No output differs between stress levels.

### The 133 lines still wrong, and whose they are

Every one is one of two faults master has with no override in the program at all:

A. 78 lines, `k.poke` after the freeze prints :ok where Ruby raises FrozenError. Master guards an instance variable store only in the class it saw the freeze on. Witnesses on master, no override anywhere: `class K < P; end; k = K.new; k.freeze; k.poke` with poke in P (:ok); the same with `def k.hello` making a singleton class (:ok); `def seal = freeze` in P and poke in a subclass (:ok). Kinds: the child, parent-only, chain, poke-in-the-child and singleton classes.

B. 55 lines, through a box master calls the builtin freeze and never the class's own: `x = row[0]; x.freeze` leaves the override's counter at 0 (49 lines), and freezes for real an object whose own freeze does not (6 lines). Letter GF.

Rule (b), a loud failure turned silent: 0 counted. 38 of the 133 lines stand in programs master did not build (35) or that died on the uncaught NoMethodError (3): REACHED, NOT MADE, both halves by script:
- Half 1 (twin5.rb): each program on master in two twins. Twin S changes only the cured expressions (each `super` of a freeze override becomes `self`, of a frozen? override `false`). Twin R renames the overrides' def lines (freeze_twin, frozen_twin?), so the calls reach Object's and the object is frozen for real. Master builds all 76 twins, and for each of the 38 lines BOTH twins print byte for byte the line the fix prints (24 poke lines, 14 counter lines).
- Half 2 (half2e.rb): master's C and the fix's C for the same program, temporaries renumbered and the frame's declaration set aside, through diff: in all 38 every changed line lies inside an override (a function named `_freeze` or `_frozen_p`), is its prototype or a call of it, or is the boxed frozen? call whose answer is now typed a bool (`sp_poly_frozen(x)` wrapped in `sp_box_bool`, 44 lines); 297 lines of master's, 337 of the fix's. No changed line holds poke, the store of @t or `sp_poly_freeze(`: what computes the 38 lines is master's text on both trees.
The other 95 are lines master itself prints for the same program.

### The coordinator's attack set (probes, master / fix)

- A parent class of the program's own that defines freeze, super must reach that: the userparent kind (43 programs, every one master's C: 37 right, 6 wrong through a box on both, fault B) and at6 (a grandparent's): right.
- A module's freeze in the chain (at1): the module's method runs; same C as master.
- `super` with arguments, or with a block (at3, at5, mo5): no build on master and here, the same error (Ruby raises ArgumentError for the arguments).
- freeze's answer used as a value (at4: assigned, in an Array, passed, in a Hash): right; master raised.
- `frozen?` after dup and clone with the override (at2): true, false, true, and the clone's write raises: right; master did not build.
- A Struct (the struct kind), an exception class, a by-value candidate (vt3, vt6, vd1, vd2): right; a dead override on a by-value candidate emits master's C.
- A reopened String, Integer, Hash, Array, Object with the same override (ro1, ro3, ro5, mo4, ro2): master's C, or the same failure to build.

### Corpus

6,375 programs (test/, benchmark/, packages/*/test/): the generated C is the same for 6,372; three differ only by the worktree path in a string (conditional_require_line, require_expression_lines, source_file_required); none refused on either tree. optcarrot (the packed source of an earlier build): C identical, 12,341 lines. So no test of the tree changes its answer.

### Cost (callgrind, instructions; cost-ge/)

No program that runs on master changes its code path: of the family's 120 right programs 105 emit master's C and 15 change only the body of an override they never call.

| program | master gcc | fix gcc | master clang | fix clang |
|---|---|---|---|---|
| dead_store: a store in a class whose override is never named, 3,000,000 times (same C) | 665,309 | 665,279 | 654,742 | 654,755 |
| none_store: the same class with no override (same C) | 665,323 | 665,293 | 654,756 | 654,769 |
| dead_seal: the same class with `def seal = freeze` (master's own mark; same C) | 8,165,314 | 8,165,314 | 14,126,669 | 14,126,670 |
| live_frozen: `def frozen? = super && @n > 0` asked 3,000,000 times | raises | 18,665,264 | raises | 36,626,637 |
| live_builtin: the builtin frozen? asked as often | 18,665,222 | 18,665,223 | 27,626,583 | 27,626,569 |

The differences of a few tens on identical C are run-to-run noise of the process start. A class whose override is called pays what master's own mark costs a class with a bare `freeze` (dead_seal: 2.5 instructions a store under gcc, 4.5 under clang); such a program raised on master. An own frozen? that asks super costs the builtin's under gcc and three instructions more a call under clang (the method call).

### Other checks

- share-strings tests by hand (the Makefile loop, 83 tests): 0 failures.
- `ruby tools/gate.rb check` with the piece staged: exit 0 on the commit and on both picks (it notes that no Ruby 4.0 is here). `make gate` itself not run here.
- test/super_freeze_builtin.rb: 27 lines, .expected from CRuby 3.3.6 with --enable-frozen-string-literal (no Hash inspect, no address, no message in it); the CRuby 4.0 box stays open. It does not build on master (gcc and clang: C type errors where the value of a frozen? that asks super is used); passes on the commit and both picks, gcc and clang, three stress levels.

## Merge checks

With `git merge-tree --write-tree`, the pick 2b3faad288de against:
- the then piece (letter FX), claude/own-then-no-block-on-a2bd8900 f36eff65cd94: clean; no file shared.
- the boxed scrub repair, claude/scrub-block-boxed-receiver-repair-on-cf1821c3 4b47d421c9f1: clean.
- claude/reader-string-freeze-n3bxdb 4d1a8230cb49: one conflict, src/codegen_stmt.c, which that head has with master 5a752fce itself and this piece does not touch; src/analyze.c merges by itself (that head changes mark_reader_identity_operands and an_phase_storage, this piece an_phase_value_types). No function shared.
- Letter GG (a write barrier on the three `self->msg =` stores of emit_super): this piece adds one block of 18 lines directly above the final raise of emit_super, below the is_a? arm, and touches none of those lines.

## Finds for the miner (master, none built here)

1. Fault A above: a frozen object's instance variable write does not raise in a method of another class of its chain than the one the freeze was seen on (three witnesses; silent).
2. Fault B: letter GF, being built above this piece.
3. `r = super` in a prepended module's method beside the class's own: 'lv_r' undeclared, no build (prepend kind, kept form; freeze or any name).
4. `super` with arguments in a freeze override, `def freeze(x = 1) = super(x)`: no build where Ruby raises ArgumentError.
5. `alias seal freeze` of the BUILTIN freeze in a class: `k.seal` raises NoMethodError (al5).
