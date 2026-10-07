# Notes, letter IN narrowed: a boxed String or Array times a Float

Class: FIX WITH A STATED COST, gcc's alone (the body's first paragraph). One commit. The brief's `/` half (`row[0] / 2` prints 0 for a boxed String) is not here: the change that makes a boxed `/` or `%` beside a value that is no number raise (claude/poly-div-mod-operand-v4, 3cf64c62ac91) cures that witness, checked by building it; the coordinator agreed the narrowing at 16:48 UTC 10-07. The witness is still master's on the tip 759d120fd207 (`w27/div.rb`: prints 0).

## The head

- Built and measured on master 9274c732eaa2 (worktree in26; staged tree 9c2d6846694e) and, after master moved, on the tip 759d120fd207 (the same patch applies clean; staged tree 12ff52bbc5f4). The commit is 3da8ec132674012ecb2be9e6925112f750284fe9 on 759d120fd207 (one final newline, author and committer dates equal, read from the clock).
- The move 9274c732eaa2 to 759d120fd207 touches no function the piece touches (hunk-by-hunk function lists of both diffs: none shared; in lib/spinel_rt.h the move is at sp_File_pread and the divmod family, far below sp_poly_mul).
- On the tip: `make` rc 0; `ruby tools/gate.rb check` with the piece staged rc 0; the three tests 18 of 18 cells (gcc, clang x SPINEL_GC_STRESS unset, 1, 2) and right under `--share-strings`. Bare tip (built): test/poly_times_float_count.rb prints 32 wrong lines, test/poly_times_float_count_big.rb 1 (TypeError for the ArgumentError), test/poly_times_own_star.rb is right (it guards the stand-down). The same counts on 9274c732eaa2.
- lib/spinel_rt.h: 31 lines in, 1 changed (the tail of sp_poly_mul gains the arm before its `return sp_poly_binop_bad`); `git diff --word-diff` shows no removal. sp_poly_binop_bad is unchanged. Runtime archive: `nm -S` of lib/libspinel_rt.a is the same on master and the piece, on both tips (3,076 and 3,077 symbols, no size differs).
- Expected files are CRuby 3.3.6 with `--enable-frozen-string-literal`; the 4.0 box stays open.

## The family (gen-times.rb: 3,132 programs)

14 receivers (a boxed String from an Array, a Hash, a method; an empty one; an appended one; five boxed Arrays; controls: a typed String, a typed Integer Array, a boxed Integer, a boxed Float) x 29 operands (11 boxed Floats: 2.5, 2.0, 0.5, 3.999999, -0.5, -1.5, 0.0, NaN, Infinity, 1e30, -1e30; typed and literal Floats; boxed and typed Integers; nil, a Symbol, true, a String, an Array, a Hash, a Rational, a Complex, a Bignum, an object with to_int, a plain object) x 10 routes (`*`, `*=` on a local, an attribute, an instance variable, an element; `send`, `public_send`, `inject(:*)`, in a block, `&.*`); the controls take two routes. gcc, SPINEL_GC_STRESS unset, 1 and 2; CRuby 3.3.6 the answer; kinds by times-intab.rb.

| 3,132 programs | master 9274c732eaa2 | the piece |
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
- clang: the 1,400 programs whose output changed were run again with clang on the piece, at the three stress settings: all 1,400 print what gcc prints (1,380 right, the 20 folds above), and none differs across stress.

## Attack sets (attack-times/, 41 programs; CRuby, master and the piece side by side)

- re_* (16) and dy_* (13): every way of giving String or Array a `*` (reopen, alias, alias_method, define_method, prepend, a module, a singleton def, Object, Kernel, Comparable, a subclass, method_missing, class_eval, instance_eval, send(:define_method), refine): in each the Float count keeps master's TypeError (the stand-down) or the program does not build on either tree; right-on-master lost 0.
- own_* (4): a `*` in a module nothing includes, a Struct's, a top-level def: the flag is set and the Float count keeps master's TypeError; a `**` alone does not set it and the repeat answers.
- rt_* (8): routes (a Method object, to_proc, a chain, a conditional), kinds (binary, UTF-8, frozen, nested, a Hash's value), edges (2**62 as a Float, the largest Float under the word, -0.0, 0.999...). 26 of 27 edge lines right; the one: `"ab" * 9.0e18` says "string size too big" where Ruby says "argument too big" (sp_str_repeat's words, the same for an Integer count on master). The rest that differ are Ruby 3.3's inspect of an Encoding and of a Hash.

