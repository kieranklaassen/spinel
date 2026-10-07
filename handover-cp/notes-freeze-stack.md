# Notes: a class's own freeze and frozen?, a stack of two (letters GE and GF) on master 42557a3c0e7c

Two pull requests, in this order:

1. "super in a freeze or frozen? override is Object's": a plain fix, no cost.
2. "A class's own freeze and frozen? run through a boxed value", above it with "Depends on": a fix with a stated cost (3 to 7 instructions a boxed call, in a program where a class defines the name; the cost opens its body).

They take the place of the one commit 5066ac160144 (on 9274c732eaa2) that reader 6 passed. That commit is withdrawn: it loses a right program (below), and master's move to 8dc5522541bb took away the reason it was one commit.

## The commits

| | on 42557a3c0e7c (hand these over) | on 8dc5522541bb (where the tables below were measured) |
|---|---|---|
| commit 1 | 7405ec86e505ae88fa9bf5e35f73cdb5e3bacadc, tree df13960cf031 | d530c0ae267f51fdcf87da385f5bfe679b2f3284, tree e1382a5aac65 |
| commit 2, on commit 1 | a2ced545cdd9c44215c46eedd11edde3a9236c01, tree 3f24e101b75d | 404476ebbbf2d88de90596796ae0f84400b9313c, tree 0d222dac7dce |

Each message ends in one newline; author and committer dates are equal (epoch 1791413095 for the pair on 42557a3c). The added and removed lines of each commit are the same on both tips, in the same order (cmp of the two lists: 214 lines, 194 lines). Commit 2's message names the tip of its cost figures, so it differs between the two tips in that one word; commit 1's message is ed1d2f45ca40's byte for byte.

Numstat. Commit 1: src/analyze.c 10 in; src/analyze_infer.c 9 in, 2 out; src/codegen.c 18 in; src/compiler.c 23 in; src/compiler.h 1 in; test/super_freeze_builtin.rb 124 and its `.expected` 27. Commit 2: src/codegen_call.c 12 in; src/codegen_call_object.c 4 in, 1 out; src/codegen_call_recv.c 3 in, 1 out; src/codegen_internal.h 1 in; test/poly_own_freeze.rb 85 and 47; test/poly_own_freeze_or_nil.rb 32 and 8. That is 22 lines of source in commit 2.

## For reader 6, as a delta on what it read

- Commit 1 is GE as read (ed1d2f45ca40 on 2801817b82e1): the same added and removed lines, line for line (cmp), and the same message. Nothing to read again but the tip.
- Commit 2 against the boxed half of 5066ac160144, file by file: src/codegen_call_object.c, src/codegen_internal.h and test/poly_own_freeze_or_nil.rb with its `.expected` are the same lines. src/codegen_call.c goes from 28 lines to 12: `poly_builtin_answers_recv` is gone, and `poly_dispatch_keeps_builtin` gains its first line, `if (nt_ref(c->nt, id, "block") >= 0) return 0;`. src/codegen_call_recv.c goes from 17 lines to 4: `emit_poly_freeze_builtin` is gone and the freeze line is master's again (`sp_poly_freeze(` recv `)`) under the new condition. test/poly_own_freeze.rb gains two lines with a two-line comment, and one comment loses five words; its `.expected` gains six lines.

## What was wrong with the commit that was read (rule (a))

A `freeze` or `frozen?` call through a box that carries a block, in a program where a class defines the name:

```ruby
class Doc; def freeze = self; end
[5, "s", nil, :k].each { |v| p v.freeze { 1 } }     # master and Ruby: 5, "s", nil, :k
```

The read commit stood the builtin arm down for every such call. The dispatch that takes the call has no builtin in its default arm when the call carries a block (`emit_poly_builtin_default_at` returns at `nt_ref(nt, id, "block") >= 0 && argc == 0`), so 5, the String and nil raised NoMethodError. Found by an attack set written for every reason that arm can decline, which the first attack sets did not have: 20 programs of the place family below (a block through a box). The repair is the one line above: the arm stands down only where the default arm keeps the builtin, and a block is the first thing that arm asks. A call with a block through a box therefore does what master does (the builtin answers, the class's own method is not called there): said under "Not covered" in the body, pinned by the two new test lines.

## What was taken out, and why the piece is two again

On 8dc5522541bb a call on a box of "the object or nil" is typed boxed. The read commit's repair for a slot typed by the class (`poly_builtin_answers_recv`, `emit_poly_freeze_builtin`, the `as_recv` lines) therefore fires in no program: with and without it the compiler emits the same C for 2,950 programs (the boxed-slot family, the three earlier families of 792, 492 and 514, and 72 attacks, tests, probes and twins; `same.rb`). It is gone.

The same move ends the reason for one commit. The super fix alone used to stop three right programs building (`y = x.freeze` on such a box, typed for the object where the boxed line made a boxed value). On 8dc5522541bb it loses none: over 1,883 programs its C differs from master's for 372, of which 63 were right and stay right. So an order exists: the super fix first, the boxed arms above it. The other order still does not exist: the boxed arms before the super fix send a `freeze` that ends in `super` to the class, where the `super` raises (46 lines right on master turned into NoMethodError, measured on the first GF).

The type half of `poly_dispatch_keeps_builtin` (the builtin's answer known, and the slot boxed or of the builtin's type) is reached by none of those 2,950 programs either (a debug variant with the question taken out emits the same C for them). It stays: it is the default arm's own test, and the arm stands down by the inverted test (only where a line of master's proves the dispatch answers the other values).

