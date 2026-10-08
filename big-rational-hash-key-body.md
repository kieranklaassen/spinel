<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a stated cost.** With gcc a Hash lookup by a Rational, a Range or a Complex key pays 1 instruction (0.4% of the loop measured below) and one by an Integer key takes 1 less; with clang every key is on the same count as before. The arm was measured in two places (under **Cost**): where it is, gcc lays the function out 1 instruction dearer for those three keys and clang's count does not move; before the hook for user objects gcc's count does not move and clang's is 1 dearer for a word-sized Rational. Neither is zero with both compilers.

A Rational whose numerator or denominator is a Bignum was never found as a Hash key. A plain run:

```ruby
x = [Rational(2**70, 3), :a][0]
h = { x => 1 }
k = [Rational(2**70, 3), :a][0]
p h[k], h.key?(k)
p [x, k].tally.size
```

```
spinel diff: output-diff
  program: key.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,3 @@
-1
-true
-1
+nil
+false
+2
```

`fetch`, `include?`, `dig`, `values_at`, `delete` and a counter kept in `Hash.new(0)` missed the same way. The hash of such a key goes by value already (`sp_rbval_hash_key`), but the comparison a lookup runs, `sp_rbval_eql_key` (lib/spinel_rt.h), had an arm for the word-sized Rational alone, so a Rational of Bignums was equal to itself only.

`sp_brat_eql_key` compares two of them part by part. It also answers for one of each kind: an operation's answer stays a Rational of Bignums when its parts fit a word again (`x / 2**70` is `(1/3)`), and it is the key the word-sized `(1/3)` is, as the hash takes it. It allocates nothing: a lookup compares keys while it holds values nothing else does.

**Measured against CRuby 3.3.6 on master 3d629868.** 289 generated programs: seventeen boxed values (five Rationals of Bignums: a Bignum numerator, a Bignum denominator, a negative one, one whose parts fit a word again, one with denominator 1; two word-sized Rationals, an Integer, a Float, a Bignum, a String, a Symbol, an Array, a Range, a Complex, a Struct, nil) as the stored key and as the lookup key, every pair. Each prints twenty lines: `[]`, `key?`, `fetch`, `include?`, `dig`, `values_at`, `eql?`, the two `hash` values compared, `tally`, `uniq`, `&`, `|`, `-`, a `Hash.new(0)` counter, a store over the key, `delete`, Hash `==` and `merge`. Each run plain, under `SPINEL_GC_STRESS=1` and under 2.

| of 289 | master | this branch |
|---|---|---|
| right | 272 | 279 |
| a line wrong and silent | 17 | 10 |

By the line: 5,672 right on both, 98 cured, 10 wrong on both with the same text, none lost. The seven cured programs are the five pairs of equal Rationals of Bignums and the two pairs of one of each kind. The ten left are named under **Not here**.

**Cost.** 200,000 lookups each (callgrind), master beside this branch:

| key | gcc | clang |
|---|---|---|
| an Integer | 36,868,131 to 36,668,131 | 34,023,834, the same |
| a word-sized Rational | 54,869,046 to 55,069,046 | 44,824,709, the same |
| a Range | 54,468,710 to 54,668,710 | 52,224,394, the same |
| a Complex | 57,068,756 to 57,268,756 | 46,824,419, the same |
| a Struct | 87,471,361, the same | 89,430,097, the same |
| an object with its own `hash` and `eql?` | 80,472,036, the same | 76,630,035, the same |
| a String | 60,470,144, the same | 58,027,491, the same |
| `tally` of four values, two of them Rationals | 601,570,511 to 602,170,511 | 541,002,128, the same |
| a Rational of Bignums, the cured lookup | 56,892,741 to 79,092,842 | 49,850,421 to 72,650,522 |

The new arm sits after the word-sized Rational's. Before the hook for user objects instead it measures the same with gcc and 1 more for a word-sized Rational with clang. The cured lookup now runs the comparison it skipped.

**Not here.** Ten lines of the family are wrong on master and here, with the same text, and none is a lookup: `x.eql?(y)` answers true for a Bignum beside a Rational of Bignums with denominator 1, in both directions (it does for `1` beside `Rational(1, 1)` too), and `x.hash == y.hash` prints true for eight unequal pairs (a boxed Bignum beside nil, a Rational of Bignums beside its negative, beside a Symbol, beside an Integer). Every lookup line of those programs is right.

**Generated C.** `make cident REF=3d629868`: `6498 identical, 0 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The change is in the runtime; no test's C changes. Whether optcarrot's generated C changes is not known: there is no checkout of it where this was written.

**Test.** `test/big_rational_hash_key.rb`: lookup, `key?`, `fetch`, `include?`, `tally`, store over an equal key, `delete`, a Bignum denominator and a negative value, a Rational of Bignums whose parts fit a word beside the word-sized Rational of the same value in both directions, keys of other classes beside it, and a Set. On master 16 of its 42 lines are wrong, in every build. Here it prints the same plain, under `SPINEL_GC_STRESS=1` and 2, built with clang, and under `--share-strings`. The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written. The test is marked `# spinel: int64`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
