# Notes: a class's own freeze and frozen?, one commit (letters GE and GF together)

Class: fix with a stated cost (GF's cost, unchanged). ONE commit, in the place of the two stacked pieces "super in a freeze or frozen? override is Object's" (GE) and "A class's own freeze and frozen? run through a boxed value" (GF). Title: "A class's own freeze and frozen?: super is Object's, a box calls them".

## Why one commit

Each piece alone breaks a program that is right on master.

- GF before GE: through a box master ran the builtin, so a class whose freeze ends in `super` was right there by accident. Sending the call to the class reaches the `super`, which raises on master: 46 lines right on master turned into NoMethodError (measured before GE existed; notes-gf-v1.md).
- GE alone: a `super` that answers the object makes the override's value the object. The analysis types `x.freeze` by the class where the box is "the object or nil" (`v = nil; x = cond ? d : v`: the read is narrowed to the class, the slot is boxed), and master's boxed freeze line emits a boxed value there. `y = x.freeze` then does not build: 3 programs of the family below that master runs right (nil in the box, `NilClass` and counter 0), and `arg_nil_super` of the attack set. It is master's own no-build for `def freeze; self; end` in the same program, and for a program with no override at all (`fr_true__nil__tern__isother__used`: a class with only `frozen?`).
- Reader 6's finding on the first GF (the dispatch's default arm raises for nil where the call is typed by the class) is the other face of the same typing.

So the order rule has no order to give, and the two travel as one (the rule for two faults whose halves each turn a crash into the other's wrong answer).

## The commits

- On master 2801817b82e1, where everything below is measured: f44ae59ed7203fc049ab822c1f89af468ff39d31, tree 080f320d5958.
- On master 9274c732eaa2 (the tip at 15:55 UTC 10-07): 5066ac16014480f2bcf0f3dd446ce70541cf3201, tree cdabaaa34e6a, one final newline, author and committer dates equal. The same 426 added and removed lines as on 2801817b, in the same order (cmp of the two lists).
- Numstat: src/analyze.c 10 in; src/analyze_infer.c 9 in, 2 out; src/codegen.c 18 in; src/codegen_call.c 27 in, 1 out; src/codegen_call_object.c 4 in, 1 out; src/codegen_call_recv.c 16 in, 1 out; src/codegen_internal.h 1 in; src/compiler.c 23 in; src/compiler.h 1 in; three tests with their `.expected` (124 and 27, 80 and 41, 32 and 8).
- For reader 6, as a delta on what it read: GE's change is untouched (src/analyze.c, src/analyze_infer.c, src/codegen.c, src/compiler.c, src/compiler.h and test/super_freeze_builtin.rb are GE's ed1d2f45ca40 byte for byte). Against the first GF (de4c7c7f1fbd above ed1d2f45ca40) `git diff de4c7c7f1fbd f44ae59ed720` is src/codegen_call.c 27 in, 1 out; src/codegen_call_recv.c and src/codegen_call_object.c (the two conditions gain `&& poly_dispatch_keeps_builtin(c, id)`, and the freeze line calls a helper); src/codegen_internal.h 1 in; 11 lines more in test/poly_own_freeze.rb; the new test/poly_own_freeze_or_nil.rb.

## What the delta is

