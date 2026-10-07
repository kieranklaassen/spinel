# Notes, letter FX: a class's own then and yield_self with no block (v1)

Class: fix. One commit. No refactor commit, no cost piece.

## The commits

- On master 2801817b82e1 (the measured tree): commit e6427daabd569581e2b3651345cf940bbce65545, tree 8462e6adbcde.
- Picked onto master a2bd890054b6 (the tip at 10:38 UTC 10-07; its move from 2801817b touches src/spinel_parse.c, Makefile and docs only): commit f36eff65cd942d9c0eb5cbab72bcf1a88a7dc1e5, tree 66134155b596. Built; the test passes there with gcc and clang at SPINEL_GC_STRESS unset, 1 and 2; `ruby tools/gate.rb check` exits 0.
- Numstat: src/codegen_call_object.c 12 in, 1 out; test/poly_own_then.rb 65 in; test/poly_own_then.rb.expected 32 in.

## What it changes

`emit_call_freeze_dup_arms` (src/codegen_call_object.c), the arm for then and yield_self with no block and no argument: it made `sp_enum_of_one(receiver)` for every receiver. It now stands down when `recv_names_own` (new, static, above the function) says the receiver has the name from the program: a typed object whose class resolves the name (`comp_resolve_member`, a method or a reader, the test the dup and clone arm of the same function makes), or a boxed value in a program where a class defines or reads the name (`user_defines_or_reads`, the dup and clone arm's test again). The call then reaches the object call or the boxed class switch, whose default arm comes back here for the builtin values (`user_defines_or_reads` answers 0 inside a builtin arm) and makes the Enumerator.

No other function is touched. Not touched: emit_poly_call, emit_call_body, infer_call_inner (the three over 1,000 lines), the nil helpers, emit_tap_then_expr (the block form), emit_call_identity_arms.

## Left out of FX, and why

- frozen? (the letter named it). Through a box master never calls a class's own freeze or frozen?; an object whose freeze or frozen? calls `super` is right there by accident, because `super` in a class's own freeze raises NoMethodError on master even on a typed receiver (emit_super has no Object#freeze). Sending the boxed frozen? to the class's method turns lines right on master into that raise, and a class with its own freeze AND frozen? pair breaks the same way while the boxed freeze stays builtin (`row[0].freeze; p row[0].frozen?`). Measured on a 492-program freeze family with the three changes together (tree "fy"): 46 rule (a) lines, every one in the three definers whose freeze calls super. So frozen? and freeze through a box stand on a cure of super first: two letters asked of the coordinator.
- itself. Master's stand-down in the identity arm leaves `itself` out, and it has to: the analysis rewrites calls into `itself` calls as an identity mark (Set#to_set, Encoding.default_internal=, and eleven more sites in analyze.c, analyze_desugar.c and analyze_pass.c), so a stand-down by name would send a rewritten call to a class's own `itself`.

## Measured

Trees: m9 = master 2801817b; ft = the commit. The first family ran on an earlier tree of the same master ("fx": this change plus the frozen? and itself changes since dropped); its rows are carried for the 304 then and yield_self programs because fx and ft emit the same C for every one of them (moved.rb fx ft over the 792: 288 differ, 144 frozen? programs and 144 itself programs, none of then or yield_self), and master and ft emit the same C for the other 488 (moved.rb m9 ft: 248 differ, 204 then, 44 yield_self). The second family ran on ft itself.

Every program prints a value or the class of a raise on each line; CRuby 3.3.6 with --enable-frozen-string-literal is the reference; gcc and clang; SPINEL_GC_STRESS unset, 1, 2. The fix's output is byte for byte the same under both compilers at the three levels for every program it changes (checked file by file), so one row serves.

### Family 1, the value used (gen-fx-then.rb; 304 programs of then and yield_self)

Who defines the name (own def, parent, module, alias, define_method, attr_reader, Struct member, singleton, class method, top level, another class, default argument, private, a subclass) x what it answers (7, :own) x the receiver (typed; in a box: the object, an Integer, a String, nil, a Symbol, a Float, an Array, another class's object, a subclass's object; typed-or-nil; a subclass object behind the parent's type, and in a box) x two programs ("plain": the call's class, the value kept; "extra": safe navigation, a statement, then the block and block-pass forms).

| | right | wrong | no build |
|---|---|---|---|
| master | 14 | 26 | 264 |
| fix | 139 | 149 | 16 |

By program: no build -> right 125; no build -> wrong in one line 123; no build -> no build 16 (same C); right -> right 14 (same C); wrong -> wrong 26 (same C). The fix changes the C of 248, every one a no-build on master. Of their 746 output lines 623 are right and 123 wrong, one in each of the 123 "extra" programs.

- Rule (a): 0 (no program master builds changes its C).
- Rule (b), a loud failure turned silent: 0 counted; 123 lines REACHED, NOT MADE, both halves by script:
  - Half 1 (twin3.rb): the twin is the same program with ONLY the two blockless calls changed (they take `itself` for the name; nothing else moves, so the program's Symbols keep their numbers). Master builds every twin and prints, for each of the 123 lines, byte for byte what the fix prints: 70 block-pass lines (`x.then(&pr)` on a value with no then of its own: NoMethodError where Ruby answers 4), 44 block lines (`x.then { |q| 3 }` on an object with its own then: 3, the block's value, where Ruby calls the method), 9 block lines where the method answers a Symbol (the block's 3 printed as the Symbol of that number).
  - Half 2 (half2.rb): master's C and the fix's C for the same program, temporaries renumbered and the frame's declaration set aside, through diff: in all 123 every line of master's the fix changes holds `sp_enum_of_one(` (246 lines, two blockless calls a program); the block and block-pass lines are master's text on both trees.
- The 16 that stay no build: a then only a subclass defines, called on a parent object (typed or boxed). The 26 wrong on both, same C: a top-level `def then` (private on Object: Ruby raises NoMethodError, both trees answer the Enumerator), and the block-pass line beside a class method or another class's then.

### Family 2, the value dropped (gen-fx-then-effect.rb; 280 programs)

The method counts its calls in an ivar; the count is read back. Definers own, parent, module, alias, define_method, default argument, private, singleton, another class, a subclass, none x the same receivers x four shapes (a statement twice, safe navigation, inside a block over a mixed Array, the last-but-one statement of a method).

| | right | wrong | no build |
|---|---|---|---|
| master | 158 | 78 | 44 |
| fix | 276 | 0 | 4 |

By program: wrong -> right 78 (the SILENT ones: master builds, makes an Enumerator and drops it; the class's method never runs); no build -> right 40; right -> right 158 (76 with changed C); no build -> no build 4 (the subclass case again, same C). Rule (a) 0, rule (b) 0, nothing reached. By line where both build: 581 right on both, 101 wrong on master and right on the fix, 0 others.

### Corpus

6,375 programs (test/, benchmark/, packages/*/test/): the generated C is the same for every one (three differ only by the worktree's path in a string: conditional_require_line, require_expression_lines, source_file_required); none refused on either tree. optcarrot (the packed source of an earlier build): C identical, 12,341 lines. So no test of the tree changes its answer.

### Cost (callgrind, instructions; cost-fx/)

| program | master gcc | fix gcc | master clang | fix clang |
|---|---|---|---|---|
| tst_own: `x.then` dropped, x an Integer in a box, a class with its own then beside it, 300,000 calls | 120,010,039 | 121,822,553 | 120,361,263 | 121,572,824 |
| tst_none: the same with no then of its own (same C) | 122,125,285 | 122,125,285 | 124,874,229 | 124,874,229 |
| then_none: the value kept, no then of its own (same C) | 124,594,828 | 124,593,700 | 124,947,012 | 124,947,012 |
| tst_obj: the class's object in the box (master never calls the method; prints 0 for 300,000) | 119,180,379 | 8,765,976 | 119,230,479 | 8,127,520 |

tst_own: +6.0 instructions a call under gcc, +4.0 under clang, of about 400 a call (the Enumerator is still made): the class switch and one rooted slot for the receiver. then_none's 1,128 under gcc is run-to-run noise on identical C (two runs of the fix gave 124,594,828 and 124,593,700).

### Other checks

- share-strings tests by hand (the Makefile's loop, 83 tests, plain and SPINEL_GC_STRESS=1): 0 failures.
- `ruby tools/gate.rb check`: exit 0 on the commit and on the pick. `make gate` itself not run here.
- test/poly_own_then.rb: 32 lines, .expected from CRuby 3.3.6 with --enable-frozen-string-literal (no Hash inspect, no address, no message in it); the CRuby 4.0 box stays open. It does not build on master (the first value-using line is a C type error); passes on the commit and on the pick, gcc and clang, three stress levels.

## Finds for the miner (master, none built here)

1. `super` in a class's own freeze raises NoMethodError on a typed receiver (the deep-freeze idiom). Letter asked.
2. A class's own freeze and frozen? are not called through a boxed value (silent). Letter asked, stacked on 1.
3. A class's own then or yield_self called WITH a block runs the block (silent wrong value); `def then(&b)` Promise style does not build ("type inference did not converge in 128 rounds"); when the method answers a Symbol the block's Integer prints as a Symbol.
4. `x.then(&pr)` raises NoMethodError for a boxed and for a typed Integer, no class involved.
5. A class's own tap with a block is silently ignored.
6. `def self.frozen? = :cls`: `K.frozen?` answers false.
7. A typed object's frozen? that answers a non-boolean prints true or false.
8. attr_reader :itself or a Struct member itself through a box answers the receiver; a top-level `def then` or `def frozen?` (private on Object) is answered by the builtin where Ruby raises.
9. A then only a subclass defines, called on a parent object: no build.