## Measured on 8dc5522541bb (CRuby 3.3.6 with --enable-frozen-string-literal is the answer; gcc; SPINEL_GC_STRESS unset, 1, 2)

Trees: M = master; E = commit 1 alone; F = commit 2 on commit 1.

Families: the boxed-slot family (`gen-freeze-slot.rb`, 1,080 programs, as in notes-freeze-one-commit.md); the place family (`gen-ctx.rb`, 666 programs, new: six definitions (a freeze answering self, ending in `super`, answering a Symbol; a frozen? answering true, ending in `super`, answering a Symbol) x three boxes (an Array's element beside 5, a String, nil and a Symbol; the object or nil through `x = t == 0 ? d : nil`; a method's picked value) x 37 places for the call: dropped, kept, with a block (braces, do, a block argument), under `&.`, in an interpolation, a condition, `if`, `unless`, `!`, `&&`, `||`, an argument, before `nil?`, twice, `==`, an Array and a Hash literal, a parameter, a `map`, a reassignment, an instance variable, `send` and `public_send`, a `case`, a multiple assignment, parentheses, a rescue modifier, a `begin`, `then`, `tap`, `frozen?` after it); the odd definitions (`attack-freeze-defs/`, 68 programs, new, written by hand: the method made by an alias, define_method, an attr reader or writer, a module, Kernel, Object, the top level, a Struct, a singleton, a class method; with an empty body, an optional parameter, a `yield`, a raise, an exit, a recursion; answering an Integer, a String, an instance variable; defined in a class never instantiated; each dropped and used); the attack set on the box typed by the class (`attack-freeze-or-nil/`, 36 programs, as before).

### Commit 1 alone (E against M)

1,883 programs (the four sets, the twins and the probes). The C is master's for 1,511. Of the 372 whose C changes: 63 right stay right; 4 wrong, 2 not building and 1 dying become right; the others were a build failure or a raise at the `super` on master and now run on to a fault master has without the `super` (rule (b), reached not made, below). Right on M and not right on E: 0.

Rule (b) by the line. 278 rows of the two families are not right on E. 277 print, byte for byte, what master prints for the twin program: `self` where the `super` stood in a `freeze`, `false` where it stood in a `frozen?` (`twin.rb`; the twins are programs of the same families). The other one, `fz_super__ornil__frozenq`, has the twin's line by the line that computes it (the nil slot's `frozen?`, which the twin and the program compute by the same C; the lines before it differ by the `super`). The six faults those rows meet are named in the body, each with its twin.

Test 6 of 6 cells (gcc, clang x unset, 1, 2); `ruby tools/gate.rb check` staged rc 0; `--share-strings` right. Corpus (6,446 programs): 3 differ, by the path in a comment; no refusal changes. Optcarrot's C identical. The cost programs, and a program that defines such an override and never names it, emit master's C.

### Commit 2 against its base (F against E)

1,746 programs (the two families), by program:

| E / F | programs |
|---|---|
| same C on M, E and F | 177 |
| right / right | 750 |
| wrong / right | 598 |
| no build / right | 119 |
| wrong / wrong | 102 |

Right on E and not right on F: 0. Of the 102 wrong on both, 100 print the same bytes on E and F. Two (`fq_super__elem__case`, `fq_super__pick__case`) differ only in the count of the override's calls, which is now right; the line still wrong is `case x.frozen?` with `when nil` first taking false, a fault of master's `case` (letter NZ).

### The stack against master (F against M)

| | right | wrong | no build |
|---|---|---|---|
| boxed-slot family, M | 744 | 278 | 58 |
| boxed-slot family, F | 1,065 | 15 | 0 |

Right on M and not right on F: 0. The 15 wrong on both are `nil__param`: nil in a parameter typed by the class (master's typed-slot nil hole; master's bytes).

Place family: 489 of 666 change their C. Of those, M right 0, F right 402, 87 wrong: 65 on the slot typed by the class that holds nil (`ornil`, the nil hole again), 20 with a block on the call through a box (the builtin answers, as on master: "Not covered"), 2 the `case` above. No program prints differently at the three stress levels.

