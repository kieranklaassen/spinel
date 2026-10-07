# Notes, letter FX: a class's own then and yield_self with no block (v2, after reader 4's NOT READY)

Class: by the ruling on letter GF, a FIX WITH A STATED COST (a right program pays 4 to 6 instructions a call; the body opens with it). One commit. Title unchanged.

## The reading and the repair

Reader 4 (NOT READY on f36eff65cd94): a receiver TYPED as the class and nil at run time ran the class's method with no self. Three programs: the method touches an ivar (right on master, rc 139 on the piece); the method prints (right on master, an extra line on the piece); the value used (no build on master, `Symbol` for `Enumerator` on the piece).

Ruled: the inverted test. The method is called only where the receiver is PROVED never nil; every other receiver keeps master's C byte for byte.

First try, the nil fact alone (`repr_of(c, recv).may_nil`, src/analyze_nil.c): it LEAKED, and is not what the commit does. Its header names three shapes "taken as not nil without proof"; one is a builtin iteration's block parameter, and a hole in a typed Array reaches it:

    a = [W.new]
    a[2] = W.new
    a.map { |b| b.then; 1 }

`b` is typed W, the fact says not nil, and the method ran on the hole. (Most other iteration forms box the parameter; `map` over a local Array did not.)

What the commit does: the proof is what is written at the call. `recv_is_made_object` (static, src/codegen_call_object.c) answers yes for