## Corpus (6,418 programs: test/, benchmark/, packages/*/test)

18 emit other C than master: 3 by the tree's path alone, 15 gain the one init line `sp_poly_times_own = 1;` (5 package tests of benchmark and bigdecimal, 10 tests that define a `*`). 0 refusal changes. The 15 were run on both trees in the six cells: 83 of 90 right on each, the same 7 failing on master (stress cells of bigdecimal_basic, coerce_poly_operand and benchmark_tms: master's own, the same output but for the addresses a stress report prints).

## Cost (callgrind; cost-times/; instructions a call, or a turn for the mixed loops)

| program | gcc 9274c732 | gcc 759d120f | clang, both |
|---|---|---|---|
| Integer x Integer (52) | 0 | 0 | 0 |
| Float x Float, Float x Integer | 0 | 0 | 0 |
| String x Integer (390) | +1.0 | +1.0 | 0 |
| Array x Integer (789) | 0 | 0 | 0 |
| Array x String, the join (1,285) | +1.0 | +1.0 | 0 |
| Bignum x Integer (1,590) | +1.0 | +1.0 | 0 |
| Rational x Integer (420) | +3.0 | +3.0 | 0 |
| an object's own `*` (201), and beside one | 0 | 0 | 0 |
| six Integer operators a turn (328) | -2.0 | -2.0 | 0 |
| five Float operators a turn (277) | -2.0 | -2.0 | 0 |
| String and Array operators a turn (2,850) | -4.0 | -4.0 | 0 |
| String x Float, the cured call | 481 | 481 | 458 |

Totals on 759d120f, gcc, master to the piece: si 117,130,488 to 117,430,538; as 385,615,101 to 385,916,082; big 476,876,545 to 477,176,572; rat 126,167,704 to 127,067,758 (300,000 calls each); mixi 164,178,871 to 163,178,853 and mixf 138,675,671 to 137,675,680 (500,000 turns); mixs 570,033,445 to 569,232,281 (200,000 turns). The full list of both tips and both compilers is cost-times/cells.txt.

Placements measured before this one (gcc unless said), which is why the arm is where it is:
- arms inside sp_poly_mul that call sp_str_repeat and sp_poly_array_repeat for a Float count: +1.0 on EVERY boxed multiply (Integer x Integer 52 to 53), +36 on Array x Integer: gcc inlined sp_poly_array_repeat as "called once" and stops with a second call site.
- an arm in sp_poly_binop_bad (sp_poly_mul untouched): every single-operator cell 0 with both compilers, but the mixed loops move: gcc +1 a turn on the Integer loop, clang +2 on the Float loop and +1 on the String loop (sp_poly_binop_bad's callers are laid out anew).
- a tail arm that tests the Float tag alone, the helper asking the receiver's kind and the flag: +1 to +6 on the single-operator cells (Integer x Integer +1, String x Integer +2, Rational x Integer +6).
- this one, a tail arm and a SP_NOINLINE helper: clang 0 everywhere, gcc as the table.

Optcarrot: generated C identical on master and the piece, on both tips (12,172 lines, cmp). Its run on 759d120f: gcc 3,230,992,860 to 3,231,103,772 (+110,912, 0.0034%), clang 2,750,486,969 to 2,750,520,263 (+33,294, 0.0012%), checksum 59662; three runs each on 9274c732: the counts repeat to within 350 instructions. By function (callgrind_annotate): the whole difference is sp_PolyPolyHash_get (+115,220 gcc, +33,120 clang) and sp_PolyPolyHash_set (+180, +240); sp_poly_mul runs 4,528 fewer with gcc and the same with clang. Why the Hash probe moves was not traced further (the piece changes no line of it; the binary's layout shifts).

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