Attack set on the box typed by the class: M right 10, F right 33 of 36. `arysub` does not build on any tree; `ivar_self` and `ivar_super` are the nil hole in an instance variable (E's bytes).

Odd definitions: M right 35, F right 60 of 68; the other 8 print E's bytes.

Tests 18 of 18 cells; on M `test/poly_own_freeze.rb` prints 15 of its 47 lines, 4 of them wrong, and dies at the `super`; `test/poly_own_freeze_or_nil.rb` prints 2 lines wrong; `test/super_freeze_builtin.rb` does not build. On E the first prints 5 of 47 wrong and the second 2 of 8. `ruby tools/gate.rb check` staged rc 0; `--share-strings` right for the three. Corpus: 3 differ, by the path; no refusal changes. Optcarrot's C identical.

One reached row outside the families, for commit 2: a typed object's own `frozen?` that answers a Symbol prints true. A program with a boxed call beside it (`p row[0].frozen?`) did not build on E and now builds and prints true for the typed call: master's line with the boxed call's value written in its place (probe `q5`).

### Cost (callgrind, instructions a call, a builtin value read from a mixed Array, 3,000,000 calls)

| | gcc | clang |
|---|---|---|
| `frozen?`, five kinds of value | +3.0 | +3.0 |
| `frozen?`, an Integer and a String | +4.0 | +7.0 |
| `freeze`, five kinds of value | +4.2 | -1.0 |
| `freeze`, an Integer and a String | +3.0 | +7.0 |

E's cells are M's to the instruction (the same C). A program with no `freeze` or `frozen?` of its own emits master's C under F.

## The move to 42557a3c0e7c (about 70 commits)

Master moved from 8dc5522541bb to 42557a3c0e7c while the pair was being cut. Both commits merge into the new tip clean, by exit status.

- Commit 1 shares no function with the move (one neighbouring declaration in src/compiler.h). Commit 2 shares `emit_poly_call0_arms`, where the move changes other lines, so it is rebuilt on the tip and read as a delta. `emit_poly_builtin_default_at`, whose tests `poly_dispatch_keeps_builtin` repeats, is the same 74 lines on both tips.
- Bare 42557a3c: `test/super_freeze_builtin.rb` does not build; `test/poly_own_freeze.rb` prints 15 of its 47 lines, 4 of them wrong, and dies at the `super`; `test/poly_own_freeze_or_nil.rb` prints 2 of 8 wrong. The tip cures nothing here.
- Commit 1 alone on the tip: its test 6 of 6 cells; staged `ruby tools/gate.rb check` rc 0; `--share-strings` right. The boxed tests on it: 5 of 47 and 2 of 8 lines wrong, as the body of commit 2 says.
- The stack on the tip: 18 of 18 cells; staged gate check rc 0; `--share-strings` right for the three.
- Bridge (`bridge2.rb`: is the piece's C, read as a diff against its base's C, the same lines on both tips?). Commit 1 against master: boxed-slot family 1,080 of 1,080 (120 with a change), place family 663 of 663 (219 with a change; the other 3 master refuses and commit 1 compiles, on both tips), odd definitions 68 of 68 (none changes). Commit 2 against commit 1: 1,080 of 1,080 (580 with a change), 666 of 666 (400), 68 of 68 (48). Master's own C for these programs is the same on both tips for all but 2 of the odd definitions.
- The runtime moved too, so the programs were run again with the stack's build on the tip (gcc; unset, 1, 2) and each output compared with the one on 8dc5522541bb (`eqout.rb`): boxed-slot family 1,080 of 1,080 the same bytes (1,065 right, 15 wrong); the 489 place programs whose C changes, 489 of 489 (402 right, 87 wrong); odd definitions 68 of 68 (60 right, 6 wrong, 2 not building, as on master).
- Corpus on the tip (6,469 programs): master against commit 1, master against the stack, commit 1 against the stack: 3 differ each time, by the path in a comment; no refusal changes. Optcarrot's C is identical on the three trees.
- Cost on the tip: the table above to the tenth of an instruction (gcc +3.0, +4.0, +4.2, +3.0; clang +3.0, +7.0, -1.0, +7.0); commit 1's cells are master's to the instruction. The body and the message of commit 2 name 42557a3c for these figures.

## Master's faults met, for the miner

- A Boolean false in a `case` whose first arm is `when nil` takes the nil arm (letter NZ).
- An own `frozen?` that answers a Symbol prints true or false.
- A frozen object's instance variable write is not refused in another class of its chain (an inherited `poke`).
- `+=` on a member of a frozen Struct does not raise.
- A slot typed by the class that holds nil runs the method with no object: a local written `x = cond ? d : nil`, a block's local, a parameter, an instance variable.
- A String that interpolates `x.frozen?` ahead of `x.freeze` prints true for the first.
- A `freeze` or `frozen?` call with a block through a box never reaches the class's method.

## Files

Texts: super-freeze-title-v1.txt, super-freeze-pr-body-v3.md, super-freeze-commit-message-v1.txt; boxed-own-freeze-title-v1.txt, boxed-own-freeze-pr-body-v2.md, boxed-own-freeze-commit-message-v2.txt. Generators and sets: gen-ctx.rb (the place family), attack-freeze-defs/ (68), with gen-freeze-slot.rb and attack-freeze-or-nil/ already here. Scripts: freeze-stack.rb (E against F by program), freeze-twin.rb (the twins), same.rb and chg.rb (which programs emit the same C on two trees), eqout.rb (two runs of a family, output by output).
