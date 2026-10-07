# Notes, letter GF: a class's own freeze and frozen? through a boxed value (v1)

Class: fix, with a small cost on a neighbour stated in the body (a builtin value in a box beside a class with its own `freeze` or `frozen?` pays the dispatch). One commit. STACKED on letter GE ("super in a freeze or frozen? override is Object's"): the body says "Depends on" in words.

## The commits

- On GE's measured commit (ed1d2f45ca40, on master 2801817b82e1): de4c7c7f1fbd5da22e62b233679e7ce652cd6037, tree 078ae86322ef.
- On master 7bdde552e6ee (the tip at 12:40 and 12:46 UTC 10-07): GE picked 30c29281de06a2cc4071952b2f29f2c6348e99b2 (tree f507f2cdaac5), this piece above it 6d3f6e3a07df43bffc32d12b79e065173c7f27c7 (tree 254e9c25f3c6). Built there; `test/poly_own_freeze.rb` and GE's `test/super_freeze_builtin.rb` pass with gcc and clang at SPINEL_GC_STRESS unset, 1 and 2, and with `--share-strings`; `ruby tools/gate.rb check` with the piece staged exits 0. From 5a752fceb48c (where GE's handed-over pick 2b3faad288de stands) to 7bdde552 master touches none of the functions of GE or of this piece.
- Numstat: src/codegen_call_object.c 4 in, 1 out; src/codegen_call_recv.c 2 in, 1 out; test/poly_own_freeze.rb 69 in; test/poly_own_freeze.rb.expected 38 in.

## What it changes

Two conditions, each master's own idiom (`!user_defines_or_reads(c, name)`, asked at some forty boxed arms):

- `emit_poly_call0_arms` (src/codegen_call_recv.c), the freeze line: `if (sp_streq(name, "freeze"))` emitted `sp_poly_freeze(recv)` for every boxed receiver. It now stands down in a program where a class defines or reads `freeze`, as the `nil?` arm at the top of the same function does. Witness: `row = [d, 5]; row[0].freeze; p d.sealed` with Doc's own freeze setting @sealed: false for true, and the object is frozen for real (`p d.frozen?` true for false).
- `emit_call_freeze_dup_arms` (src/codegen_call_object.c), the boxed frozen? arm: `if (frr.kind == RK_BOXED)` emitted `sp_poly_frozen(recv)`. Same condition, as the dup and clone arm of the same function has. Witness: `class Draft; def frozen? = true; end; row = [Draft.new, 5]; p row[0].frozen?`: false for true.

The call then reaches the boxed class switch: the class's method for its objects; the default arm comes back to these two lines for every other value (`user_defines_or_reads` answers 0 inside a builtin arm), so an Integer, a String, nil, a Symbol, a Float, an Array or another class's object in the box takes the builtin as before.

