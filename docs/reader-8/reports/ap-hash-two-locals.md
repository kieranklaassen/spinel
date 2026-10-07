# Second reading: "A Hash named by two locals takes one variant under both names" (brief AP)

Verdict: **NOT READY**. Rule (a) is not 0: 18 of my programs (100 rows) are right on master 8684d54ce75f
and on the base at all six rows, and silently wrong on the piece (three routes, findings 1 to 3).
The wrong lines are master's own (the twins print them on master), so the piece does not make them, it reaches them
in programs that never reached them; the twin does not excuse rule (a).
Rule (b), "reached, not made", holds for every program I tested when the twin keeps both names and writes the
store as an index store; with the twin the brief names (the same program with ONE name) it holds for 10 of 26
and fails for 16, because master refuses the one-name program too (finding 4). That choice of twin is the coordinator's.
The texts need fixes whatever the ruling (finding 5).

Everything below was run unless a line says "read" or "inferred".

## 0. What was read, and on what

- Piece: commit 057fd457766d (tree 5203fd9383ef), one commit over the cap fix 1f1490a2aae6 (tree 962b0ec149f2,
  "A Hash parameter given two kinds of value is not typed from its body", passed by another reader, not read here),
  on upstream dafa0d047fbd. Diff of the piece: src/analyze_pass.c +137, src/compiler.c +1, src/compiler.h +5,
  test/hash_local_alias_widened.rb +47, its .expected +26.
- BASE = master 8684d54ce75f merged with the cap fix alone: /home/claude/r8/ap/base-tree-ap, HEAD c5fedca7, tree e38bff9d5cb1 (as expected).
- PIECE = master 8684d54ce75f merged with the branch tip: /home/claude/r8/ap/piece-tree-ap, HEAD 26279707, tree 08b045e43403 (as expected).
- Plain master 8684d54ce75f: /home/claude/r8/m (read only), third column where it says "master".
- Tip (section 7 only): master 26d456ec1035 plain (/home/claude/r8/master-26d456ec-tree) and the piece merged into it
  (/home/claude/r8/ap/piece-tip-tree-26d456ec, tree b54a75ff166f as expected).
- CRuby 3.3.6 with `--enable-frozen-string-literal`; LANG=C.UTF-8; gcc and clang; SPINEL_GC_STRESS unset, 1, 2.
  A "row" is program x C compiler x stress level (six rows a program).
- Nothing was pushed, posted or opened. No network was used.

## 1. Findings

### Finding 1 (rule (a)): deleting the current key while walking, on a Hash the piece makes poly-keyed

Smallest program (/home/claude/r8/ap/finds/a1_delete_in_each.rb):

```ruby
h = {a: 1, b: 2}
g = h
m = {1 => 2}
g.merge!(m) if ARGV.size > 5
h.each { |k, _v| h.delete(k) }
p h.to_a
```

| | output | rows |
|---|---|---|
| CRuby 3.3.6 | `[]` | |
| master 8684d54ce75f | `[]` | right at all six |
| base (master + cap fix) | `[]` | right at all six |
| piece | `[[:b, 2]]`, exit 0 | wrong at all six |

The store is never run. With the store run (`g.merge!(m)` with no guard, finds/a1b_delete_in_each_run.rb) it is the same:
base `[]` at six rows, piece `[[:b, 2]]` at six rows. The same with `h.each { |_k, _v| h.shift }`
(finds/a3_shift_in_each.rb, three entries: CRuby, master and base `[]`, piece `[[:c, 7]]` at six rows).

Cause (read): master's each emitter keeps the "the current key was deleted, do not step past the entry that slid in"
step only for Symbol- and Integer-keyed Hashes: src/codegen_iter.c line 6275,
`int key_is_int = (ty_hash_key(rt) == TY_SYMBOL || ty_hash_key(rt) == TY_INT);`, and line 6294 emits a plain `_tN++`
otherwise. The same lines are in the piece's tree. The piece gives `h` the poly-keyed variant, so the walk loses the step.

Reached, not made (both halves by script): the one-name twin (finds/a1_twinA_one_name.rb, `h.merge!(m) if ARGV.size > 5`)
and the two-name twin with an index store (finds/a1_twinB_index_store.rb, `g[1] = 2 if ARGV.size > 5`) print
`[[:b, 2]]` at all six rows on master, on the base and on the piece. The piece's C for the program against the base's C
for either twin differs only in the alias and store statements and the frame struct line (half2.rb); the loop is the same text.
The twin does not excuse rule (a): the program was right on master and is wrong here.

In my HARD family this route is 14 programs, 84 rows: `each`, `each_pair` and `count` with a delete, `each` with a shift,
on Symbol-keyed Hashes with Integer or String values, and on an Integer-keyed one where a block store widens.

### Finding 2 (rule (a)): `Hash[g]` gives back the same Hash

Smallest program (finds/a4_hash_brackets_same_hash.rb):

```ruby
h = {a: 1}
g = h
m = {1 => 1}
g.merge!(m) if ARGV.size > 5
c = Hash[g]
c[:n] = 5
p g.to_a
```

CRuby `[[:a, 1]]`. Master 8684d54ce75f and the base: `[[:a, 1]]` at all six rows. Piece: `[[:a, 1], [:n, 5]]`, exit 0, at all six rows.