1. `poly_dispatch_keeps_builtin` (src/codegen_call.c, declared in src/codegen_internal.h): the test `emit_poly_builtin_default_at` makes before it keeps the builtin in the dispatch's default arm (the builtin's answer is known, and the slot is boxed or of the builtin's type). The two boxed arms stand down only where it holds: `!(user_defines_or_reads(c, name) && poly_dispatch_keeps_builtin(c, id))`. Elsewhere the dispatch's default raises NoMethodError for nil, which was reader 6's finding 1; and its second program (`class Lock; def freeze = :locked; end` beside a box of a Doc or nil) builds and is right.
2. `poly_builtin_answers_recv` (static, src/codegen_call.c): for `freeze` with no argument, the builtin's answer boxed (TY_POLY) and the dispatch's slot typed for a plain object (no by-value class, no Array subclass), where every candidate class's `freeze` answers that same type (`comp_poly_candidates`, each `scopes[mi].ret == ret`). There `emit_poly_builtin_default_at` keeps the arm and takes the builtin's value back into the slot by `emit_unbox_text` (master's checked unbox, `sp_poly_unbox_cls`: nil is NULL, an object of the class or below is its pointer, anything else raises TypeError), and `poly_dispatch_keeps_builtin` answers yes. So through a box of the object or nil the class's freeze runs for the object and nil stays nil.
3. `emit_poly_freeze_builtin` (static, src/codegen_call_recv.c): the builtin line `sp_poly_freeze(recv)`, taken back into the slot the same way where the call is typed for a plain object. This is the line GE alone needs (the three programs), and it is where a box typed by the class comes when part 2 does not hold (two classes whose freeze answer different types: master's dispatch does not build there for ANY method, `def me = self` in two classes and `y = x.me` on a box of one or nil; a find for the miner).

Not touched: emit_poly_call, emit_call_body, infer_call_inner (the three over 1,000 lines; emit_poly_call0_arms is 513 lines and grows by none: the helper stands above it), the nil helpers, emit_super's other names, the then arm of emit_call_freeze_dup_arms (letter FX's).

## Measured (master 2801817b; CRuby 3.3.6 with --enable-frozen-string-literal is the answer; gcc; SPINEL_GC_STRESS unset, 1, 2)

Trees: M = master; E = GE alone (ed1d2f45ca40); F = the first GF above GE (de4c7c7f1fbd); C = this commit.

### The boxed-slot family (`gen-freeze-slot.rb`, 1,080 programs)

Who defines what (a freeze answering self, a Symbol, nil, ending in super; a frozen? answering true or a Symbol) x the other value of the box (nil, an Integer, a String, an Array, another object) x how the box is made (a ternary, an `if` assignment, an Array element, a Hash value, a method's value, a local a block writes) x which value is there at run time x the call (dropped, its value used, frozen? after it). Each program prints a value or the class of a raise, then the counter of the override's calls.

| | right | wrong | raise | no build |
|---|---|---|---|---|
| M | 729 | 271 | 4 | 76 |
| E | 728 | 270 | 0 | 82 |
| F | 1,026 | 18 | 24 | 12 |
| C | 1,047 | 27 | 0 | 6 |

By program, M / E / C: right on M and on C 729 (3 of them not building on E); wrong on M, right on C 246; no build on M, right on C 70; raise on M, right on C 2; raise on M, wrong on C 2 (reached, below); wrong on both 25; no build on both 6. Right on M or on E and not right on C: 0. The first GF lost 18 programs right on M to the raise (reader 6's finding), 3 of them the ones that do not build on E.

The 584 programs whose C differs from master's all print the same bytes at the three stress levels (579 right, 5 wrong).

What stays wrong or does not build on C, all in the box typed by the class (nil the other value): a freeze that answers nil or a Symbol (the builtin runs, master's C: 9 wrong, 6 no build); the local a block writes, typed by the class and nil at run time (master's typed-slot nil hole, 14, of which 2 are the reached lines); an own frozen? answering a Symbol prints true (4: 3 through the box, where master printed false and did not call it, 1 on the typed local, master's line).

### The attack set on the box typed by the class (`attack-freeze-or-nil/`, 36 programs)

The value of `x.freeze` used as a receiver, in a chain, as an argument, in an Array and a Hash literal, in an interpolation, as a condition, with `||`, reassigned to `x`, under `&.`; a method's value; an ivar; a loop and a while whose other value changes kind; a cell a lambda writes; a subclass, a subclass with its own freeze; a module's freeze; a Struct; a small scalar class; an Array subclass; each with a freeze answering self and one ending in super.

M right 9, E right 8, C right 30. Right on M: all right on C (`arg_nil_super` does not build on E). Not right on C: `arysub` (no build on all three), `ivar_self` and `ivar_super` (the typed-slot nil hole; the second is reached, r3 below), `modfz` (a module's freeze: the builtin runs, as on master), `subown_self` and `subown_super` (two classes whose freeze answer different types: master does not build; reached, r4).

### The three earlier families (1,798 programs; notes-gf-v1.md has their tables)

C emits, for every one of the 492, 514 and 792 programs, the C the first GF emitted (`moved.rb`: same 492, same 514, same 792): none of them has a box typed by the class. Their rows stand as read: 492 of 492 right; 431 of 514 (78 wrong with GE's line, fault A; 5 no build on all); 390 of 792 (the frozen? programs 188 of 228).

### Reader 6's two crosses as the attack set

The two generators are the reader's, cut from its reports by their sums (r6-gensf.rb e3bef581632e, r6-gengf.rb c1e5e9fb2809). A program whose C on this commit is the first GF's C (the tree the reader read) keeps the reader's row; the others were run here on M, E and C.

- gensf (GE's cross, 2,895 programs): the first GF's C for every one (9 refused by both).
- gengf (4,004 programs): the first GF's C for 3,896. The 108 that differ all have nil as the other value of a box made by a ternary or a method (the box typed by the class). Right on M 58: all 58 right on C (4 of them do not build on E: the reader's two and their `&.` forms). No build on M, right on C 38 (6 of them right on E). No build on M, wrong on C 10 (reached; below). No build on all three 2 (`fzodd`, a freeze answering a Symbol, its value kept). So right on master and lost: 0, where the first GF lost the reader's 48. The same bytes at the three stress levels for all 108.
- The 10 (`g__other__nil__*`): no override in Doc, a class Lock beside it whose frozen? answers a Symbol. Master does not build them (`p v.frozen?` on the nil local, `r = x.freeze`, `x&.freeze`); here they build, and their one wrong line is `p lk.frozen?` on the typed Lock, `true` for `:maybe`, master's own line. `twin-other.rb`: the twin has a plain value where each call master cannot build stood (`x` for the boxed freeze, `true` for `v.frozen?`, `x.nil?` for `x.frozen?`); master's bytes for the twin are this commit's, 10 of 10. On the tip (bare 9274c732eaa2 and 5066ac160144, both built) the 10 rows are the same.

### Under clang

The 584 programs of the boxed-slot family whose C differs from master's: the rows are the gcc rows, and all 2,336 output files (stress unset, 1 and 2) are byte for byte gcc's.

### Corpus

6,375 programs (test/, benchmark/, packages/*/test/), `-c --no-line-map`: the C of this commit is master's for every one but 7, which differ only by the tree's path in a string and the revision in RUBY_DESCRIPTION; none refused. optcarrot: identical, 12,341 lines.

### Cost (callgrind, instructions; 3,000,000 calls on a value read from a mixed Array; `cost-gf/`)

The six programs emit the C they emitted on the first GF, so its cells stand: a builtin value in the box beside a class with its own frozen? pays +3.0 a call with gcc and clang; beside a class with its own freeze +4.2 a call with gcc, -1.0 with clang. With no such class in the program the C is master's.

Master's own charge for the names it already sends to the dispatch, in the shape reader 4 named for letter FX (`row = [5, "s"]; v = row[0]`; the call dropped in a while loop of 200,000; the same program with and without `class Q; def NAME ...; end`, the method called once on a typed Q, the box never holding a Q), on bare master 1df866be9c54 (`cost-k/`): `v.dup` +5.02 gcc, +4.03 clang a call; `v.to_s` +5.04, +4.05; `v.nil?` +1.52, +2.43; `v.hash`, `v.freeze`, `v.frozen?` 0 (their arms do not stand down on master).

The cost is stated in the body's first lines beside master's cells, not cut (the coordinator's ruling of 16:07 UTC 10-07); the body says a later cost change, one answer for every name master dispatches this way, would repay them all.

GE's cost, unchanged: a class whose override runs pays on its instance variable stores the frozen check a class with a bare `freeze` pays (2.5 instructions a store with gcc, 4.5 with clang).

### On the tip 9274c732eaa2

Built there (5066ac160144, worktree gf26): the three tests pass with gcc and clang at SPINEL_GC_STRESS unset, 1 and 2 (18 of 18 cells) and built with `--share-strings`; `ruby tools/gate.rb check` with the piece staged exits 0 (`make gate` not run: no Ruby 4.0 here). Bare master 9274c732eaa2, built: test/super_freeze_builtin.rb and test/poly_own_freeze.rb do not build (line 80 "void value not ignored", line 79 "incompatible types when assigning to type 'sp_Doc *' from type 'sp_RbVal'"); test/poly_own_freeze_or_nil.rb builds and prints 3 of its 8 lines wrong.

The rows read on 2801817b stand on the tip: for every program, the piece's C read as a diff against its master's C (`bridge2.rb`; the four emitted here) is the same on 9274c732eaa2 as on 2801817b. Boxed-slot family: 584 with the same change, 496 with none. The three earlier families: 379 and 113; 409 and 105; 144 and 648. The attack set: 31 and 2, 1 refused by both on both, and 2 (`ret_self`, `ret_super`) whose changed lines differ only by the numbers of temporaries and frame slots, which master itself renumbered. Master's own C moved between the two for all of them (the revision string).

## Reached, not made (`twin-freeze.rb`, both halves by script)

Five programs stand for the two routes. Half 1: master's bytes for the twin are this commit's bytes for the program, 5 of 5.

- r1, r2 (`fz_super__nil__param__isother__drop`, `__used`) and r3 (`ivar_super`): a slot typed by the class, nil at run time. Master runs the class's freeze with no object and dies at its `super` (NoMethodError); here the `super` answers, and the counter says 1 where Ruby says 0. The twin has `self` where the `super` was: master prints `ok`, 1 (`NilClass`, 1; `true`, `true`, 2), this commit's bytes. Half 2: the changed lines are the override's own (its type, the `super` line, the `return`), the use of its value, and the numbers of the rescue's temporaries.
- r4, r5: a box typed by one class beside a second class whose freeze has another type; the class's object in the box; `y = x.freeze`. Master does not build. Here the builtin answers and the class's freeze is not called (`Sub`, 0 for 10). The twin is `y = x`: master prints `Sub`, 0. Half 2: one line changes, `lv_y = sp_poly_freeze(lv_x)` into the same call inside the unbox.

GE's own reached lines stand as its notes have them (notes-ge-v1.md): the 24 poke lines (fault A) and the Struct member `+=`; its 14 counter lines through a box are right here.

## Not here (as on master)

- Through a box typed by the class: a freeze that answers something other than the object; two classes whose freeze answer different types; a module's freeze. The builtin runs.
- A typed object's own frozen? that answers something other than true or false prints true or false (also through the box typed by the class).
- A slot typed by the class that holds nil runs the class's method with no object.
- A frozen object's instance variable write is not refused in a method of another class of its chain; `+=` on a member of a frozen Struct is not refused.

## Finds for the miner (master, none built here)

1. `y = x.freeze` on a box of an object or nil did not build with NO override in the program (cured here by the line of part 3).
2. The boxed class dispatch does not build where two classes define a method that answers `self` and the box is typed by one of them (`class A; def me = self; end; class B; def me = self; end; v = nil; x = cond ? a : v; y = x.me`: "assignment to 'sp_A *' from incompatible pointer type 'sp_B *'").
3. Its default arm raises NoMethodError for nil where the builtin has an answer and the slot is typed by the class (`x.dup`, `x.to_a`; sent before).
4. An own frozen? answering a Symbol through a box of the object or nil prints true.
