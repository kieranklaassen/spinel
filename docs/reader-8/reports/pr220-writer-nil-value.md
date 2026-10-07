# Second reading: fork pull request 220, "A hand-written writer takes a value that answers nil"

Reader 8, 2026-10-07. Piece: one commit cf69b2ebd8a068eabbca1065f019fa1543034bd7 (tree 72fc9a3b1867c04b9de21a8a7e81eaabc60b3cdb, checked) on
upstream master 8684d54ce75ffe60dba47b754acd2104e502aaa7 (`upstream/master` in /home/claude/spinel still names it). Nothing was pushed, posted or
opened anywhere. CRuby here is 3.3.6 (`ruby --enable-frozen-string-literal`), not 4.0. Everything is under /home/claude/r8/p220/ .

## VERDICT: NOT READY

One finding counts against the piece under rule (b) (finding 1: a build failure becomes a silent wrong answer through the piece's own
emission, and the twin test fails both halves by script). Three more families are master's faults reached, each with a twin that passes by
script, and need one plain paragraph in the body (findings 2 to 4). The body's and the commit message's error line is not the line the
reproducer prints (finding 5). Rule (a) reads 0 everywhere.

## The coordinator's two questions

**(1) Does the piece stand on master alone, or does it need fork pull request 208 beneath it?** It stands on master alone. Its one commit's
parent is 8684d54c; the tree builds, the piece's test passes on it (gcc and clang, stress unset, 1, 2) and fails to build on master. Fork
pull request 208 (2c01d61e, one commit on 06064727) is not in master (`test/boxed_writer_nil_value_runs.rb` is absent, and 2c01d61e is not
an ancestor of anything fetched here) and is not beneath 220. The two touch different functions in different files: 208 changes
`emit_poly_index_call` (src/codegen_call_recv.c) and `emit_call_stmt` (src/codegen_stmt.c), the boxed receiver's two arms; 220 changes
`emit_call_cmethod_arms` (src/codegen_call_class.c), the typed receiver's arm. Read from the fork's public API (the commit's file list);
208's head is not fetched in this container, so the two were NOT merged together here. Inferred, not run: they merge without a conflict
(no common file).

**(2) Does it add to the codegen nil helpers?** No. The 9 added lines (src/codegen_call_class.c 1240 to 1248 on the piece) are all inside
`emit_call_cmethod_arms`, in master's arm "An explicit `def x=(v)` reached as `obj.x = v` in value position". They test `at == TY_NIL`,
where `at = repr_of(c, argv[0]).as_ty` is a line master already has, and call only `buf_puts` and `emit_call_body` (between
`g_setter_value_inner++` and `--`, as master's two neighbouring branches do). None of `nil_recv_guard`, `local_obj_nil_written`,
`nil_value_node`, `method_ret_nilable`, `nil_answers_call`, `obj_nilable` or the value-type nil witness is touched, called by the new
lines, or changed in what it answers; `git diff 8684d54c cf69b2eb -- src` is that one hunk. The function grows from 897 to 906 lines
(under the 1,000 line rule; `ruby tools/gate.rb check` with the commit staged over master: exit 0).
One thing to know beside the "no": what a writer does with the nil it is handed IS decided by master's nil fact, and that fact does not see
a value of nil type that is no literal as a nil reaching the parameter (finding 4). The piece adds nothing there, but its newly built
programs walk into that gap.

## Findings

Words used below. A row is one program, one C compiler (gcc or clang), one SPINEL_GC_STRESS setting (unset, 1, 2): six rows a program.
R right (CRuby's bytes and exit), W silent wrong (exit 0, other bytes), L loud (raise or non-zero exit where CRuby has none, or another
error), C crash (signal or time-out), X not built or refused. "Twin" is the task's: `lit` puts the nil literal where the value stood,
`loc` binds the value to a local first (`t = VALUE; a.v = t`), `typ` puts a typed value there (`(VALUE; 3)`). Twins run on MASTER only.

### Finding 1 (counts against the piece, rule (b)): a writer assignment at the end of a block inside the value answers its writer's body

Smallest program (g_hand2/yield_block_writer.rb):

```ruby
class K
  def v=(x)
    @v = x
    42
  end
end
def yb
  p yield
  nil
end
a = K.new
b = K.new
a.v = yb { b.v = 6 }
```

- CRuby 3.3.6: `6`
- master 8684d54c: does not build. gcc: `error: variable or field 'lv___sv3' declared void`; clang: `error: variable has incomplete type 'void'`.
- piece cf69b2eb: builds, exit 0, prints `42` with gcc and with clang at stress unset, 1 and 2 (six rows of six).

So a build failure becomes a silent wrong answer. The twin test, by script (twcmp.rb over hand2.jsonl and tw_hand.jsonl):

- half 1 FAILS. `t = yb { b.v = 6 }; a.v = t` prints `6` on master (six rows), and `yb { b.v = 6 }; a.v = nil` prints `6` on master
  (six rows). Master never prints `42` for either twin.
- half 2 FAILS. The line is computed by C the piece changes. Master writes the inner assignment (in the twin, and in the piece's
  program before the C compiler stops on the void temporary) as
  `({ (void)(sp_K_v_set((sp_K *)lv_b, _t9)); 6LL; });`
  and the piece writes it as the bare call
  `sp_K_v_set((sp_K *)lv_b, _t9);`
  so the block answers what the writer's body answers.

With a value of another type (`def yb; p yield; 1; end`) the C is byte-identical on both trees and master prints `6`: the fault is in the
new arm only. A String one (g_hand2/yield_block_writer_str.rb: `a.v = twice { b.w = "str" }` with `def w=(x); @w = x; "wret"; end`)
prints `"wret"` where CRuby prints `"str"`; its `loc` twin on master prints `"str"`.

Cause, read in the source and checked by the C above: master's typed branch emits the value BEFORE `g_setter_value_inner++`
(`emit_one_arg(c, saved0, b)` then the counter, then `emit_call_body`). The piece's branch emits the nil-typed value inside
`emit_call_body`, so inside the window where that counter switches the "an assignment's value is its right-hand side" arm off for every
nested writer call. Master has a second way to keep the value for nested assignments in value position (`setter_value_open` in
src/codegen_call_recv.c), which is why 39 of the 43 positions I tried inside the value stay right; a writer assignment that is the last
STATEMENT of a block handed to a user method that yields is emitted as a statement and has only the switched-off arm.

How wide (generator gen2.rb family f1, 256 programs: 4 yielding methods, 4 inner writer bodies, 4 inner values, 4 outer contexts, 3 outer
positions; gen3.rb family f4, 323 programs: 43 positions of a typed writer assignment inside the value):

| set | programs | X to R | X to W | X to X (stays unbuilt) | twin |
|---|---|---|---|---|---|
| f1, screen (piece, clang, stress unset) | 256 | 72 | 68 | 116 | |
| f1 candidates, full matrix (c_f1.jsonl) | 98 | 0 | 68 (408 rows of 408) | 30 (180 rows) | `loc` twin on master: 68 of 68 differ, master right on all |
| f4, C read for all 323 (barecall.rb): the bare call only at the 4 block-tail positions | 323 | | 30 by the C | | |
| f4, full matrix on those 30 and 60 of the others (c_f4.jsonl) | 90 | 60 (360 rows) | 30 (180 rows of 180) | 0 | `loc` twin on master (twc_f4.jsonl): 30 of 30 differ, master right on all |

The 72 right ones of f1 are those where the inner writer's body ends in the assigned value itself (`@v = x`), so the wrong answer and the
right one are the same bytes. The 116 unbuilt ones are those where the body's C type differs from the value's (for example a body ending
in `true` with an Integer value): the C compiler refuses `sp_RbVal` for `sp_int` and the program stays a build failure, which is allowed.

Repair, by the inverted test (not built by me): take the new arm only where the value holds no block with such an assignment, and leave
every other program on master's C (still a build failure); or emit the value outside the `g_setter_value_inner` window, into the argument
slot, and show by script that the 2,159 programs of my bulk set keep the C they have now.

### Finding 2 (master's fault reached; needs a sentence in the body): `x&.v = f` runs `f` when `x` is nil

Smallest program (g_hand3/safe_nil_recv.rb):

```ruby
class K
  def v=(x)
    @v = x
  end
end
def nilf
  puts "nilf"
  nil
end
def pick(f) = f ? K.new : nil
b = pick(false)
b&.v = nilf
puts "end"
```

- CRuby: `end`
- master: does not build (gcc `'lv___sv3' declared void`, clang `incomplete type 'void'`)
- piece: `nilf` then `end`, six rows of six

Twins on master (tw_hand3.jsonl, six rows each): `b&.v = (nilf; 3)` prints `nilf` then `end` (the same wrong line, where CRuby prints
`end`); `b&.v = nil` prints `end` (right; there is nothing to run); `t = nilf; b&.v = t` prints `nilf` then `end`, which is right for
that program. So the twin that carries the fault is the typed one, not the task's two: master runs any value that is a call before it
looks at a nil receiver. Side find S6 is the same line in a program master builds (`b&.v = bump`, g_hand3/side_safe_nav_typed_value.rb:
CRuby `end`, master and piece `bump` then `end`, C byte-identical). Half 2: the C of the piece's program is master's C for the `lit`
twin with the call in the argument's place (half2.rb), and the receiver test is master's text. In the bulk screen 13 of the 16 wrong programs
are of this kind (receiver form `safen`, a nil receiver behind `&.`); the other 3 are in "Counts".

### Finding 3 (master's fault reached; the piece writes the same `0` master writes): nil becomes 0 in a block that also leaves by `next 7`

Smallest program (g_hand3/next_tail_min.rb):

```ruby
class K
  def v=(x)
    @v = x
  end
end
def nilf = nil
a = K.new
p [1, 2].map { |i| next 7 if i > 1; a.v = nilf }
```

- CRuby: `[nil, 7]`
- master: does not build (gcc `'lv___sv7' declared void`)
- piece: `[0, 7]`, six rows of six

Twins on master: `a.v = nil` in that place prints `[0, 7]` (six rows; the same wrong line); `t = nilf; a.v = t` prints `[nil, 7]`
(right). Half 2 by diff: the piece's C for the program and master's C for the `lit` twin differ in three places only, the declaration
and body of `sp_nilf` and the argument slot (`_gcf.v[0] = (sp_nilf(), sp_box_nil());`); the line that makes the wrong answer,
`_t6 = ({ (void)(...sp_K_v_set(...)...); 0; }); ... sp_IntArray_push_nilable(_t3, _t6);`, is the same text on both. The `0` in it is
written by the piece's new arm for this program and by master's "simple value" branch for the twin. I count it as reached, because the
literal twin passes both halves; I name it because the `loc` twin is right on master, so "the value bound to a local first" would have
been right had master built it that way. The coordinator decides whether one sentence is enough.

The same family, from generator gen2.rb family f2 (286 programs: the assignment where an Integer, Float, String, Symbol, true, Array or
object "or nil" is expected, 41 places): screen 277 right, 4 wrong, 5 still not built. Full matrix on the 9 (c_f2.jsonl, twc_f2.jsonl):

| program | CRuby | master | piece | `lit` twin on master | `loc` twin on master |
|---|---|---|---|---|---|
| loopbreak-int: `r = loop { n += 1; break 7 if n > 5; break(a.v = nilf) if n > 1 }; p r.nil?` | `true` | no build | `false` (24 rows of 24 over the 4 wrong programs) | `false` (same line) | `true` (right) |
| loopbreak-flt, mapnext-int, mapnext-flt | | no build | wrong the same way | same line | right |
| loopbreak-obj, loopbreak-str, mapnext-str, arrstore-arr, arrstore-obj | | no build | no build (`int` to a pointer) | no build, the same C error | right |

So wherever the place is typed by another exit, the piece gives what master gives a nil LITERAL there (0, or a C error for a pointer),
and the 5 that stay unbuilt only change their error line. Rule (a) is untouched (master built none of the 9).

### Finding 4 (master's fault reached; needs a sentence in the body): nil handed to a parameter that another call types as an object raises nothing

Smallest program (g_hand3/obj_param_silent.rb):

```ruby
class N
  def name = "n"
end
class C
  def v=(x)
    @v = x.name
  end
end
def nilf = nil
a = C.new
a.v = N.new
a.v = nilf
puts "unreached"
```

- CRuby: NoMethodError (undefined method `name' for nil), exit 1, nothing on stdout
- master: does not build (gcc `'lv___sv5' declared void`)
- piece: prints `unreached`, exit 0, six rows of six

With `def name = @name` (a slot read instead of a constant) the piece's program dies of SIGSEGV, exit 139, on all six rows
(g_hand/obj_param_call.rb, g_hand/slot_obj_read.rb: the two X to C programs of the hand set).

Twins on master: `t = nilf; a.v = t` prints `unreached`, exit 0 (six rows; the same wrong answer); `a.v = nil` raises NoMethodError
(right). The same holds with no writer at all (`a.set(nilf)`, g_hand3/side_obj_param_plain_method.rb: master and piece print
`unreached`, C byte-identical). Master's nil fact marks a parameter "may be nil" only when a nil LITERAL reaches it; a call or a local of
nil type does not, so no guard is written. The piece writes no part of that; its newly built programs reach it. Rule (b) by the letter
(build failure to silent wrong answer, and to a crash) is met only through the twin, so the body has to say it.

### Finding 5 (text): the quoted error line, and three things the body does not say

1. Body and commit message both quote `# error: variable or field 'lv___sv5' declared void` under the reproducer. The reproducer as
   printed, on master 8684d54c with gcc, says `'lv___sv2'`; with clang the words are `variable has incomplete type 'void'`. A reader who
   pastes the program does not get the quoted line. Fix: quote what the reproducer prints, or say "(the number varies)".
2. The body says the newly built programs "are right" and gives the 480 count; it has no sentence for the families that build now and
   are wrong through master (findings 2, 3 and 4, and the three smaller ones below). Each needs one plain sentence, with its twin.
3. What stays unbuilt is not named: `a.v ||= f` and `a.v &&= f` with a nil-answering `f` (gcc `void value not ignored as it ought to
   be`, the same on both trees; g_hand/orw.rb, g_hand/andw.rb), and `a.v = f` as an operand of `+` (g_hand/as_op_plus.rb).
4. The cident line in the body counts 6,343 programs; here `optcarrot-single.rb` is absent, so I compared 6,342 (see "Counts" below).

### Three smaller reached lines (master's, each with its proof)

- `puts "b" if !(k.v = nilf)` never runs the assignment (g_hand/unless_not.rb: CRuby `nilf a nilf b nilf c nilf true`, piece
  `nilf a b nilf c nilf true`, one `nilf` short). The same statement in a program master builds (g_hand2/not_assign.rb, C byte-identical
  on both trees) prints `b 5` where CRuby prints `nilf b nil`: master's `!` of a nil-typed expression answers true without running it.
- A String kept by a writer is a copy: `o.v = s; s << "c"; p o.v` prints `"ab"` for `"abc"` on the line ABOVE the cured statement
  (g_hand/writer_str_append.rb). `lit` and `loc` twins on master print the same line.
- `def rd = nil` at top level and then `class Object; def rd = 13; end`: `a.v = rd` keeps the first definition (g_hand2/redef_object.rb,
  piece `nil nil`, CRuby `13 13`); the `loc` twin on master prints the same.

## The text, sentence by sentence

Sums, recomputed here over the lines inside each block, every line ended by a newline:

| block | stated sha256 | recomputed | |
|---|---|---|---|
| Title | 8f9b761ae99ff742fa962fef26a515559ff4cf110a8c7879e65cf1721d9bd093 | the same | holds |
| Body | 72da0fd0be89baf58fd5d3ebbd3f25d894c4021953eba3fa616de914f87cad24 | the same | holds |
| Commit message | 5269669580fc7380b6e140dfafea8d7a020b9595e4711a71b7891656a816e338 | the same | holds |

The commit message block is byte for byte `git log -1 --format=%B cf69b2eb`; the title block is the commit's subject and the pull
request's title; the body saved by the builder and the body live on the fork are the same bytes. No number sign followed by a digit in
title, body or commit message (the template's `Depends on: #` has none after it). No upstream pull request is named. No model name and
no session link. One trailer, `Co-Authored-By: Claude Code <noreply@anthropic.com>`. The template's head comment and its four boxes are
the template's bytes. The generator's sum the hand-over states (e09368ad...b7864) holds, and it writes 600 programs.

| sentence | reading |
|---|---|
| Title: "A hand-written writer takes a value that answers nil" | true, short |
| "`obj.x = v` through a hand-written `def x=` did not build when `v` answers nil and is no nil literal" | true (run: master fails with gcc and clang; a nil-typed LOCAL built on master and still does, so "no nil literal" is a little wide: "no nil literal or variable", as the next paragraph says) |
| reproducer's comment `# error: variable or field 'lv___sv5' declared void` | NOT what it prints: `'lv___sv2'` with gcc here, other words with clang (finding 5.1) |
| "The value of the assignment is its right-hand side ... reads it back after the writer." | true, read in master's source |
| "A value of nil type (...) made that temporary a `void` local." | true (the C line is `void lv___svN = ...;`) |
| "it is now handed to the writer as it is, run once" | true for the value itself in every program I ran, except behind `!` where master never runs the assignment at all (smaller reached line 1) |
| "and the assignment answers nil as it does for a nil literal" | true, including where the nil literal's answer is wrong on master (finding 3) |
| "600 programs ... the 480 with such a value did not build on master and are right" | C part true: 480 of the 600 change C and all 480 have the void temporary on master, 120 have master's C (conly_builder.tsv). "are right": see "Counts" below for the sample I ran. It is true of the builder's set and NOT true of the neighbouring programs of findings 1 to 4, which the body does not mention (finding 5.2) |
| "`tools/cident.sh`: 6,342 corpus programs identical; the one that differs is the new test." | here: 6,337 identical and 5 differ of 6,342 compared, 4 of the 5 by the build's revision stamp in RUBY_DESCRIPTION, the fifth the new test; optcarrot-single.rb is absent here (finding 5.4). No corpus program's own C changes. |
| gate block: "not run here: this container cannot run the full gate" | plain, and true here too |
| "tools/gate.rb check: exit 0" | true with the commit staged over master (warning only: no Ruby 4.0 here) |
| Commit message, paragraph 1 and 2 | true as above; "A value of any other type keeps its temporary" true (0 programs with changed C outside the void ones, of 5,262 classified) |
| Commit message's error line | as the body's (finding 5.1) |

## Side finds on master 8684d54c, for the miner (no fix built)

Each of S1 to S9 is a program in g_hand3/ whose C is byte-identical on master and the piece; each was run on both with gcc and clang
at stress unset, 1 and 2 (hand3.jsonl). S10 to S13 come from the hand sets and probes as said.

| | program | CRuby 3.3.6 | master 8684d54c (and the piece) |
|---|---|---|---|
| S1 | `def nilf; puts "nilf"; nil; end; p(!nilf)` (side_not_drops_call.rb) | `nilf` `true` | `true`: `!` of a nil-typed call never runs the call |
| S2 | `p(nilf&.length)` (side_safe_nav_on_nil_call.rb) | `nilf` `nil` | `nil`: the call is dropped |
| S3 | `class K; def self.cv=(x); @cv = x; 5; end; end; p(K.cv = 3)` (side_class_writer_value.rb) | `3` | `5`: a class-level writer's assignment answers the body |
| S4 | `class IX; def []=(k, x); 5; end; end; i = IX.new; p(i[1] = 3)` (side_index_writer_value.rb) | `3` | `5` |
| S5 | `pick(a) { b.v = 6 }.v = 5` with `def pick(o); p yield; o; end` and a writer ending in 42 (side_block_tail_in_receiver.rb) | `6` | `42`: finding 1's fault, on master, when the block sits in the RECEIVER's call |
| S6 | `b&.v = bump` with `b` nil, `bump` typed (side_safe_nav_typed_value.rb) | `end` | `bump` `end`: the value runs for a nil receiver |
| S7 | `get(a).v = bump` (side_typed_value_before_receiver.rb) | `get` `bump` | `bump` `get`: a typed value that is a call runs before the receiver |
| S8 | `a.set(N.new); a.set(nilf)` where `set` calls `x.name` (side_obj_param_plain_method.rb) | NoMethodError | `unreached`, exit 0: a nil-typed call or local handed to an object-typed parameter has no nil guard (with a slot read in `name`: SIGSEGV) |
| S9 | `a.n = N.new("kk"); a.n = nil; p a.n.name` (side_obj_slot_nil_read.rb) | NoMethodError | SIGSEGV, exit 139, six rows of six |
| S10 | `p [1, 2].map { \|i\| next 7 if i > 1; a.v = nil }` (tw_hand3/next_tail_min.lit.rb) | `[nil, 7]` | `[0, 7]`; with plain `nilf` as the block's last expression neither tree builds |
| S11 | `a.v \|\|= nilf`, `a.v &&= nilf` (g_hand/orw.rb, andw.rb) | run | no build on either tree: gcc `void value not ignored as it ought to be` |
| S12 | `def rd = nil; x1 = rd; class Object; def rd = 13; end; t = rd; p t` (probe/s12.rb, run on master with gcc only) | `13` | `nil`: the first definition is kept |
| S13 | a writer reached through `method_missing`: `p(m.zz = nilf)` (g_hand/mmiss.rb) | `nilf` `mm zz=` `nil` | `nilf`, then NoMethodError, exit 1, on both trees (loud, same C) |

## Counts

All numbers in this section are on master 8684d54c against the piece cf69b2eb, unless a line says "tip". "Run whole" means both trees,
gcc and clang, SPINEL_GC_STRESS unset, 1 and 2: six rows a program. "Screen" means the piece only, clang, stress unset, against CRuby: one
row a program, a sieve to pick what to run whole, not a proof. "By C" means only the generated C was compared (`-c` on both trees):
SAME (byte-identical, so the program behaves as on master), VOID (C differs and master's C declares the `void` temporary, so master's
does not build with any C compiler), other (0 everywhere).

### One line per set

| set | programs | by C: changed (VOID) / same / refused by both / other | screened | run whole (rows) | rule (a) | rule (b), made by the piece (twin fails) | wrong or crash through master (twin passes) | unbuilt made right | still unbuilt | unchanged C, run |
|---|---|---|---|---|---|---|---|---|---|---|
| bulk, gen.rb, 9 families (writer x history x value x receiver x context) | 3,271 | 2,159 / 1,101 / 11 / 0 | 488 of the 2,159: 471 right, 16 wrong, 1 loud | 38 (228): v1 30, c_bulk 4, c_hist 4 | 0 | 0 | 7 wrong, 1 loud (TypeError for NoMethodError) | 30 | 0 | |
| the builder's 600 (its generator, sum holds) | 600 | 480 / 120 / 0 / 0 | 100 of the 480: 100 right | 0 | 0 by C | | | | | |
| hand, hand2, hand3 (181 distinct of 188) | 181 | 150 / 31 / 0 / 0 | | 181 (1,086) | 0 | 2 (12 rows) | 10 wrong (60 rows), 2 crash (12 rows) | 135 (810 rows) | 1 (6 rows) | 31 (186 rows): 12 right, 14 wrong, 1 loud, 1 crash, 3 unbuilt, the same on both trees |
| lie.rb (value forms that might be typed nil and not be nil) | 146 | 17 / 123 / 6 / 0 | | the 17 (102) | 0 | 0 | 1 wrong (the redefined method, 6 rows) | 16 (96 rows) | 0 | |
| f1, gen2.rb (a writer assignment at a block's end inside the value) | 256 | 256 / 0 / 0 / 0 | 256: 72 right, 68 wrong, 116 unbuilt | 98 (588) | 0 | 68 (408 rows) | 0 | 0 of the 98 (72 by the screen) | 30 (180 rows) | |
| f2, gen2.rb (the assignment where a typed value "or nil" is expected) | 286 | 286 / 0 / 0 / 0 | 286: 277 right, 4 wrong, 5 unbuilt | 9 (54) | 0 | 0 | 4 wrong (24 rows) | 0 of the 9 (277 by the screen) | 5 (30 rows) | |
| f3, gen2.rb (nil into a typed parameter or slot) | 216 | 216 / 0 / 0 / 0 | 108 (the statement forms): 100 right, 5 wrong, 3 signal | 4 (24) | 0 | 0 | 1 wrong (6 rows), 3 crash (18 rows) | 0 of the 4 (100 by the screen) | 0 | |
| f4, gen3.rb (a typed writer assignment at 43 places inside the value) | 323 | 323 / 0 / 0 / 0 | C read for all 323: the bare call in 30 | 90 (540) | 0 | 30 (180 rows) | 0 | 60 (360 rows) | 0 | |
| smoke (first trial) | 8 | 4 / 4 / 0 / 0 | | 8 (48) | 0 | 0 | 0 | 4 (24 rows) | 0 | 4 right (24 rows) |
| **all, run whole** | **445** | 410 changed, 35 same | | **445 (2,670)** | **0 rows** | **100 programs (600 rows)** | 23 wrong (138 rows), 5 crash (30 rows), 1 loud (6 rows) | 245 (1,470 rows) | 36 (216 rows) | 35 (210 rows) |
| **all, by C** | **5,262** (and the 24 of hand2, hand3) | 3,880 / 1,364 / 18 / 0 | 1,238 | | | | | | | |
| `--share-strings`, by C (hand, lie, f1 to f4) | 1,391 | 1,241 / 143 / 7 / 0 | | | | | | | | |
| `--share-strings`, run whole (share_set: the programs with Strings and every finding) | 76 | 68 / 8 | | 76 (456) | 0 | 4 of f1 and the 2 of hand2 as without the flag | as without the flag, but writer_str_append is right with the flag | 51 (306 rows) | 0 | 8 wrong on both (48 rows) |
| twins, master only (`lit`, `loc`, `typ`) | 177 | | | 177 (1,062) | | | | | | |
| tip 26d456ec: the smallest programs, both tip trees; their twins on the tip's master | 23 and 10 | | | 23 (138 x 2 trees) and 10 (60) | 0 | finding 1 the same | the same | | | |

Notes to the table.

- Rule (a) is 0 rows in every set run whole, and 0 by C everywhere else: of the 5,262 programs compared by C, the piece changes the C of
  3,880 and every one of those has the `void` temporary in master's C; all 410 changed programs that were run whole failed to build on
  master with gcc and with clang. No program whose C is unchanged can differ.
- Rule (b), made by the piece: 100 programs, all finding 1 (68 of f1, 30 of f4, the 2 of hand2). Their `loc` twins print the right line
  on master: 68 of 68, 30 of 30 and 2 of 2 by script (twcmp.rb).
- Wrong or crash through master, 29 programs run whole, each with a twin that prints the same line on master, by script except where
  said: `x&.v = f` with `x` nil, 7 (finding 2; the `typ` twin); nil as 0 in a typed place, 7 (finding 3; the `lit` twin); nil into a
  typed parameter, 2 wrong, 5 crash (finding 4; the `loc` twin; sym-call-stmt's twin differs only in the heap addresses `Proc#inspect`
  prints, so the script says "differs" and I compared it by eye); 3 histories whose FIRST line is already wrong on master
  (`x.to_i` on an Array, a Symbol or true prints a number where CRuby raises; `loc` twin the same lines); `!(k.v = nilf)`, the String
  copy and the redefined method, 4 (the three smaller lines); 1 loud for loud with another class (`nil + 1` inside the writer: TypeError
  for NoMethodError; `loc` twin the same).
- Screen leftovers not run whole: 9 of the 13 bulk programs with a nil receiver behind `&.` (4 were, all finding 2); 4 of f3's 5 wrong
  are my generator's noise (an object's address in `inspect`, and CRuby 3.3's `{:a=>1}` against the `{a: 1}` that Spinel and CRuby 4.0
  print), not answers.
- Half 2 by script over the changed programs (half2.rb, 3,550 listed): 2,569 are exactly master's C with the temporary's expression in
  the argument's place and `0` as the value; 831 are not (f1's 256 and f4's 323 by design, since a nested assignment is emitted
  otherwise; 252 others, 159 of them a writer assignment nested in the value, the rest a receiver hoisted before the value); 150
  skipped (C identical, or a tree refuses).
- The harness fault the coordinator named (a worker thread dying on a non-ASCII byte in the C compiler's error text, its program left
  without a record): checked. Every result file has as many distinct programs as its directory (hand 164, hand2 12, hand3 12, c_f1 98,
  c_f2 9, c_f3 4, c_f4 90, c_bulk 4, c_hist 4, c_lie 17, share 76, tip 23, and every twin file); no program was lost, so none hides a
  "right on master, not built on the piece" row. My runs had LANG=C.UTF-8 exported, and the records hold gcc's curly quotes. "terminated
  with exception" stands only in three screen logs, at the moments I stopped the screen by pid (a reader thread's closed stream).
  My copy now has the fix all the same (`Encoding.default_external`, `scrub`).

### The piece's test and the tools (8684d54c)

| check | result |
|---|---|
| test/def_writer_nil_value_runs.rb on master | does not build, gcc (`'lv___sv8' declared void`) and clang |
| the same on the piece | equal to `.expected`, gcc and clang, stress unset, 1, 2 (6 rows of 6); `.expected` equals CRuby 3.3.6's output |
| `CIDENT_JOBS=2 make cident REF=8684d54c...` | `cident: 6337 identical, 5 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`; the 5: the new test, and 4 programs that print the build's revision (`unreleased revision 8684d54c` against `cf69b2eb`); 6,342 compared, optcarrot-single.rb absent here |
| `tools/refusals.sh` | `refusals: pass (530 records)` |
| `make reject-test` | `reject-test: pass` |
| `make share-strings-test` | `share-strings-test: pass` |
| `ruby tools/gate.rb check`, the commit staged over master | exit 0 (warning: no Ruby 4.0 here, `.expected` not compared with CRuby 4.0) |
| function length | `emit_call_cmethod_arms` 897 to 906 lines |

### Cost and compile time (8684d54c)

Cost at run time for programs that were right: none to measure. No program that built on master has other C (cident above; 1,364 of
1,364 generated programs with master's C; the 3,880 changed ones did not build), so no callgrind run was made.

Compile time, CPU seconds of the child process, three runs each, machine shared (cost/ in my directory):

| program | master | piece |
|---|---|---|
| int2000.rb: 2,000 `a.v = intf` (typed value), `spinel -c` | 0.65, 0.79, 0.62 (558,854 bytes of C) | 0.77, 0.77, 0.59 (the same bytes) |
| nil2000.rb: 2,000 `a.v = nilf`, half in value position, `spinel -c` | 0.52, 0.50, 0.65 (805,868 bytes; does not build) | 0.52, 0.49, 0.52 (670,257 bytes) |
| nil2000.rb, whole build with gcc | no build | 9.81 |
| lit2000.rb: the `lit` twin (`nilf; a.v = nil`), whole build with gcc | 10.24 | 9.97 |
| int2000.rb, whole build with gcc | | 2.99 |

The same order on both trees; a nil-valued assignment costs the C compiler what master's nil literal costs it.

## On the tip 26d456ec1035

Everything in this section is on upstream master 26d456ec103513fd8d7d9367dbbc9060854f3116 (21 commits past 8684d54c) and on the merge
of cf69b2eb into it; nothing above this heading is.

- Merge: `git merge cf69b2eb` on 26d456ec is clean. Merged tree 63ffdb7b2199bd6ac64c4f9efbf15176d93fffdc, the expected 63ffdb7b2199.
  Built in /home/claude/r8/p220/tip-merge-tree-26d456ec-220 (a path of 48 characters) with `nice -n 5 make -j1`, exit 0. Master's
  compiler is /home/claude/r8/master-26d456ec-tree/bin/spinel, read only.
- The piece's test, test/def_writer_nil_value_runs.rb: on master 26d456ec it does not build (gcc `'lv___sv8' declared void`, clang
  `variable has incomplete type 'void'`); on the merged tree it is equal to `.expected` with gcc and clang at stress unset, 1 and 2
  (6 rows of 6).
- The body's reproducer on master 26d456ec: still `'lv___sv2'`, not the quoted `'lv___sv5'` (finding 5.1 stands).
- Finding 1 on the tip, g_tip/yield_block_writer.rb: CRuby `6`; master 26d456ec does not build (`'lv___sv3' declared void`); merged
  tree `42`, 6 rows of 6. Twins on master 26d456ec: `lit` prints `6`, `loc` prints `6` (6 rows each). The String one prints `"wret"`
  twice for `"str"` twice; its `loc` twin on master 26d456ec prints `"str"`. Finding 1 stands unchanged.
- Findings 2, 3 and 4 on the tip, the same bytes as on 8684d54c: safe_nil_recv `nilf` `end` (twins: `typ` the same line, `lit`
  right); next_tail_min `[0, 7]` (twins: `lit` `[0, 7]`, `loc` `[nil, 7]`); obj_param_silent `unreached`, exit 0 (twins: `loc`
  `unreached`, `lit` NoMethodError); obj_param_call SIGSEGV. The three smaller lines and `a.v ||= nilf`, `a.v &&= nilf` (no build on
  both tip trees) the same. Side finds S1 to S9: the same output on master 26d456ec and the merged tree, C byte-identical. 23 programs
  on both tip trees and 10 twins on the tip's master, 6 rows each (tip.jsonl, tw_tip.jsonl); no finding changes.
- One cident, `make cident REF=26d456ec103513fd8d7d9367dbbc9060854f3116` on the merged tree:
  `cident: 6346 identical, 5 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against 26d456ec1)`. The 5 are the
  new test and the same 4 programs that print the build's revision (`unreleased revision 26d456ec` against the merge commit's
  `f10d1e15`); 6,351 compared, optcarrot-single.rb absent. The first try of this run was killed by the container's restart (its
  reference C was complete and was reused; the log of the killed try is tip-cident-killed-by-restart.log).
- "A boxed builtin's own method at another count raises ArgumentError" (upstream commit 99b1eaa8, merged as 7dbe15e8): it adds
  `emit_walk_arity_raise` (src/codegen_util.c) and `builtin_arity_expected` (src/codegen_call.c) and calls the first from
  `emit_collect_expr`, `emit_predicate_expr` (src/codegen_fold.c) and `iter_ewi_zip_poly_arms` (src/codegen_iter.c): the error path of a
  builtin Enumerable walk over a boxed String, Symbol, Integer or Float. It does not touch the ground this piece stands on:
  src/codegen_call_class.c is unchanged by all 21 commits, and no line the 21 commits add or remove in src/ names a setter, TY_NIL,
  `emit_call_body` or `emit_call_cmethod_arms` (grep over `git diff 8684d54c 26d456ec -- src`: 0). Read, and borne out by the runs
  above.
- Upstream master has moved again, to 5390d3002886 (20 commits past 26d456ec). Nothing was built on it. `git merge-tree --write-tree
  upstream/master-5390 cf69b2eb`: exit 0, no conflict, tree 4e6ec8e0cffe0924738d78f145b2d9fb915313eb; src/codegen_call_class.c is
  unchanged between 26d456ec and 5390d300.

## What was NOT run

- `make gate`, `make test`, `make scale-test`, ruby/spec, optcarrot: not run, on any master. The machine was shared by other readings
  and restarted once; the cident runs compare the corpus without optcarrot-single.rb, which is absent here.
- CRuby 4.0: absent. Every CRuby answer is 3.3.6 with `--enable-frozen-string-literal`.
- The whole matrix on every generated program: not run. Of the 3,880 programs whose C the piece changes, 410 were run whole, 1,238
  were screened (piece, clang, stress unset; the two sets overlap in part) and the rest were compared by C only. In the bulk set the
  second screen list stopped at 109 of 308 when the container restarted and was not resumed. f3: 108 of 216 screened. The builder's
  600: 100 of the 480 screened, none at gcc or under GC stress.
- 9 of the 13 screened bulk programs with a nil receiver behind `&.` were not run whole (the 4 that were are all finding 2).
- The piece merged with fork pull request 208: not tried; 208's head is not fetched here. No common file, by the fork's public API.
- On the tip: only the 23 smallest programs, their 10 twins and the one cident. No generator, no reject-test, refusals.sh or
  share-strings-test there. Nothing at all on 5390d3002886 but the merge-tree line.
- Generational GC modes, `--int-overflow=promote`, `-m32`, macOS, wasm, valgrind or sanitizers: not run. callgrind: not run, there is
  no program to measure (see "Cost").
- No sub-worker was started. No command was refused by a safety check. Nothing was pushed, posted or opened; the fork's public API
  was read for the pull request's text and for 208's file list; the upstream's API was not called.