Master's `Hash[h]` returns the receiver, not a copy (side find M10: `h = {a: 1}; c = Hash[h]; c[:n] = 5; p h.to_a` prints
`[[:a, 1], [:n, 5]]` on master at six rows). On the base the program was right because `g` and `c` had different variants and the
write converted, which copies. Twins: the two-name index-store twin (finds/a4_twinB_index_store.rb) is wrong the same way on master,
base and piece at six rows; the one-name twin (finds/a4_twinA_one_name.rb) is RIGHT on master, base and piece at six rows, so the
one-name twin does not print the wrong line here. HARD family: 2 programs, 12 rows. In the copy sample (616 run) every other
copy form is right on the piece (`dup`, `clone`, `merge`, `to_h`, `select`, `reject`, `slice`, `except`, `map`, `sort` and more: 588
programs), and all 28 `Hash[...]` copies are wrong on the piece at six rows; those 28 are not rule (a): 17 are wrong on the base too
(with other wrong lines) and 11 are refused on the base (finding 4).

### Finding 3 (rule (a)): `h.invert.invert == h` is false under stress 2

Smallest program (finds/a5_invert_twice_stress2.rb):

```ruby
h = {"a" => "x", "b" => "yy"}
g = h
m = {1 => "x"}
g.merge!(m) if ARGV.size > 5
p h.invert.invert == h
```

CRuby `true`. Master 8684d54ce75f and the base: `true` at all six rows. Piece: `true` plain and under stress 1, `false` (exit 0) under
SPINEL_GC_STRESS=2 with gcc and with clang. Both twins (finds/a5_twinA_one_name.rb, finds/a5_twinB_index_store.rb) print `false` under
stress 2 on master and on the base: master's fault (side find M11), reached. HARD family: 2 programs, 4 rows.

Half 2 for findings 2 and 3 (half2.rb): the piece's C against the base's C for the index-store twin differs only in the literal `m`,
the store statement, the frame struct line and, for a5, one renumbered name (`_k12` against `_k7`); the `Hash[]` and `invert` code is the same text.

### Finding 4 (rule (b)): refused on the base, silently wrong or aborting on the piece; which twin?

Programs the base refuses and the piece builds are 7,901 of my 43,488 (section 2); 2,987 of them were run at six rows.
2,856 are right at all six rows. 125 are silently wrong at some row (642 rows; 77 raise, 36 hard, 11 copy, 1 use) and 6 are loud at some
row (12 rows: 4 hard programs abort under stress 2, 2 use programs, see the notes in section 2). The smallest of each kind:

Smallest, a silent wrong answer where CRuby does not raise (finds/b1_refused_to_wrong_delete_in_each.rb):

```ruby
h = {1 => 1, 2 => 2}
g = h
m = {"k" => 1}
g.merge!(m) if ARGV.size > 5
h.each { |k, _v| h.delete(k) }
p h.to_a
```

CRuby `[]`. Base: REFUSED ("line 2: a local variable write given a Hash, which no conversion keeps in its sp_StrIntHash * slot").
Piece: `[[2, 2]]`, exit 0.

Smallest, prints on where CRuby raises (finds/b2_refused_to_wrong_plus_assign.rb):

```ruby
h = {a: 1, b: 2}
g = h
m = {"k" => "s"}
g.merge!(m)
t = 0
h.each { |_k, v| t += v }
p t
```

CRuby: TypeError (String can't be coerced into Integer), exit 1. Base: REFUSED. Piece: `3`, exit 0.

Smallest, refused to abort (finds/b3_refused_to_abort_sort_by.rb):

```ruby
h = {1 => 1, 2 => 2, 3 => 7}
g = h
m = {"k" => 1}
g.merge!(m) if ARGV.size > 5
p h.sort_by { |k, _v| k.to_s }
```

CRuby `[[1, 1], [2, 2], [3, 7]]`. Base: REFUSED. Piece: right plain and under stress 1; under stress 2, exit 134,
"*** SPINEL_GC_VERIFY: the mark reached a freed heap string", gcc and clang.

The twin test, by script (twinb.rb, half2.rb), for these three and for 26 representatives of the 77 raise-family programs
that are refused on the base and not right on the piece (two for each kind of store x use x rescued or not):

| twin on the BASE | of 26 | the three above |
|---|---|---|
| A: ONE name (alias line dropped, the store through `h`): REFUSED | 16 | all three (and refused on the piece too) |
| A: ONE name: the piece's six rows byte for byte | 10 | none |
| B: both names kept, the store written as an index store (`g["k"] = 1`): the piece's six rows byte for byte | 17 | all three |
| B: REFUSED (my index-store form does not build for 9 String-keyed shapes; A holds for those 9) | 9 | none |

So every one of the 29 has a twin on the base that prints the piece's six rows byte for byte (half 1), and for twin B the piece's C
against the base's C for the twin differs only in the changed statement, the frame struct line and renumbered rescue names (half 2;
out/raise.twinb.jsonl; for b1, b2, b3 by half2.rb: the literal `m`, the store statement and the frame struct line). But the twin the brief names, the same program with ONE name, is REFUSED on master for the Symbol- and
Integer-keyed kinds: `h = {a: 1, b: 2}; m = {"k" => 1}; h.merge!(m)` is refused on master, on the base and on the piece, while the
two-name program builds on the piece. For 16 of the 26 and for all three smallest programs the one-name twin does not print the wrong line.
Read strictly, half 1 fails there; read as "the same line of master's text is reached by another program master builds", it holds for all.

