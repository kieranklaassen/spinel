### Both pieces on master c534bbf9abac (master's tip at 07:12 UTC, 10-07)

Master moved thirteen commits past 5390d300: the default SIGINT and SIGTERM handlers (a line in every program's `main`, `lib/sp_cold.c`, `lib/spinel_rt.h`), the builtin modules as modules (`lib/sp_poly_cold.c`, `codegen.c`, `codegen_call.c`), a Float Array's chunk family (`codegen_call_array.c`), two `&.` fixes (`analyze_desugar.c`, `codegen_iter.c`) and `String#scan` with a block at a method's tail (`codegen_stmt.c`). The runtime changes for every program, so no row is carried: the tests, the corpus C and the cost are run again here. The families are not run again; their C is compared (below).

The two commits pick onto c534bbf9 with no conflict and nothing changed by hand:

- piece 1, 1439e838f925 picked: 0ddd9cfaa7d2fcdba73bafc07410ca55b25fdd64, tree 0d8f3b726f376f8f69b16596b9a634a69730f44f
- piece 2, 15911319b19c picked: bf35428ebf17399869d37fff85a4d10fd1fde8dc, tree 31ff66512da37d2e74b0dd1b90b28f347e3694bc

Upstream changed one function that piece 1 also changes, `emit_unresolved_call`: its hunk words the receiver of a NoMethodError as "module Math", some 560 lines below the `chr` arm, and no test of the piece prints a message. Piece 2 shares no function with the move (`tail_iter_receiver` is upstream's only hunk in `codegen_stmt.c`).

gcc 13.3.0 and clang 18.1.3, SPINEL_GC_STRESS unset, 1 and 2, CRuby 3.3.6 for the expected answers.

#### Piece 1

- Tests: the four of the piece and upstream's three boxed tests (`boxed_walk_own_method_arity`, `boxed_dig_receiver_checked`, `boxed_handle_face_args`) pass under gcc and clang at the three stress levels (14 of 14 lines, 42 runs). On master c534bbf9 the piece's four are as before: `boxed_integer_only_receiver` 39 of 71 lines wrong, `boxed_integer_only_bignum` 5 of 12, `boxed_integer_only_own_method` does not build, `boxed_integer_only_inherited` passes.
- Corpus C (`-c --no-line-map` over `test/`, `benchmark/`, `packages/*/test/` and optcarrot; 6,363 programs on master): 6,280 identical, 83 differ; 7 of the 83 differ only by the build tree's path or revision string; 76 change (69 in `test/`, 7 in `packages/`), the same 76 programs as on 5390d300, 264 lines after masking temp numbers, every one at a cured call. 0 benchmarks, optcarrot identical, 0 refusal changes (the 4 files only on the piece's side are its tests).
- The 76 programs' tests and the 4 new tests: 80 of 80 at stress unset; at stress 1 and 2, 76 pass and the same four fail the same way on master c534bbf9 (`packages/ffi/test/ffi_libc.rb`, `ffi_nil_numeric_arg.rb`, `ffi_store_string.rb` at stress 2; `test/hash_iterator_boxed_callable.rb` at 1 and 2).
- Cost, instructions a call against master (callgrind, 2,000,000 calls, an Integer in the box), gcc / clang: `odd?` -1 / -2, `even?` 0 / -2, `~` -2 / -2, `chr(Encoding::UTF_8)` -2 / 0. The cells of 5390d300.
- The sibling shapes (35 programs, among them `&.`) and the brief's 197 programs, run again under gcc: every row is the row of 5390d300, on master and on the piece (sibling: 28 cured, 3 right, 4 not right; brief: 28 of master's 43 wrong cured, 0 lost).
- The families' C: for each of the 1,800 family programs, the 1,188 ancestor programs and the brief's 197, `diff master.c piece.c` on c534bbf9 is line for line the diff on 5390d300 (2,146 with a change, 1,039 with none); no refusal moved. Master's own C moved in all 3,185.
- The share-strings tests by hand (`--share-strings`, stress unset and 1): 82 of 82. `tools/gate.rb check`: exit 0.

#### Piece 2

- Tests: `test/boxed_attr_bitwise_op_assign.rb` and upstream's three pass under gcc and clang at the three stress levels (8 of 8 lines, 24 runs). On master c534bbf9 the piece's test has 94 of 118 lines wrong.
- Corpus C: 6,355 identical, 8 differ; 7 by path or revision string only; 1 changes (`test/poly_nil_op_assign.rb`, one line, the `|=` on a boxed attribute). optcarrot identical, 0 refusal changes. That program's test and the new test pass at the three stress levels.
- Cost against master, gcc / clang: `&=`, `|=`, `^=` with a plain operand -1 / -1; with a call as operand gcc +1, -1, -1 (as on 5390d300) and clang 0, 0, 0. The clang cells were -1 on 5390d300: the piece's count is the same on both masters (58,630,565 then, 58,631,239 now, for 2,000,000 `&=`), master's own went from 60,630,556 to 58,631,325.
- The brief's 197 programs under gcc: every row the row of 5390d300 (15 of master's 43 wrong cured, 0 lost).
- The families' C: for the order family's 180, the family's 924 (45 of them refused by `-c` on master and on the piece, on both masters), the supplement's 300 and the brief's 197, the diff against master on c534bbf9 is line for line the diff on 5390d300 (1,152 with a change, 404 with none); no refusal moved.
- The share-strings tests by hand: 82 of 82. `tools/gate.rb check`: exit 0.

#### A line moved in notes-piece1.md

The coordinator ruled that the one WRONG row that became a raise of another class is no break of either rule and belongs under "Not here". Read the last paragraph before "Corrected from the second form's fold" as this line of that list:

- `class NilClass; def odd? = to_i.odd?; end` with nil in the box raises NameError where master raised NoMethodError; Ruby answers false. Wrong on master and here, by another class.

The boxed Regexp's `~` (NoMethodError where master answered -1) stays where the body names it, under "Not covered".

Not run: `make gate` (no Ruby 4.0 here).