1. `X.new` (a call named `new` on a constant; the nil fact covers a `new` the program defines);
2. a local of its own scope, no parameter, no block parameter, not captured by an escaping proc (`is_cell`) nor rebound by one (`proc_rebinds`), whose every write is a plain `name = X.new`: the five local-write node kinds are walked (`comp_is_local_write`'s list), and any write that is not that (a target of a multiple assignment, `||=`, `&&=`, an operator write, any other value) answers no;
3. a local read the nil fact marks GUARDED (`if b`, `b && b.then`, `return unless b`, `unless b.nil?`), with the same two capture checks;

and the nil fact is asked first in all three (a read that can run before the write). `recv_names_own` adds

4. the `&.` form: master's own safe-navigation wrapper has tested the receiver before the arm runs.

A boxed receiver is as in v1: the class switch sends nil to the Enumerator by its tag. Not in the list, so master's C: a parameter, an ivar, a method's value, a block parameter, a constant, a global, a class variable, a Struct member, `self` (a nil in a typed slot runs master's user methods with no self, so `self` is not proof), a local copied from another local.

No nil helper is added or touched; no function over 1,000 lines is touched; the arm's condition is the only changed line of `emit_call_freeze_dup_arms`.

## The commits

- On master 2801817b82e1 (measured): 23b7b07c6aa7c4f7feec297f61174e372dbefd7c, tree f6e0e1bad1b4. Numstat: src/codegen_call_object.c 61 in, 1 out; test/poly_own_then.rb 78; .expected 36.
- On master 4f8b737c1402 (the tip at 13:39 and 13:55 UTC 10-07): 1494b2634c6ea7b3963e1565dad92a02349092da, tree e0d9383d0123. BUILT there (upstream changed `emit_call_identity_arms` in the same file since 2801817b; the pick is clean). The test passes with gcc and clang at SPINEL_GC_STRESS unset, 1 and 2, and with `--share-strings`; `ruby tools/gate.rb check` with the piece staged exits 0; the bare tip does not build the test.
- For the reader, who reads on a2bd890054b6: 37be4cd385a9817a0278766692e38622d7fca485, a child of f36eff65cd94 holding the repair alone (src 57 in, 8 out; the test 17 in, 4 out; .expected 4 in). Its tree, 64aefa13c4cf, is the tree of the one commit picked onto a2bd890054b6. Built; the test passes in the six cells; staged gate check exits 0. It is for the reading only.

## The reader's three programs

`attack-fx/reader/r1.rb`, `r2.rb`, `r3.rb` and the same with yield_self: the C of the piece is master's byte for byte on 2801817b and on 4f8b737c (six programs, `cmp` of `-S --no-line-map`); on the delta build r1 and r2 print `done`, r3 does not build, as on master. The test now holds the case: `q = pick(false); q.then` (the first version of the piece dies there, rc 139).

## Measured

Trees: m9 = master 2801817b; ft = the first version (e6427daabd56); fr = this commit. CRuby 3.3.6 with --enable-frozen-string-literal is the answer; gcc and clang; SPINEL_GC_STRESS unset, 1, 2. A program whose C is master's carries master's row. Four families, 1,086 programs.

| family | master right / wrong / no build | this commit right / wrong / no build |
|---|---|---|
| 1, the value used (`gen-fx-then.rb`, 304) | 14 / 26 / 264 | 137 / 147 / 20 |
| 2, the value dropped (`gen-fx-then-effect.rb`, 280) | 158 / 78 / 44 | 260 / 16 / 4 |
| 3, slot kinds (`gen-fx-nil-slots.rb`, 392) | 66 / 98 / 228 | 178 / 54 / 160 |
| 4, guards and `&.` (`gen-fx-guards.rb`, 110) | 53 / 41 / 16 | 84 / 26 / 0 |

Rule (a): 0 in all four (no program right on master is anything else here; by line where both build, no right line of master's changes). Rule (b): 0 made; 121 lines reached, not made, all in family 1 (below). No output differs between stress levels. Under clang every program whose C differs from master's (246, 178, 136, and all 110 of family 4) has gcc's rows, and every output file is byte for byte gcc's.

### Family 1 (304)

no build -> right 123; no build -> wrong in one line 121; no build -> no build 20 (18 with master's C; 2 where only the `&.` line changed and the plain call beside it is on a copied local); right -> right 14 and wrong -> wrong 26, master's C. Against the first version: 4 programs go back to no build (a singleton `then` on `x = k0`, a copied local).

The 121 lines reached, not made, both halves by script on this commit:

- Half 1 (`fx-twin3.rb`, pointed at this commit's outputs): the twin is the program with ONLY the two blockless calls changed (they take `itself` for the name). Master builds every twin and prints, for each of the 121 lines, byte for byte what this commit prints: 70 block-pass lines (`x.then(&pr)` on a value with no then of its own: NoMethodError where Ruby answers 4), 43 block lines (`x.then { |q| 3 }` on an object with its own then: 3, where Ruby calls the method), 8 block lines where the method answers a Symbol (the block's 3 printed as the Symbol of that number). 121 of 121.
- Half 2 (`fx-half2.rb`): master's C and this commit's C for the same program, temporaries renumbered, the frame's declaration set aside: in all 121 every line of master's that changes holds `sp_enum_of_one(` (242 lines); the block and block-pass lines are master's text on both.

The reader's count on his own programs: 38 twin pairs hold with a line wrong against CRuby, of his kinds (i) a block on an object with its own then, (ii) `x.then(&blk)`, (iii) a block where only the child defines then; 11 have no twin because the line builds on neither side. The body names the three kinds in those words and no longer says the 11 build.

### Family 2 (280)

wrong -> right 62 (the SILENT ones: master builds and the method never runs); no build -> right 40; right -> right 158 (76 with changed C); wrong -> wrong 16, master's C (the receiver is a parameter, or a local copied from another: left); no build -> no build 4. By line where both build: 581 right on both, 77 wrong to right, 24 wrong and the same, 0 others. The first version cured the 16.

### Family 3, how a nil reaches the slot (392)

49 slot kinds x nil or an object at run time x then or yield_self x dropped or used. Master, the first version, this commit:

    master right     first version WRONG     this commit right       42   (the first version's rule (a) losses)
    master no build  first version WRONG     this commit no build    70   (its build failures turned silent)
    master no build  first version a raise   this commit no build     6
    master right     right                   right                   24
    master no build  right                   right                   68
    master wrong     right                   right                   44
    master no build  right                   no build                76   (an object at run time in a slot not proved: left)
    master wrong     right                   wrong                   48   (the same, value dropped: left)
    the same C on all three                                          14   (8 no build, 4 master's raise, 2 wrong)

The 112 cured here: `X.new`, the made local, and every boxed kind (an Array's pop, shift, first, find, min_by, sample, delete_at, fetch; a Hash's miss, fetch, delete, dig; a block parameter of each, map, a Hash's each). The 256 with master's C: every kind whose typed slot can hold nil.

### Family 4, guards and `&.` (110)

55 shapes x nil or an object: the guard forms (`if b`, `b &&`, modifier, `return unless`, `unless b.nil?`, a ternary), the same with the local rewritten inside the guard (in a block, a lambda, a proc, a loop, a rescue, an ensure, a multiple assignment, `&&=`), negated guards (`unless b`, `if !b`, `if b.nil?`, the else branch, `b ||`, `until b`), a guard on another local, and `&.` on a local, a call, a chain, an ivar, a parameter, a boxed value, an element. no build -> right 16, wrong -> right 15, right -> right 53, wrong -> wrong 26 with master's line (a guard the fact does not take, or a write in the guarded region: left). By line: 147 right on both, 15 wrong to right, 26 wrong and the same.

### Attack programs (gcc, stress unset; `attack-fx/`, four sets)

118 more, written to break the write walk and the fact, run on master and on this commit: a typed Array's hole bound by map, each, select, inject, sort_by, flat_map, each_with_object, a for loop; the made local rewritten from such a parameter inside a block, a lambda, a proc, a nested block, `define_method`, a method, a loop; a local shadowed by a block parameter; a `new` the class defines to answer nil. Right on master and not here: 0. Every write from inside a block, a lambda, a proc or a loop is seen by the walk (set 4: 20 programs keep master's C; the 21st, whose block writes `X.new`, is cured).

### Corpus

6,375 programs (test/, benchmark/, packages/*/test/): the generated C is the same for 6,368; 3 differ by the worktree's path in a string; 4 by the compiler's own revision in RUBY_DESCRIPTION. None refused on either tree. optcarrot (one packed source file): C identical, 12,341 lines, emitted by both trees with one command.

### On the tip

`bridge2.rb`, master 2801817b and this commit against master 4f8b737c and the pick, over families 1 to 3 (976 programs): master's own C moved in every one (upstream's repr_of reads), and `diff master.c piece.c` is line for line the same on both masters in every one (560 with a change, 416 with none). The rows are carried.

### Cost (callgrind, instructions; master 2801817b against this commit; `cost-fx/`)

| program | master gcc | this commit gcc | master clang | this commit clang |
|---|---|---|---|---|
| tst_stmt (the reader's shape): class Q with its own then, `v = [5, q][0]`, `v.then` 200,000 times as a statement | 77,429,920 | 78,437,482 | 77,450,105 | 78,257,666 |
| tst_own: the same with the value read from an Array each turn, 300,000 calls | 120,010,017 | 121,821,358 | 120,360,006 | 121,571,522 |
| tst_none: no then of its own (same C) | 122,124,135 | 122,125,263 | 124,875,226 | 124,874,099 |
| then_none: the value kept, no then of its own (same C) | 124,594,842 | 124,593,714 | 124,946,872 | 124,946,872 |
| tst_obj: the class's object in the box (master prints 0 for 300,000) | 119,181,485 | 8,765,945 | 119,231,476 | 8,127,390 |
| tst_typed: a made local, `k.then` 300,000 times (master prints 0) | 118,824,288 | 2,765,325 | 118,572,211 | 3,026,681 |

tst_stmt: +5.04 a call with gcc, +4.04 with clang, of 387 (the reader's figures on his program). tst_own: +6.04 and +4.04, of 400. So "four to six" was two programs' figures told as one; the body now names both. The two same-C rows move by about 1,100 instructions between runs.

## The five sentences

1. "did not build; it now builds": gone. The body says master builds few such programs (one whose method answers nil builds), names the three kinds of line that run for the first time, and says a line that does not build by itself still keeps the program from building.
2. The subclass sentence: "called with the value used on a receiver typed as the parent".
3. The cost: both programs and both compilers named, first in the body.
4. The message's "a then the program defines was never called": gone; it says the arm made the Enumerator without asking whether the receiver's class defines the name.
5. "Not covered" opens with the receiver not proved an object.

## Finds for the miner (master, none built here)

1. A nil in a typed object slot reached through a hole of a typed Array (`a = [W.new]; a[2] = W.new; a.map { |b| b.n }`) runs a user method with no self: the nil fact takes the block parameter as not nil.
2. Blockless `yield_self`, value dropped, on an object-typed local a write leaves nil, beside a class that defines yield_self: NoMethodError, where nil answers Kernel's yield_self; `then` in the same place does not raise (4 programs of family 3).
3. Master types a blockless call to a class's own then by the class's method and emits the Enumerator; where C lets it through (`p s.then.then`, an attr_reader named then) the Enumerator is printed as the class's object.
4. A boxed value's blockless `yield_self` makes an Enumerator that inspects with `:then` (the reader's nine lines).
