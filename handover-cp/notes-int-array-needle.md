# Notes, letter FS: a typed Integer Array searched for a boxed number that is no Integer

Class: FIX WITH A STATED COST (the body's first paragraph): a boxed needle that is neither an Integer, nil nor a number pays the one new tag question. One commit.

## The head

- Commit a76c414187930b9d4db56b869e2c5de48679c19b on master 8dc5522541bb (tree e632ac9c1585; one final newline, author and committer dates equal, read from the clock).
- Built and measured on master 759d120fd207 (staged tree 1e7c872aa7c5), then built again on the tip 8dc5522541bb: the same patch applies clean, and the move (56 commits) touches no function the piece touches.
- On the BARE tip 8dc5522541bb first: the test prints 11 of its 33 lines wrong and misses one (0 of 6 cells); the piece is not cured there. The piece on that tip: `make` rc 0; `ruby tools/gate.rb check` with the piece staged rc 0; the test 6 of 6 cells; right under `--share-strings`; the attack set prints what it printed on 759d120fd207; the nineteen cost programs give the same differences on both tips, with both compilers, to the hundredth; corpus and optcarrot below.
- On 759d120fd207: `make` rc 0; `ruby tools/gate.rb check` with the piece staged rc 0; test/int_array_boxed_number_needle.rb 6 of 6 cells (gcc, clang x SPINEL_GC_STRESS unset, 1, 2), right under `--share-strings`; bare master prints 11 of the 33 lines wrong and misses one.
- lib/spinel_rt.h: 17 lines in, none changed (one new function, sp_poly_int_needle, after sp_poly_rb_equal). src/codegen_call_recv.c: the two arms' emitted lines move into one static function, emit_int_array_boxed_search, above emit_kind_array_call; that function shrinks (815 lines to 801; on the tip 816 to 801). No runtime archive change.
- Expected file: CRuby 3.3.6 with `--enable-frozen-string-literal`; the 4.0 box stays open.

## The cure

`Array#index`, `find_index`, `rindex`, `include?` and `member?` ask `element == needle`. For a boxed needle the typed Integer Array's two arms searched the slots for an Integer's word or the nil slot's, and answered "not there" (nil, false, -1) for any other tag. A Float or a Rational can equal an Integer: `2 == 2.0`, `3 == Rational(6, 2)`.

A number equals at most ONE Integer. sp_poly_int_needle(v) hands it back boxed:
- a Float f with `f > -2**w` and `f < 2**w` (w the word's 63) and `f == (sp_float)(sp_int)f`: the Integer `(sp_int)f`. NaN and the infinities fail the range test; a Float with a fraction fails the third. The cast is defined inside the range. -2**63 is excluded: it is the nil slot's word (SP_INT_NIL), no element, and an Integer Array with a nil in it must not find the nil for it.
- a Rational whose denominator is 1 (and whose numerator is not the nil slot's word): the numerator.
- any other value: itself (its tag is no Integer's: not there).

The emitted line (for a boxed needle; a typed nil needle keeps master's line byte for byte):

    ({ sp_IntArray *_ta = RECV; SP_GC_ROOT(_ta); sp_RbVal _tv = NEEDLE; sp_int _tk;
       (_tv.tag == SP_TAG_INT ? (_tk = _tv.v.i, 1)
        : _tv.tag == SP_TAG_NIL ? (_tk = SP_INT_NIL, 1)
        : (((1 << SP_TAG_FLT | 1 << SP_TAG_OBJ) >> _tv.tag) & 1)
          && (_tv = sp_poly_int_needle(_tv), _tk = _tv.v.i, _tv.tag == SP_TAG_INT))
       ? sp_IntArray_<fn>(_ta, _tk) : MISS; })

The receiver is evaluated and rooted before the needle, as on master; the helper allocates nothing.

## Why this shape (callgrind, instructions a lookup, against master's line; var/ harness on the emitted C, an Array of eight, a needle that changes each turn)

The inverted test cannot be made at compile time: a box carries no record of the kinds it holds. So the question was which emitted shape leaves the Integer and nil needles at master's count. Twenty-four shapes were compiled by hand-editing the emitted C of seven programs (cost-fs/shapes.cells.txt, 420 cells; v0 there is master's line; the harness is cost-fs/var/). What they showed:

- master's line makes ONE call after the root push (the Integer's and nil's searches merge), and gcc then keeps two copies of the tag tests, one behind each way out of the push (pushed, or the slow path). ANY second callee on a later arm (a per-element scan, a cold function, a pointer or a scalar argument: v1, B, C, Bp, Cp, K, S1) makes gcc keep the "pushed" flag in a register and test it after the call: +5 on `include?` with an Integer needle, in every such shape.
- choosing the needle's word first and calling the search ONCE (S4, S5, T1) keeps gcc's two copies: 0 on `include?`, 5 to 7 fewer on `index`.
- clang is the other way about: it wants the tag question as a bit test (`(mask >> tag) & 1`, T1: +2 on `include?` with a changing needle, 0 with a fixed one) and loses 5 to 7 with the two compares (T2, T3). The same shape as an inline function (T5 to T7) costs gcc 2 to 4.
- the first form of the cure, a per-element scan asking `==` (sp_poly_eq, then an exact Float comparison), cost a Float needle 120 to 780 a lookup; the conversion costs it 52 to 95, most of it master's own scan that now finds.

## Cost (callgrind; master 759d120fd207 and 8dc5522541bb, the same figures; the compiler's own output; 300,000 lookups in an Array of eight)

| needle | gcc | clang |
|---|---|---|
| Integer, `include?` (61 to 71 on master) | 0 | 0 to +2 |
| Integer, `index`, `rindex` (83 to 108) | -5 to -7 | -2 to -3 |
| nil, `index` (112) | -6.5 | +0.5 |
| a String or a Symbol (20 to 47) | +5 | +6 to +9 |
| Integers and Strings in turn (52) | +2.5 | +5.5 |
| a Float that is found (the cured lines) | +56 to +95 | +56 to +93 |
| a Float with a fraction (not there, 20) | +31 | +28 |

cost-fs/cells-759d.txt and cost-fs/cells-tip.txt have the nineteen programs' totals for both trees and both compilers.

Optcarrot: generated C identical to master's but for the worktree's path in `#line`, on both tips. Run on 759d120fd207: gcc 3,230,992,860 to 3,230,994,427 (+1,567), clang 2,750,486,969 to 2,750,488,983 (+2,014); checksum 59662.

## The family (gen-fs.rb: 2,616 programs; kinds by times-intab.rb, the breakdown by fs-breakdown.rb)

5 receivers (an Integer Array literal, one with a nil, one built by `<<`, one in an instance variable, a Float Array as control) x 6 methods (index, find_index, rindex, include?, member?, count) x 21 needles (1, 9, 1.0, 1.5, -0.0, 2.0, NaN, Infinity, 2.0**62, 2.0**53, 2**70, Rational(1, 1), Rational(3, 2), Complex(1, 0), Complex(1, 1), a String, a Symbol, nil, true, an object with ==, a plain object) x 4 sources of the box (an Array's element, a Hash's value, a conditional, a method's value); and 96 with the needle typed. gcc, SPINEL_GC_STRESS unset, 1 and 2; CRuby 3.3.6 the answer.

| 2,616 programs | master 759d120f | the piece |
|---|---|---|
| right | 2,002 | 2,302 |
| wrong value | 608 | 308 |
| no build | 6 | 6 |

- 300 become right: the three typed Integer receivers (the literal, the one built by `<<`, the instance variable) x the five needles that equal an element (1.0, 2.0, -0.0, 2.0**62, Rational(1, 1)) x index, find_index, rindex, include?, member? x the four sources.
- Rule (a): the 2,002 right on master are right. Rule (b): nothing raised or failed to build on master in a way the piece changes; the 6 that do not build are master's (a typed Complex or Rational handed to `count`).
- 2,316 programs print master's bytes. The 308 that stay wrong are among them: Complex(1, 0) (120: every receiver and method), an object whose `==` answers true (120), a Float Array searched for Rational(1, 1) (20), and 48 with a typed needle (a typed Complex(1, 0) or Rational(1, 1); and a typed 1.5, which master truncates and finds: below).
- The literal with a nil in it is a boxed Array on master and was right throughout (504 controls); `count` goes another way and already finds a boxed Float (420, unchanged).
- No output differs across the three stress settings on either tree.
- clang: the 300 programs whose output changed were run again with clang on the piece built on the tip 8dc5522541bb, at the three stress settings: all 300 print what gcc prints on 759d120fd207, all right, none differing across stress.

## Attack set (attack-fs/, 20 programs; CRuby, master and the piece side by side, on both tips)

- routes: the lookup in a conditional, a modifier, `+ 10`, `.to_s`, a Hash key, `&&` and `||`, through a method's parameter, after map, select, dup, reverse, sort, on `(1..5).to_a`: master prints "no", nil and dies with NoMethodError at `xs.index(n) + 10`; the piece prints every line right (CRuby 3.3 spells the Hash's inspect `{true=>1}`, the one line that differs from the container's Ruby).
- flt_edge: 0.0, -0.0, 1.0, -1.0, 2.0**62, 2.0**63, -(2.0**63), 2.0**53 and the Float next to 2**53 + 1, NaN, the infinities, 1e30, -1e30, 0.5, -0.5, two denormals, the Float next to 2**62 + 1: right.
- rat_norm: Rational(4, 2), Rational(6, 3), 3r, a sum and a product of Rationals, Rational(3, 2), Rational(-2, 1), with the five methods: right.
- side_effects: a needle and a receiver that log their evaluation: each runs once, the receiver first, as on master.
- loop_gc: 1,000 turns over six needles in an Array of 200, a String made between the lookups: right at the three stress settings.
- empty (an emptied Array, then one element), ivar_recv (an instance variable's Array through three methods), typed_keep (a typed Integer and a typed nil needle, `count`), nil_slot (a literal with nils, and a plain Integer Array beside it): right.
- n1 to n7: an Integer Array that holds nil seven ways (a literal, `<< nil`, `xs[1] = nil`, Array.new(3), a map that answers nil, push, none) searched for -(2.0**63), nil, 3.0, 1.0, Rational(3, 1), 2.0: right on the piece; n5 and n7, the two that are typed Integer Arrays, are wrong on master. -(2.0**63) is never found: not where the nil sits either.
- kinds, not_covered, boxed_recv, delete_left: the "Not covered" rows below; the piece prints master's bytes for each of those lines.

## Corpus (test/, benchmark/, packages/*/test: 6,418 programs on 759d120fd207, 6,446 on 8dc5522541bb)

On each tip 11 programs emit other C than master: 3 by the tree's path alone, and 8 tests that search a typed Integer Array with a boxed needle (def_delegators_const_splat, int_array_nil_elements, int_array_search_poly_needle, issue_2970, nilable_int_slot_boxed_nil, poly_iter_to_a_params, sample_random_boxed, splat_index_runtime_length). 0 refusal changes. The 8 were run on both trees in the six cells, on both tips: 48 of 48 right on each.

## Not covered (each run on master and on the piece: the same wrong answer on both)

- `xs.delete(n)` with such a needle (nil; Ruby deletes): another thread's piece.
- a Complex whose imaginary part is 0 (`Complex(2, 0)`), boxed or typed.
- a Rational made of Bignums that reduces to a word (`Rational(2**70, 2**69)`): a BigRational here.
- an Integer Array that is itself in a box (`row[0].include?(n)`): the boxed receiver's dispatch.
- a typed Rational needle (`xs.include?(Rational(2, 1))`): the typed needle's arm. (A whole typed Float needle is right on master; one with a fraction is not: below.)
- a Float Array searched for a boxed Rational.
- an object needle whose class defines `==` keeps master's answer (not there, no call): the piece that makes `1 == obj` ask the object is another thread's.

## Master's own faults met on the way (none built; for the miner)

1. A typed Float needle with a fraction is truncated and found: `[1, 2].include?(1.5)` prints true, `index(1.5)` 0, `count(1.5)` 2 (silent; 12 family rows).
2. A typed Rational or Complex needle: `xs.include?(Rational(2, 1))` and `xs.index(Complex(1, 0))` print false and nil; `xs.count(Rational(1, 1))` does not build.
3. An Integer Array that is itself in a box: `row[0].include?(2.0)` prints false.
4. A boxed Complex(2, 0) in an Integer Array, and in a Float Array: not found (`count` too).
5. A Float Array searched for a boxed Rational(1, 1): not found.
6. `xs.delete(2.0)` on an Integer Array answers nil and deletes nothing.
7. An object whose class defines `==` is never asked by `index`, `include?` or `count` on an Integer Array (Ruby's `1 == obj` asks the object).
8. A boxed Rational made of Bignums that reduces to a word (`Rational(2**70, 2**69)`) is not found.