Kinds met (all refused on the base; the wrong line is master's text in each, see the side finds):
1. a walk that deletes the current key leaves an entry (`each`, `each_key`, `each_pair`, `each_value`, `map`, `select`, `count`
   with a delete, `each` with a shift): silent, at all six rows, and CRuby does not raise (M1);
2. `t += v` over values of two kinds prints `3`, `"121"`, `"12s"`, `"xyy5"` where CRuby raises TypeError (M2);
3. an Integer method on a String value prints on: `v.even?` gives `true` where CRuby raises NoMethodError (M7);
4. under stress 2 only, a garbage Symbol in the output, exit 0: `g.transform_keys(&:succ).to_a`, `g.keys.map(&:succ)`,
   `g.values.map(&:upcase)`, `g.each { |_k, v| p v.upcase }` (M3);
5. `Hash[g]` is the same Hash (M10); `h.invert.invert == h` false under stress 2 (M11); a key added during `each` raises
   after the key is in (`p h.size` prints 4, CRuby 3) (M13);
6. abort under stress 2 in `sort_by { |k, _v| k.to_s }` and `sort_by { |_k, v| v.to_s }` (M4).

The body names kinds 2, 3 and 6 only.

### Finding 5 (texts): see section 5 for the sentence by sentence reading. In short

1. Body, "None that is right on master is wrong, refused or not building here": false (findings 1 to 3).
2. Body, "23 print on where CRuby raises ... 12 ... abort": the kinds are incomplete. Kinds 1, 4 and 5 above are silent wrong
   answers where CRuby does not raise at all, and are not "prints on where CRuby raises".
3. Body, the `spinel diff` block is a trimmed report, not the tool's output (the tool prints three more lines and `@@ -1 +1 @@`).
4. Body, "`h["c"]` ... 289 instructions against 157, a store 321 against 174 (callgrind)": I measure 189 against 64 and 225 against 87
   with my loop. The differences agree (+125 and +138 against the builder's +132 and +147); the pairs do not reproduce as stated.
   Say what loop the numbers are per, or give the difference.
5. If the piece is classed "a fix with a stated cost", the cost is not first: it comes after three paragraphs, in the first
   bullet under "What was chosen".
6. "Depends on" is an empty number sign; the cap fix under it should be named in plain words there. The measured paragraph says
   only "with the fix for a Hash parameter given two kinds of value under it".
7. The body is 608 words; the measured paragraph is one dense block of numbers from dafa0d04, none of which can be checked by
   a reader on current master.
8. Cost not stated: a parameter shared with another caller. When one caller's Hash becomes poly-keyed the method's parameter
   does, and every caller pays the boxed read and store (read in the C; not measured).
9. The commit's author field is the tool's no-reply identity, not a person's name; the trailer is the co-author line the fork uses.
   No number sign followed by digits and no model name in title, body or message.

## 2. Counts

My generators (all under /home/claude/r8/ap): gen_core.rb (alias forms and chains, widening events, identity, scopes),
gen_use.rb (one use of the Hash, a key or a value, meant to be right on the base), gen_raise.rb (uses that raise or go wrong
on a value of another kind, rescued and not), gen_hold.rb (the Hash also held by an ivar, an Array, a Struct, a method),
gen_copy.rb (copies that must not share), gen_same.rb ("not changed, still converting" shapes), gen_hard.rb (mutation while
walking, growth, copies, sorts), gen_scale.rb (compile time), gen_empty.rb (the other reader's `h = {}; g = h` shape).

Stage 1, every program, the C of the base against the C of the piece:

| family | programs | same C | of them refused on both | C changed | base refuses, piece builds | both build |
|---|---|---|---|---|---|---|
| core | 5,504 | 4,306 | 167 | 1,198 | 575 | 623 |
| use | 14,952 | 2,861 | 104 | 12,091 | 3,422 | 8,669 |
| raise | 10,640 | 5,404 | 30 | 5,236 | 2,028 | 3,208 |
| hold | 4,860 | 1,820 | 64 | 3,040 | 312 | 2,728 |
| copy | 3,872 | 176 | 0 | 3,696 | 1,208 | 2,488 |
| same | 2,496 | 2,449 | 272 | 47 | 20 | 27 |
| hard | 1,164 | 24 | 24 | 1,140 | 336 | 804 |
| total | 43,488 | 17,040 | 661 | 26,448 | 7,901 | 18,547 |

No program is built by the base and refused by the piece (0 of 43,488). Rounds of the fixpoint, piece minus base: at most +2
in every family; no program at the round cap on the piece.

Stage 2, run at six rows (the piece first; the base only where the piece is not right or the family is small):

| family | C changed | run | right on the piece at six rows | rule (a): right on base, not on piece | refused on base, silently wrong on piece | refused on base, loud on piece | not right on base and on piece | not run |
|---|---|---|---|---|---|---|---|---|
| core | 1,198 | 1,198 (all) | 1,198 | 0 | 0 | 0 | 0 | 0 |
| hold | 3,040 | 1,520 (every 2nd) | 1,520 | 0 | 0 | 0 | 0 | 1,520 |
| use | 12,091 | 3,456 (one per kind x widening x use where both build, a third of those groups where the base refuses) | 3,425 | 0 | 1 (6 rows) | 2 (4 rows) | 28 | 8,635 |
| raise | 5,236 | 1,089 (base-refused programs only) | 1,012 | 0 | 77 (366 rows) | 0 | 0 | 4,147 |
| hard | 1,140 | 1,140 (all) | 999 | **18 (100 rows)** | 36 (204 rows) | 4 (8 rows) | 83 | 0 |
| copy | 3,696 | 616 (every 6th) | 588 | 0 | 11 (66 rows) | 0 | 17 | 3,080 |
| same | 47 | 0 | | | | | | 47 |
| total | 26,448 | 9,019 | 8,742 | **18 (100 rows)** | 125 (642 rows) | 6 (12 rows) | 128 | 17,429 |

By programs, over the 9,019 run: rule (a) 18; rule (b) refused to silently wrong 125, refused to loud 6; right on the piece 8,742
(2,856 of them refused on the base, 5,886 built by the base); not right on either tree 128.
By rows, over the 54,114 run: right on the piece 52,782; rule (a) 100; refused to silently wrong 642; refused to loud 12;
not right on either tree 578. Unchanged: 17,040 programs get the same C (661 of them refused on both).
Programs whose C changes: 26,448 of 43,488.

Notes on the table.
- Rule (a), the 18 hard programs: 14 are finding 1 (84 rows), 2 are finding 2 (12 rows), 2 are finding 3 (4 rows). Each was run alone on
  master 8684d54ce75f, on the base and on the piece (out/hard.single2.jsonl): right on master and base, wrong on the piece.
- "Not right on base and on piece" are master's faults met on both trees: the walk with a delete on String keys or by `each_key`,
  `each_value`, `map`, `select` (M1), `Hash[h]` (M10; the 17 copy programs print other wrong lines on the piece than on the base),
  a key added during `each` (M13), `1.chr` shown as `"\u0001"` (M14), a Symbol method result as a garbage Symbol under stress 2 (M3, M15),
  `sort_by` with a block that builds an Array or a String (M4, M16), dynamic Symbols under stress 2 (M12), `invert` twice (M11).
- The 2 use programs "refused, loud": one (`p g.to_a.transpose`) aborted under stress 2 inside a batch and is right at six rows alone;
  the other is `g.sort_by { |k, v| [v, k] }`, exit 1 under stress 1 ("comparison of Array with Array failed"), as on master (M16).
  Five use members were not reached by any batch (behind an abort); run alone, all five are right on the piece at six rows.
- A batch packs 30 to 60 programs as methods of one program; an abort under stress 2 in a batch hides the members after it for that row.
  Every member a batch did not reach or did not get right was packed again in small batches on both trees or run alone.

"Wrong to right" could be counted only where the base was run. In the piece-first runs a program right on the piece at six rows
was not run on the base, so "right on both" and "wrong on the base, right on the piece" are not separated there.
By hand (probes/z, 28 edge programs, gcc and stress unset only): 13 are wrong or refused on the base and right on the piece, none the other way.

The harness fault the coordinator reported (a non-ASCII byte in a C compiler error kills a worker thread and the program gets
no record): my copy converts every captured output before it is searched, so it does not raise there; I added the default
encoding line all the same. Checked: every stage 1 file has as many records as its directory has programs (core 5,504,
use 14,952, raise 10,640, hold 4,860, copy 3,872, same 2,496, hard 1,164, scale 94), no record anywhere says the generated C
did not build, and the logs hold one "terminated with exception": a JSON error on a stress 2 garbage Symbol in a RUN (not a
build) of the first singles run over the 696 raise programs whose one-name twin is refused; that run ended at 32 records and
was replaced by the batch run of the same list (out/raise.prio.batch.jsonl, 960 members). The lost program was built and run by
the piece; it is one of the kind 4 programs above. Two runs were stopped by me and are short on purpose
(out/raise.alone.jsonl 127 of 246, out/hard.single.jsonl 16 of 191; section 8).

## 3. The piece's own test and the tools (master 8684d54ce75f)

- Own test test/hash_local_alias_widened.rb: CRuby 3.3.6 prints its .expected. On master 8684d54ce75f and on the base it is REFUSED
  (line 18, "a local variable write given a Hash, which no conversion keeps in its sp_StrIntHash * slot"), so it fails without the
  piece. On the piece its output equals the .expected at all six rows.
- `ruby tools/gate.rb check` with the piece's diff staged (soft reset to the base commit, then back): exit 0. It says CRuby 4.0 is not
  here, so the .expected was not checked against CRuby 4.0. `infer_write_types` is 461 lines, `infer_hash_aliases` 45 (read).
- `make reject-test`: "reject-test: pass". `make share-strings-test`: "share-strings-test: pass". `tools/refusals.sh`: "refusals: pass (530 records)".
- `CIDENT_JOBS=1 make cident REF=c5fedca7ab344fc17db0e4ec106c2dff47d3bf5c` (the base commit) in the piece tree:
  "cident: 6337 identical, 4 differ, 1 refusal changes, 0 refused by both, 0 not in the reference (against c5fedca7a)".
  The 4 that differ (test/frozen_chilled_builtin_strings.rb, test/object_scoped_ruby_constants.rb, test/ruby_description_shape.rb,
  test/symbol_id2name_ruby_desc_minmax.rb) differ in 8 lines, each one the compiler's own revision inside RUBY_DESCRIPTION
  ("unreleased revision c5fedca7" against "26279707", the two merge commits; the tool's pattern for that string does not match this form).
  The refusal change is "NO LONGER REFUSED: test/hash_local_alias_widened.rb", the piece's own test. So no program of the corpus
  gets other C from the piece.
- `make gate`: not run (section 8).

## 4. Cost, rounds, compile time

- Callgrind, my loops (cg/): a read `h["c"]` on a String-keyed Hash under two names with a value of another kind is 189 instructions
  an iteration on the piece (poly-keyed) against 64 for one name on the base (String keys, boxed values); the two-name program on the
  base (still typed, and losing the entry) is 92. A store is 225 against 87 (two names on the base: 104). The builder's 289 against 157
  and 321 against 174 are not reproduced; the differences are close (+125 and +138 here, +132 and +147 there).
- Rounds: piece minus base is -2 to +2 over the 43,488 programs (hold 0: 1,964, +1: 2,202, +2: 694; copy +2: 2,500; use +1: 10,861).
  "A changed program takes at most two rounds more": true here. "None reaches the round cap": true here (0).
- Compile time at scale (gen_scale.rb, up to 1,600 names in one chain, 1,600 pairs, 1,600 methods): one round more (3 to 4);
  CPU of `-c`: chain_end_1600 0.28 s to 0.36 s, pairs_1600 1.69 to 1.84, meths_1600 1.02 to 1.14, pairs_targets_1600 4.59 to 5.70.
  The same order; no blow-up.
- "Not changed, still converting" (gen_same.rb, 2,496 programs): 2,449 get byte-identical C. The other 47 are two shapes I specified
  wrongly (a poly-key store that master already widens through, and an alias inside a lambda), both fair triggers; not run.
- No program of the core family where the base gave both names one variant gets another on the piece (623 checked, sametype.rb).

## 5. The texts, sentence by sentence

Title: "A Hash named by two locals takes one variant under both names". True where each local is written once with a literal,
`Hash.new` or another such local (the body says so); elsewhere nothing changes. Fine.

Body. "Reproduces on 8684d54ce75f" means I ran it there.

| | sentence | reading |
|---|---|---|
| B1 | the five-line program and its `spinel diff` report | Reproduces on 8684d54ce75f: master and base say `output-diff`, `-[[:a, 1], [1, :a]]`, `+[[:a, 1]]`; the piece says `same`. The block is trimmed: the tool also prints `program:`, `ruby: exit 0`, `spinel: exit 0`, a blank line and `@@ -1 +1 @@`. Text fix: paste the tool's output. |
| B2 | "The argument widened `g` ... never reached `h`." | True (read in the base's C: `g = h` is a conversion call; run: the entry is missing). Reproduces. |
| B3 | "The same entries were lost the other way round ..., with `update`, `replace` and a store in a block." | True, each run on the base and on the piece. Reproduces. |
| B4 | "Where the two variants have no conversion between them (`m = {"k" => 2}`) the write was refused." | True: refused on master and base, right on the piece. Reproduces. |
| B5 | "The alias loop in `infer_write_types` already gives an Array under two names the boxed kind on both." | True (read, src/analyze_pass.c near line 4359). |
| B6 | "A Hash now takes the poly-keyed variant on both and keeps it: the literal is marked for it and the slots are pinned, as `widen_arg_hash` does for a caller's local." | True (read: `want_poly_hash` on the write's value, `TY_POLY_POLY_HASH` and `poly_hash_pin`). |
| B7 | "It does so where each local is written once, with a literal, `Hash.new` or another such local." | True (read; and 12 hand programs with a second write in a block, a lambda, a proc, a `while`, by `\|\|=`, a multiple assignment, a `for`, a pattern or a rescue get the same C on base and piece). A single write under a modifier `if` counts as written once and is joined (probes z03, z04; right). |
| B8 | "Two String-keyed names given a value of another kind take the poly-keyed variant too, not the String-keyed one with boxed values." | True: the piece's C is poly-keyed where the one-name program on the base is String-keyed with boxed values (510 raise programs). |
| B9 | "Nothing pins that variant across rounds; derived again each round it came after the round's writes were typed, and a copy kept in a local (`c = h.dup`) was refused." | An account of a version that is not in the diff. Not checkable from the piece. |
| B10 | "The cost: `h["c"]` on such a Hash is 289 instructions against 157, a store 321 against 174 (callgrind)." | Not reproduced as stated: 189 against 64 and 225 against 87 here; the differences agree. Text fix. |
| B11 | "Two names are joined on kinds each had last round too." | True (read: `hash_alias_seen`, `hash_local_settled`). |
| B12 | "A second name is typed from the first before the first's own stores widen it, so it runs a round behind and often reaches the same kind by itself; joined a round early, a kind that is kept would be the wrong one." | A reason, consistent with the code and with the rounds measured; not tested by removing it. |
| B13 | "A changed program takes at most two rounds more." | True over 43,488 programs here. |
| B14 | "Not changed, and still converting: a local written twice, a conditional (`g = c ? h : k`), a parameter, and a Hash that came from a call, an instance variable, a global, a constant or an element." | True: byte-identical C for 2,449 of 2,496; the other 47 are my own two wrong shapes. These programs still lose entries (probes z06, z07, z15). |
| B15 | "Measured on master dafa0d04 with the fix ... under it, against CRuby 3.3.6, plain and under `SPINEL_GC_STRESS=1` and `2`: of 47,871 generated programs ... 29,234 get the same C and 3,071 are refused on both sides." | The builder's programs are not mine; not reproducible. On 8684d54ce75f with mine: 43,488 programs, 17,040 the same C, 661 refused on both. |
| B16 | "Of the other 15,566, 15,531 are right in all three runs; master refuses 4,704 of the 15,566." | Not reproducible. Mine: of the changed programs run, see section 2. |
| B17 | "23 print on where CRuby raises (an Integer method or `t += v` on a String value, `sort_by` over mixed values): 14 do on master too, 9 are refused there." | The kinds named are met here too. The kinds are incomplete (finding 4, kinds 1, 4, 5), and "9 are refused there" is far below what a wider generator finds: 125 programs refused on the base and silently wrong on the piece here (642 rows). |
| B18 | "12 are right plain and under stress 1 and abort under stress 2 ..., 11 of them in `h.sort_by { \|k, _v\| k.to_s }`, which aborts so on master for `h = {1 => 1, 2 => 2, 3 => 7}` alone" | The last clause reproduces on 8684d54ce75f (both C compilers). The abort class is met here (b3). |
| B19 | "on master 3 of the 12 abort the same way, 6 are wrong and 3 are refused." | Not reproducible. |
| B20 | "None that is right on master is wrong, refused or not building here," | **False** on 8684d54ce75f and on 26d456ec1035: findings 1 to 3. |
| B21 | "and none reaches the round cap." | True here. |
| B22 | the gate block: "not run yet" | Still to be run by whoever opens it. |
| B23 | checkboxes: `.expected` against CRuby 4.0 unchecked; int64 "(none)"; optcarrot; "Depends on" with an empty number sign | The `.expected` equals CRuby 3.3.6 here; CRuby 4.0 is not on this machine. "Depends on" must name the cap fix in plain words. |

Commit message (30 lines, 295 words; the same text as the hand-off).

| | sentence | reading |
|---|---|---|
| C1 | "`h = {a: 1}; g = h; m = {1 => :a}; g.merge!(m); p h.to_a` printed [[:a, 1]] with nothing said." | True, reproduces on 8684d54ce75f. |
| C2 | "The argument widened `g` ... never reached `h`." | True. |
| C3 | "The same entries were lost the other way round ..., and where the two variants have no conversion between them ... the write was refused." | True. |
| C4 | "The alias loop in infer_write_types already gives an Array under two names the boxed kind on both." | True (read). |
| C5 | "A Hash now takes the poly-keyed variant on both and keeps it ..., so every write of the round sees the kind the Hash is built in and a copy kept in a local (`c = h.dup`) is typed from it." | True (`c = h.dup` after the lost-entry program: wrong on the base, right on the piece at six rows; copy sample: all 56 `dup` and `dup.dup` programs run are right). |
| C6 | "It does so where each local is written once, with a literal, `Hash.new` or another such local." | True. |
| C7 | "A second name is typed from the first ... Two names are joined on kinds each had last round too (LocalVar.hash_alias_seen), and a link that waits on that asks for one more round." | True (read; rounds +1 or +2). |
| C8 | "A local written twice, a conditional ..., a parameter and a Hash that came from a call, an instance variable or an element are left as they were, and still convert." | True. |

The message says nothing false. It does not say what the piece costs or what it newly reaches; that is the body's part.

## 6. The other reader's side-find program

`h = {}; g = h`, pairs stored through `h` and read through `g` ("master gives 0 pairs"): five hand forms (index stores of one kind,
of two kinds, in a loop, in a block, through a method) are right on master 8684d54ce75f, on the base and on the piece, with the
same C. I did not reproduce "0 pairs".

gen_empty.rb, 450 programs (an empty literal or `Hash.new`, the alias before, between or after the stores, stores of one kind or
two by index, `merge!`, `update`, `replace`, a block, a method, a loop), on master 8684d54ce75f and on the piece: 447 are right at all
six rows on both; 3 are loud on both in the same way and no other program differs between the two trees. The 3 are a master
fault (M17): after `h = {}; m = {:a => 1}; h.merge!(m); g = h; m = {"b" => "x"}`, a second `h.merge!(m)` (or `update`, `replace`)
exits 1 with "undefined method 'merge!' for an instance of Hash (NoMethodError)" at run time. None prints 0 pairs.

## 7. On master 26d456ec1035 (every number in this section is from that master)

- `git merge` of 057fd457766d (the piece with the cap fix under it) into 26d456ec1035: clean, tree b54a75ff166f (as expected).
  Built at /home/claude/r8/ap/piece-tip-tree-26d456ec (a path of 42 characters). The base on this master (the cap fix alone,
  tree 24e182734108) was not built: the comparisons below are plain master 26d456ec1035 against master 26d456ec1035 + cap fix + piece.
- The piece's own test: REFUSED on master 26d456ec1035 (line 18, the same message), equal to its .expected on the tip piece at all six rows.
- My programs (/home/claude/r8/ap/tipset/, 68 programs with their twins; out/tipset.jsonl), master 26d456ec1035 against the tip piece:

| class | programs | rows |
|---|---|---|
| rule (a): right on master 26d456ec1035, wrong on the tip piece (a1, a1b, a3, a4 at six rows; a5 under stress 2) | 5 | 26 |
| refused on master 26d456ec1035, silently wrong on the tip piece (b1, b2 and 36 of my raise and hard programs) | 38 | 176 |
| refused on master 26d456ec1035, abort under stress 2 on the tip piece (b3 and three hard programs, `sort_by` with `to_s`) | 4 | 8 |
| refused on master 26d456ec1035, right on the tip piece at six rows | 7 | 42 (and 68 rows of the programs above) |
| wrong on master 26d456ec1035, right on the tip piece (the body's five-line program) | 1 | 6 |
| the same C on both (the twins and 3 programs refused on both) | 13 | |

  Every output is the one measured on 8684d54ce75f. The twins on master 26d456ec1035: a1's two twins print `[[:b, 2]]` at six rows;
  a4's index-store twin prints `[[:a, 1], [:n, 5]]` at six rows and its one-name twin is right; a5's two twins print `false` under stress 2;
  the one-name twins of b1, b2 and b3 are REFUSED (on the tip piece too); their index-store twins print `[[2, 2]]`, `3`, and abort
  under stress 2, as the tip piece does for the two-name programs.
- One `make cident REF=26d456ec103513fd8d7d9367dbbc9060854f3116` in the tip tree:
  "cident: 6346 identical, 4 differ, 1 refusal changes, 0 refused by both, 0 not in the reference (against 26d456ec1)".
  The 4 that differ are the same four tests and differ only in the revision inside RUBY_DESCRIPTION (8 lines, "26d456ec" against the
  merge commit "b669dd80"). The refusal change is "NO LONGER REFUSED: test/hash_local_alias_widened.rb". The reference is plain master,
  so this covers the cap fix and the piece together: on master 26d456ec1035 neither changes the C of any corpus program.

Master 5390d3002886 (nothing built on it): `git merge-tree --write-tree upstream/master-5390 057fd457766d` exits 0 with tree
1044b73dfaac; the piece with the cap fix under it still merges clean.

## 8. What was NOT run

- `make gate` in the piece tree: NOT run. The machine was shared (load 11 to 22 throughout) and the container restarted once
  (about 06:02 UTC); the reading's own runs took the time. The body's gate block still says "not run yet".
- Six-row runs are samples for three families: hold every 2nd changed program (1,520 not run), use 3,456 of 12,091 (8,635 not run;
  every kind x widening x use group where both build has one program run), copy every 6th (3,080 not run). The 47 changed programs
  of the same family were not run. Of the raise family only programs the base refuses were run (1,089 of 2,028); its 3,208
  programs that both build and whose C differs were not run at six rows at all, so rule (a) was not tested on raise shapes.
- Piece-first: where the piece was right at six rows the base was not run, so "wrong on base, right on piece" is not counted
  outside the hand probes.
- Two singles runs were stopped by me and are short on purpose: out/raise.alone.jsonl (127 of the 246 raise programs CRuby exits
  non-zero on; the other 119 not run) and out/hard.single.jsonl (16 of 191; replaced by batches on both trees and by
  out/hard.single2.jsonl and out/hard.single3.jsonl, which cover every hard program a batch did not get right).
- After the restart nothing was lost but time: the record counts were compared again with the directories, the cident on the tip and
  the HARD singles were started again and finished.
- Master's C was recorded only for the core and scale families; for the others the third column (plain master) was run only for
  the finds and the 49 hard programs of out/hard.single2.jsonl.
- The twin test by script covers 26 raise representatives and the three smallest programs, not all 131 rule (b) programs.
- The base on master 26d456ec1035 (cap fix alone, tree 24e182734108) was not built; the tip numbers compare plain master with the stack.
- CRuby 4.0 is not on this machine: the .expected was compared with CRuby 3.3.6 only.
- `--share-strings` on my own programs: not run (only `make share-strings-test`).
- Nothing was built on master 5390d3002886.
- The builder's 47,871 programs were not available to me; none of the body's counts from dafa0d04 was re-measured as such.
- No safety check refused a command.

## 9. Side finds on master 8684d54ce75f, for the miner (no fix built)

Each is a one-name program, run on plain master; rows are gcc and clang x stress unset, 1, 2.

| | program | CRuby | master |
|---|---|---|---|
| M1 | `h = {"a" => 1, "b" => 2}; h.each { \|k, _v\| h.delete(k) }; p h.to_a` (side2/m1_each_delete_str.rb) | `[]` | `[["b", 2]]`, six rows. The delete step exists for Symbol and Integer keys only (codegen_iter.c 6275). |
| M1b | `h = {a: 1, b: 2, c: 7}; h.each_key { \|k\| h.delete(k) }; p h.to_a` (side2/m1b) | `[]` | `[[:b, 2]]`, six rows (Symbol keys too). |
| M1c | `h = {a: 1, b: 2, c: 7}; p h.map { \|k, v\| h.delete(k); v }; p h.to_a` (side2/m1c) | `[1, 2, 7]`, `[]` | `[1, 7]`, `[[:b, 2]]`, six rows. |
| M2 | `h = {a: 1, b: 2}; h["k"] = "s"; t = 0; h.each { \|_k, v\| t += v }; p t` (side/m2_plus_assign.rb) | TypeError | `3`, exit 0. With `t = ""` it prints a String (side/m2b). |
| M3 | `p({a: 1, b: 2}.transform_keys(&:succ).to_a)`; also `keys.map(&:succ)` | `[[:b, 1], [:c, 2]]` | a garbage Symbol under stress 2, exit 0. |
| M4 | `h = {1 => 1, 2 => 2, 3 => 7}; p h.sort_by { \|k, _v\| k.to_s }` | the pairs | abort under stress 2, "the mark reached a freed heap string", both compilers. |
| M5 | `h = {a: 1}; m = {"k" => 2}; h.merge!(m); p h.to_a` | two pairs | REFUSED (and on the piece), while the two-name program builds on the piece. |
| M6 | g_core/c04362_r_hn_four_put_1_off_top_again.rb | 34 lines | right at six rows, with "did not converge in 128 rounds" on stderr at compile time. |
| M7 | a boxed String value: `v.even?` (side/m7_even.rb) | NoMethodError | prints `true`. |
| M9 | `h.keys.map(&:to_proc)` on Symbol keys | an Array of Procs | NoMethodError at run time. |
| M10 | `h = {a: 1}; c = Hash[h]; c[:n] = 5; p h.to_a` (side2/m10_hash_brackets.rb) | `[[:a, 1]]` | `[[:a, 1], [:n, 5]]`, six rows: `Hash[h]` is `h`. |
| M11 | `h = {a: 1, b: 2}; p h.invert.invert == h` (side2/m11_invert_twice.rb) | `true` | `false` under stress 2 (both compilers), right otherwise. |
| M12 | `h = {a: 1}; 60.times { \|i\| h["k#{i}".to_sym] = i }; p h.size; p h.keys.last` (side2/m12) | `61`, `:k59` | a garbage Symbol under stress 2, exit 0. |
| M13 | `h = {a: 1, b: 2, c: 7}; begin; h.each { \|_k, v\| h[:n] = v }; rescue => e; p e.class; end; p h.size` (side2/m13) | `RuntimeError`, `3` | `RuntimeError`, `4`, six rows: the key is in before the raise. |
| M14 | `p 1.chr` (side2/m14_chr.rb) | `"\x01"` | `"\u0001"`, six rows. |
| M15 | `h = {a: 1, b: 2}; h.each { \|k, _v\| p(k.upcase) }` (side2/m15) | `:A`, `:B` | a garbage Symbol under stress 2, exit 0 (as M3). |
| M16 | `h = {1 => 1, 2 => 2, 3 => 7}; p h.sort_by { \|k, v\| [v, k] }` (side2/m16) | the pairs | exit 134 under stress 2. On a poly-keyed Hash: exit 1 under stress 1, "comparison of Array with Array failed"; on an Integer-keyed Hash under two names a wrong order `[[3, 7], [1, 1], [2, 2]]` under stress 1 (g_use/u06672). |
| M17 | `h = {}; m = {:a => 1}; h.merge!(m); g = h; m = {"b" => "x"}; h.merge!(m); p g.to_a` (side2/m17) | two pairs | exit 1 at run time, "undefined method 'merge!' for an instance of Hash (NoMethodError)"; the same with `update` and `replace`. |

M1, M10 and M11 are the three faults the piece newly reaches in programs that were right (findings 1 to 3).

Not the piece's, seen while reading: g_core/c04362_r_hn_four_put_1_off_top_again.rb (a chain of four names, a method that stores
into its parameter under a guard never run) is right on master 8684d54ce75f at six rows (with the round-cap warning) and REFUSED
on the base, so by the cap fix ("a typed Hash is passed to `put`'s parameter `x`, which the method stores keys or values of other
types into"), and on the piece. It is the cap fix's row, not this piece's; my hand reduction of it is refused on master too, so I have
no smaller form. Master's C was recorded only for the core and scale families, so I cannot say how many more such programs my
other families hold.

## 10. Where things are

- Report: this file. Generators, harness, logs, tallies: /home/claude/r8/ap/ (gen_*.rb, harness.rb, brun.rb, batch.rb, twinb.rb,
  half2.rb, final.rb, tally.rb, rows.sh, probe3.sh; out/*.jsonl, out/*.list, out/*.log).
- Smallest programs: /home/claude/r8/ap/finds/ (a1, a1b, a3, a4, a5 for rule (a); b1, b2, b3 for rule (b); each with its twins).
- Side finds: /home/claude/r8/ap/side/ and /home/claude/r8/ap/side2/.
- Tip set and its records: /home/claude/r8/ap/tipset/, out/tipset.jsonl.
