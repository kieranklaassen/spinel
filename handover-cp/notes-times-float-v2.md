# Notes, letter IN narrowed: a boxed String or Array times a Float (second form)

Class: FIX, no cost left. One commit. This form takes the place of the first hand-over (3da8ec132674, a fix with a stated cost of gcc's): the coordinator asked at 18:25 UTC 10-07 for the inverted test on the arms that paid, and the placement below pays nothing on any cell. The brief's `/` half (`row[0] / 2` prints 0 for a boxed String) is not here: the change that makes a boxed `/` or `%` beside a value that is no number raise (claude/poly-div-mod-operand-v4, 3cf64c62ac91) cures that witness; the coordinator agreed the narrowing at 16:48 UTC 10-07.

## The head

- The commit is 1f94cd612d0d1865a8ee1cc108d6545d5eaa248d on master 8dc5522541bb (tree 6602732af947; one final newline, author and committer dates equal, read from the clock).
- Built and measured on master 759d120fd207 (worktree m20, staged tree 24f1d5bceb1b). Master then moved to 8dc5522541bb: the piece merges clean, and the move touches no function the piece touches (function lists of both diffs over the three shared files src/codegen.c, src/compiler.c, src/compiler.h: none shared; lib/spinel_rt.h is not in the move). The one build on 8dc5522541bb: `make` rc 0; `ruby tools/gate.rb check` with the piece staged rc 0; the three tests 18 of 18 cells; right under `--share-strings`. Bare 8dc5522541bb (built): 32 wrong lines, 1 wrong line, right (6 of 18 cells). Six cost cells run again there with gcc and clang (Integer x Integer, String x Integer, Array x String, Rational x Integer, the Integer and the String mixed loops): 0 a call, but Array x String with gcc, 1.3 FEWER a call (386,417,735 to 386,016,605; the join allocates, and the collector's work moves with the layout).
- On 759d120fd207: `make` rc 0; `ruby tools/gate.rb check` with the piece staged rc 0; the three tests 18 of 18 cells (gcc, clang x SPINEL_GC_STRESS unset, 1, 2) and right under `--share-strings`. Bare 759d120fd207 (built): test/poly_times_float_count.rb prints 32 wrong lines, test/poly_times_float_count_big.rb 1 (TypeError for the ArgumentError), test/poly_times_own_star.rb is right (it guards the stand-down).
- lib/spinel_rt.h: 38 lines in, ONE existing line changed: the last statement of sp_poly_mul, `return sp_poly_binop_bad("*", a, b);`, is now `return sp_poly_times_tail(a, b);` (with a comment). CONTRIBUTING.md says the header's changes are additive only; this is the one line that is not, and it is what makes the cost 0 (below). sp_poly_binop_bad is unchanged, and sp_poly_times_tail calls it for every pair that is not a String or an Array with a Float count. Upstream's own merged change "Integer divmod, modulo and remainder by a Rational answer exactly" changes existing lines of that header the same way (108 in, 12 out).
- Runtime archive: untouched (header and compiler only).
- Expected files are CRuby 3.3.6 with `--enable-frozen-string-literal`; the 4.0 box stays open.

## The family (gen-times.rb: 3,132 programs)

14 receivers (a boxed String from an Array, a Hash, a method; an empty one; an appended one; five boxed Arrays; controls: a typed String, a typed Integer Array, a boxed Integer, a boxed Float) x 29 operands (11 boxed Floats: 2.5, 2.0, 0.5, 3.999999, -0.5, -1.5, 0.0, NaN, Infinity, 1e30, -1e30; typed and literal Floats; boxed and typed Integers; nil, a Symbol, true, a String, an Array, a Hash, a Rational, a Complex, a Bignum, an object with to_int, a plain object) x 10 routes (`*`, `*=` on a local, an attribute, an instance variable, an element; `send`, `public_send`, `inject(:*)`, in a block, `&.*`); the controls take two routes. gcc, SPINEL_GC_STRESS unset, 1 and 2; CRuby 3.3.6 the answer; kinds by times-intab.rb. Both trees run again on 759d120fd207 (times-family-table-tip.txt):

| 3,132 programs | master 759d120fd207 | the piece |
|---|---|---|
| right | 620 | 2,000 |
| raises where Ruby answers | 1,104 | 324 |
| raises another class than Ruby's | 714 | 114 |
| right class, other words | 649 | 649 |
| silently wrong | 3 | 3 |
| wrong value (loud in the output) | 10 | 10 |
| no build | 32 | 32 |

- 1,380 become right: 780 that raised TypeError where Ruby answers, 600 that raised TypeError where Ruby raises RangeError or ArgumentError. Receivers: all ten boxed ones; operands: the 11 boxed Floats and the typed and literal ones; all ten routes.
- Rule (a): the 620 right on master are right. Rule (b): no program that raised or did not build prints a wrong value; the three silent and ten wrong programs are master's, byte for byte.
- 1,732 programs print what master prints. 20 print something else that is not right: `[r, 2.5].inject(:*)` with a TYPED Float count (literal or a typed local; ten receivers). Master types the fold's value a Float; master raises TypeError in the multiply, the piece answers the repeat and raises at the conversion ("ArgumentError: invalid value for Float(): "abab"", "TypeError: can't convert Array into Float"). Loud on both, wrong on both; the body's "Not covered" says so. With a typed Integer count the same fold prints "0 Integer" on master and on the piece (master's silent fault, below).
- No output differs across the three stress settings on either tree.
- Every output file of this form on 759d120fd207 is byte for byte the first form's on 9274c732eaa2 (12,400 files compared); the set of changed programs is the same 1,400.
- clang: the 1,400 programs whose output changed were run again with clang on this form (759d120fd207), at the three stress settings: all 1,400 print what gcc prints (1,380 right, the 20 folds above), and none differs across stress.

## Attack sets (attack-times/, 41 programs; CRuby, master and the piece side by side)

Run again on this form: every output is the first form's.

- re_* (16) and dy_* (13): every way of giving String or Array a `*` (reopen, alias, alias_method, define_method, prepend, a module, a singleton def, Object, Kernel, Comparable, a subclass, method_missing, class_eval, instance_eval, send(:define_method), refine): in each the Float count keeps master's TypeError (the stand-down) or the program does not build on either tree; right-on-master lost 0.
- own_* (4): a `*` in a module nothing includes, a Struct's, a top-level def: the flag is set and the Float count keeps master's TypeError; a `**` alone does not set it and the repeat answers.
- rt_* (8): routes (a Method object, to_proc, a chain, a conditional), kinds (binary, UTF-8, frozen, nested, a Hash's value), edges (2**62 as a Float, the largest Float under the word, -0.0, 0.999...). 26 of 27 edge lines right; the one: `"ab" * 9.0e18` says "string size too big" where Ruby says "argument too big" (sp_str_repeat's words, the same for an Integer count on master). The rest that differ are Ruby 3.3's inspect of an Encoding and of a Hash.

## Corpus (6,418 programs: test/, benchmark/, packages/*/test; master 759d120fd207)

18 emit other C than master: 3 by the tree's path alone, 15 gain the one init line `sp_poly_times_own = 1;` (5 package tests of benchmark and bigdecimal, 10 tests that define a `*`). 0 refusal changes. The same 18 names as the first form.

## Cost (callgrind; cost-times/; master 759d120fd207; instructions a call, or a turn for the mixed loops)

| program | gcc | clang |
|---|---|---|
| Integer x Integer, Float x Float, Float x Integer | 0 | 0 |
| String x Integer | 0 | 0 |
| Array x Integer | 0 | 0 |
| Array x String, the join | 0 | 0 |
| Bignum x Integer, Rational x Integer | 0 | 0 |
| an object's own `*`, and beside one | 0 | 0 |
| six Integer operators a turn, five Float operators a turn | 0 | 0 |
| String and Array operators a turn | 0 | 0 |
| String x Float, the cured call | 483 | 460 |

The full list is cost-times/cells-tip.txt (label inF against m26; the totals differ by a few hundred instructions a program, the start-up's).

Placements measured before this one (gcc unless said):
- arms inside sp_poly_mul that call sp_str_repeat and sp_poly_array_repeat for a Float count: +1.0 on EVERY boxed multiply (Integer x Integer 52 to 53), +36 on Array x Integer: gcc inlined sp_poly_array_repeat as "called once" and stops with a second call site.
- an arm in sp_poly_binop_bad (sp_poly_mul untouched): every single-operator cell 0 with both compilers, but the mixed loops move: gcc +1 a turn on the Integer loop, clang +2 on the Float loop and +1 on the String loop (sp_poly_binop_bad's callers are laid out anew).
- a tail arm that tests the Float tag alone, the helper asking the receiver's kind and the flag: +1 to +6 on the single-operator cells.
- the first hand-over's form, a tail arm in sp_poly_mul and a SP_NOINLINE helper: clang 0 everywhere; gcc +1.0 on String x Integer (390), Array x String (1,285), Bignum x Integer (1,590), +3.0 on Rational x Integer (420), 2 to 4 fewer a turn on the mixed loops.
- this one: no test in sp_poly_mul at all; only the callee of its failing last line changes, and the new function is SP_NOINLINE. 0 everywhere.

Optcarrot: generated C identical on master and the piece (cmp). Its run on 759d120f: gcc 3,230,992,860 to 3,231,060,468 (+67,608, 0.0021%), clang 2,750,486,969 to 2,750,522,665 (+35,696, 0.0013%), checksum 59662. By function (callgrind_annotate): the difference is in sp_PolyPolyHash_get (+65,988 gcc, +33,120 clang); sp_poly_mul runs the same count. The counts repeat to within 350 instructions; why the Hash probe moves was not traced further (the piece changes no line of it; the binary's layout shifts with any new static function in the header).

## The stand-down's reach

`comp_program_defines_name(c, "*")` is true where any class or module of the program has a method of that name in its chain (def, alias, alias_method, define_method, a prepended or included module) or any def node of the program carries the name (a singleton def). It is by name and program-wide: a Vec with its own `*` in the program keeps master's TypeError for a boxed String times a Float. That is the price of not answering with the builtin where the program's String#* was meant: on master a boxed `*` never reaches a reopened String#* or Array#* (with an Integer count the builtin answers: silent, master's fault below).

## Master's own faults met on the way (none built; for the miner)

1. `[r, ti].inject(:*)`, r a boxed String or Array and ti a typed Integer, prints "0 Integer" where Ruby repeats (10 family rows, silent).
2. A reopened String#* or Array#* is never called through a boxed receiver: with an Integer count the builtin answers (silent).
3. A typed String times a boxed Bignum prints "" and a typed Integer Array times one prints [] where Ruby raises RangeError (3 family rows, silent).
4. `x = typed; x *= boxed` does not build for a typed String, or a typed Array with a Float (32 family rows).
5. A boxed Array times a huge Integer count fills memory where Ruby raises ArgumentError "argument too big".
6. `[r, ti].sum("")` prints "ab" where Ruby raises TypeError.
7. A typed Array times a typed Float is NoMethodError; a typed String times a typed Float casts with no check; sp_poly_arg_int_chk casts NaN (a typed String times a boxed NaN is "ArgumentError: negative argument"); the TypeError for a count that is nil, a Symbol or true says "into String".
8. bigdecimal_basic at SPINEL_GC_STRESS=2 reports "the mark reached a freed slot" on bare master (a rooting fault, not looked into).