Not touched: emit_poly_call, emit_call_body, infer_call_inner (the three over 1,000 lines), the nil helpers, emit_super, the then arm of emit_call_freeze_dup_arms (letter FX's ground: the two pieces touch different arms of that function and merge clean).

## Why it stands on GE

Through a box master ran the builtin, so a class whose freeze ends in `super` was right there by accident: the override never ran. Sending the call to the class reaches the `super`, which raised NoMethodError on master. Measured before GE existed (the tree "fy" of the FX notes): 46 lines right on master turned into that raise, every one in a definer whose freeze calls super. On GE they are right.

## Measured

Trees: m9 = master 2801817b; fs2 = GE's commit; fg = this commit. CRuby 3.3.6 with --enable-frozen-string-literal is the answer; gcc and clang; SPINEL_GC_STRESS unset, 1, 2. Every program prints a value or the class of a raise on each line. Three families, 1,798 programs; each is read against master and against GE, the base of this piece.

| family | master right | GE right | this piece right |
|---|---|---|---|
| freeze through a box (`gen-gf-freeze.rb`, 492) | 358 | 367 | 492 |
| GE's super family (`gen-ge-super.rb`, 514) | 120 | 382 | 431 |
| own frozen?, then, itself (`gen-gf-frozen.rb`, 792; its 228 frozen? programs) | 294 (92) | 294 (92) | 390 (188) |

### The freeze family (492)

Who defines freeze (the class; with `super`; answering a Symbol; with its own frozen? beside it; that pair with `super`; frozen? alone; none; a parent; a parent with `super`; a module; an alias; define_method; a default argument; private; a singleton method; a class method; another class; a child) x the receiver (typed; in a box: the object, an Integer, a String, an Array, nil, and more) x four programs.

- Against GE: right -> right 367, wrong -> right 125; by line where both ran: 1,405 right on both, 214 wrong to right, 0 others. Rule (a) 0, rule (b) 0, nothing reached.
- Against master: right -> right 358 (113 with master's C), wrong -> right 134. Rule (a) 0.

### GE's super family (514)

- Against GE: right -> right 382, wrong -> right 49 (GE's fault B: the override's counter stayed 0 through a box), wrong -> wrong 78 with THE SAME LINE on each (GE's fault A, a frozen object's write not refused in another class of its chain: master's, with no override in the program), no build -> no build 5. By line: 2,682 right on both, 55 wrong to right, 78 wrong and the same, 0 others. Rule (a) 0, rule (b) 0, nothing reached.
- Against master: 120 right -> 431. Of the 78 wrong, 24 stand in programs master did not build: they are 24 of GE's 38 lines reached and not made, the poke lines, twinned in GE's notes (both halves); this piece prints for them the line GE prints. GE's other 14 (the counter lines) are right here.

### The frozen? programs (228 of the 792)

Who defines frozen? x answering true or a Symbol x the receiver, typed or in a box x two programs.

- Against GE (whose C is master's for all 792): no build -> right 72, wrong -> right 24, right -> right 92, wrong -> wrong 30 and no build -> no build 10 (master's C: a typed object's frozen? that answers a Symbol prints true or false, and its no-builds). By line: 303 right on both, 58 wrong to right, 52 wrong and the same, 0 others. Rule (a) 0, rule (b) 0.
- The 564 then, yield_self and itself programs: master's C, all of them.

### Under clang

Every program whose C differs from master's (379, 409, 144): the rows are the gcc rows, and all 2,781 output files (stress unset, 1, 2) are byte for byte gcc's. No output differs between stress levels.

### Corpus

6,375 programs (test/, benchmark/, packages/*/test/): the generated C of GE with this piece is master's for every one (three differ only by the worktree's path in a string); none refused. optcarrot: C identical, 12,341 lines.

### Cost (callgrind, instructions; `cost-gf/`; 3,000,000 calls on a value read from a mixed Array)

| program | master gcc | this piece gcc | master clang | this piece clang |
|---|---|---|---|---|
| frz_none: `x.frozen?`, no frozen? of its own in the program (same C) | 109,166,010 | 109,166,010 | 130,627,286 | 130,627,286 |
| frz_own: the same beside a class with its own frozen?, the value a builtin | 111,065,977 | 120,065,978 | 126,027,335 | 135,027,410 |
| frz_obj: the class's object in the box (master prints 0 for 3,000,000) | 81,665,882 | 81,665,977 | 87,627,237 | 69,627,411 |
| fz_none: `x.freeze`, no freeze of its own (same C) | 100,165,867 | 100,165,867 | 121,127,292 | 121,127,292 |
| fz_own: the same beside a class with its own freeze, the value a builtin | 102,665,876 | 115,265,847 | 116,427,296 | 113,427,458 |
| fz_obj: the class's object in the box (master prints 0 for 3,000,000) | 69,665,875 | 99,665,940 | 66,627,297 | 90,627,555 |

GE alone is master in every cell (same C). The neighbour that pays: a builtin value in the box in a program where a class defines the name, +3.0 instructions a `frozen?` call with both compilers, +4.2 a `freeze` call with gcc and -1.0 with clang, of about 35 to 45 a call. The two _obj rows are the cured calls: the method now runs.

### Other checks

- share-strings tests by hand (the Makefile's loop, 83 tests, plain and SPINEL_GC_STRESS=1): 0 failures. The piece's test and GE's also pass built with `--share-strings`.
- `ruby tools/gate.rb check` with the piece staged: exit 0 on the commit and on the pick. `make gate` itself not run here (no Ruby 4.0).
- test/poly_own_freeze.rb: 38 lines, .expected from CRuby 3.3.6 with --enable-frozen-string-literal (no Hash inspect, no address, no message in it); the CRuby 4.0 box stays open. On master it dies at Cart's `super`; on GE alone five of its lines are wrong; passes here, gcc and clang, three stress levels.

## Merge checks

- claude/reader-string-freeze-n3bxdb 4d1a8230cb49 (it adds to `emit_call_freeze_dup_arms` too): with this commit, src/codegen_call_object.c merges by itself; the one conflict is src/codegen_stmt.c, which that head has with master and this piece does not touch. In a scratch tree (this commit merged with that head, the conflict settled by keeping master's condition line under that head's new lines; never pushed) all four tests pass with gcc and clang at the three stress levels: its `test/reader_string_freeze.rb` and `test/captured_string_freeze.rb`, this piece's, and GE's.
- The boxed scrub repair, claude/scrub-block-boxed-receiver-repair-on-cf1821c3 4b47d421c9f1 (its two lines sit beside the freeze line in `emit_poly_call0_arms`): `git merge-tree` clean. Merge-check only, as asked.
- Letter FX's carry f36eff65cd94 (the then arm of `emit_call_freeze_dup_arms`): clean.

## Finds for the miner (master, none built here)

1. A typed object's frozen? that answers a non-boolean prints true or false (the 30 above; find 7 of the FX notes).
2. GE's fault A stands (a frozen object's write is not refused in a method of another class of its chain).
