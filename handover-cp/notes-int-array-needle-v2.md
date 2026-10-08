# Notes: an Integer Array searched for a boxed Float or Rational, second form, on master 5d762fb16716

A delta against a76c414187930b9d4db56b869e2c5de48679c19b (on 8dc5522541bb), for the reader who measured it. The ruling it answers: build the class-id test so that only a Float and a Rational reach the call; the Float's and the Rational's share goes in the first lines of the description by the builder's own measure.

## What changed

One emitted line and its comment, in `emit_int_array_boxed_search` (src/codegen_call_recv.c). The guard ahead of `sp_poly_int_needle` was the tag question alone:

    (((1 << SP_TAG_FLT | 1 << SP_TAG_OBJ) >> _t.tag) & 1) && (_t = sp_poly_int_needle(_t), ...)

and is now

    (((1 << SP_TAG_FLT | 1 << SP_TAG_OBJ) >> _t.tag) & 1) && (_t.tag != SP_TAG_OBJ || _t.cls_id == SP_BUILTIN_RATIONAL)
      && (_t = sp_poly_int_needle(_t), ...)

So a Bignum, an Array, a Hash, a Range, a program's object no longer make the call; they pay the class-id compare. `sp_poly_int_needle` (lib/spinel_rt.h, 17 lines added, none changed) and the test are as they were. The diff against the tip: lib/spinel_rt.h +17, src/codegen_call_recv.c +34 -20, the test and its `.expected`.

## Why this shape (18 measured)

int-array-needle-shapes.txt: 18 ways to write the guard, each patched into the C the tree emits for 32 programs and compiled as the driver does; instructions a lookup more than master, by needle kind, for `include?` and `index` on a local and on an attribute. The shapes are in shapes.rb.

- The plain `tag == FLT || sp_poly_is_rational(v)` (shape a) costs gcc 2 on an Integer needle with `include?` and 10 on a String.
- A ternary on the OBJ tag (e, m, r) is gcc's best for a String (3 to 4) and an object (5 to 6), and clang's worst for an Integer (6) and nil (11).
- The bit test followed by `tag != OBJ || cls_id == RATIONAL` (c, the one taken; k compiles to the same) keeps gcc's Integer and nil needles at the first form's count (0 and 1 on `include?`, fewer on `index`), costs clang 1 on an Integer, and brings an object down from 25 to 13 with gcc and from 20 to 17 with clang.

The Integer needle is the common one, so the shape that leaves it alone with both compilers was taken over the one that is best for an object.

## The cost by needle kind, on 5d762fb16716

int-array-needle-cost-by-kind.txt (76 programs, cost-fs2/, gcc and clang; master's own count in brackets). In short, instructions a lookup more than master:

| the needle | gcc | clang |
|---|---|---|
| an Integer (found, not found, an Array that can hold nil) | 0 on `include?`, 3 to 7 fewer on `index` and `rindex` | 1; 2 more or 2 fewer where the Array can hold nil |
| nil | 1 on `include?`, 4 to 6 fewer on `index` | 3 to 6 |
| a String, a Symbol, true, a Bignum | 4 to 6 | 5 to 10 |
| an Array, a Hash, a program's object | 12 to 14 | 13 to 17 |
| a Float with a fraction, NaN, 1.0e19 | 27 to 39 | 20 to 30 |
| a Rational with a fraction | 30 to 33 | 31 to 33 |
| a whole Float, Rational(5, 1) (the cure: master answers "not there") | 76 to 96 | 72 to 93 |

Master's own count for a needle that is not there for its kind is 34 to 47 a lookup. The description opens with this table.

## What was run on 5d762fb16716

Both trees built from nothing (make rc 0; `nm lib/libspinel_rt.a` finds sp_poly_recur_hash_cycles). The bare tip does not cure it: the test prints 11 of its 33 lines wrong there and misses one.

- The test: 6 of 6 cells (gcc and clang, SPINEL_GC_STRESS unset, 1, 2); with `--share-strings` right; `ruby tools/gate.rb check` with the piece staged: rc 0.
- 13 attacks (attack-fs/): 6 wrong on master and right now, 2 right on both, 4 wrong on both with master's bytes, 1 (`routes`) wrong on both with 18 of its lines cured and one Hash#inspect line in Ruby 3.3's format. Right on master and not with the piece: 0.
- The family (gen-fs.rb, 2,616 programs): 1,401 emit master's C. Of the 1,215 that change: 795 right on master stay right, 300 wrong on master are right, 120 are wrong on both and print master's bytes at the three stress levels (a Complex needle, a Rational of Bignums, an object with its own `==`: "Not covered"). Right lost: 0. No program's verdict differs between the stress levels. With clang, every third of the 1,215 (405 programs): 375 right and 30 wrong, each program as with gcc.
- The corpus (6,495 programs of the tip, the C each tree emits, compared byte for byte): 6,484 identical, 11 differ, no refusal changes. Three of the 11 differ between any two trees, by the length of the tree's own path in a `require` line (test/conditional_require_line, test/require_expression_lines, test/source_file_required). The other eight take the new line (test/def_delegators_const_splat, int_array_nil_elements, int_array_search_poly_needle, issue_2970, nilable_int_slot_boxed_nil, poly_iter_to_a_params, sample_random_boxed, splat_index_runtime_length) and pass as before: 48 of 48 cells. The emit ran with no time or memory bound, so a refusal would be the compiler's own.
- Optcarrot's generated C is unchanged (cmp).

## The moves

5d762fb16716 to 3d629868df96 (six merges): the piece merges with exit 0; no file is shared. Not rebuilt there.

## Texts

int-array-needle-commit-message-v2.txt and int-array-needle-pr-body-v2.md; the title is v1's.
