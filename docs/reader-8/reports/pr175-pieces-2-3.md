# Second reading: fork pull request 175, pieces 2 and 3, on the tip 26d456ec1035

Reader 8, worker for pieces 2 and 3. Everything of mine is under `/home/claude/r8/p175s/`.
Nothing was pushed, posted or opened; no API call on matz/spinel; no file made in /mnt/project-files.

## 1. Verdicts

- **Piece 2** (e2a9c43b143d, "A computed send beside a class's own send still names its method"): **NOT READY.**
  Finding 1 is a rule (a) case (a program master has right prints a wrong line and exits 0),
  finding 2 is a rule (b) case (a refusal becomes a silent wrong answer, the twin is right on master),
  finding 4 is a carry fault (the cut still carries the old test, which fails one row). Text fixes in section 9.
- **Piece 3** (55bc330960f8, "A boxed receiver that holds an object with its own send calls it"): **NOT READY.**
  Finding 5 is a rule (a) case (a program right on master, on piece 1 and on piece 2 no longer builds, with gcc and clang),
  finding 6 is an unstated cost (compile time and run time), so by the classes it is not a plain fix as written.
  Text fixes in section 9.
- **The ground (piece 1, 9de0751585f2, passed before me)**: three kinds of program that master has right are not right
  on piece 1, and so not on pieces 2 and 3 either (G1: the C does not build; G2: a nil receiver gets the
  program's own send, a silent wrong line or a segfault; G3: an own send that forwards with `super` or
  `method(msg).call` raises). None comes from piece 2 or 3 (same C on p1 and p2; p3's differs for G1 and
  fails the same way). They are in section 4 because both pieces stand on them.

## 2. Trees and hashes (verified by running)

All three are `git merge` commits of the cut commit onto 26d456ec103513fd8d7d9367dbbc9060854f3116, in worktrees:

| tree | merge commit | tree hash | equals the hash named in the task |
|---|---|---|---|
| master | 26d456ec1035 | abc2fe187ac1 | yes (`/home/claude/r8/master-26d456ec-tree`, read only) |
| p1 on tip | 6f3e3e034f62 | 8ee8581bb1336c90fc666bf198df88ccb54547e7 | yes |
| p2 on tip | fc8e315c88e4 | 527c371a167b5625f7dc4364863619473dd255ca | yes |
| p3 on tip | cfb94f4d2796 | 0db4d79e5a31278c184757c7fca42d74a5268280 | yes |

p1 and p2 were built with `make`. p3's compiler objects (51) were compiled in its own tree; its runtime
objects (`build/`, `lib/*.a`, `packages/*.o`) were copied from p1, since `lib/` and `packages/` are the same
files in the three trees (checked with `git diff --stat`).

`git merge-tree --write-tree` on the newer upstream master 5390d3002886 (ref `upstream/master-5390`, 20 commits
later, it changes analyze_desugar.c, analyze.c and codegen_call.c): piece 1 merges clean (tree 0a963546de1e),
piece 2 merges clean (tree 195156ec535b), piece 3 merges clean (tree 477b7a3a1493). Nothing was built there.

The cut commits themselves, on their own base 06064727, were not built: every run here is on the tip merges.

## 3. Findings on pieces 2 and 3

Outputs are from runs with gcc and clang. The finding programs themselves (findings 1, 2, 5 and its second
face, G1, G2) were run with SPINEL_GC_STRESS unset, 1 and 2 and agree on all six rows; their variants and
twins, and findings 3, 3b and G3, were run with stress unset. CRuby is 3.3.6.

### Finding 1 (piece 2, rule (a)): a reader named `send` is not seen as the class's own

`/home/claude/r8/p175s/find/f1_attr_reader.rb`

```ruby
class Mailer
  def send(msg, flags) = "#{msg}:#{flags}"
end
class Job
  attr_reader :send
  def run = "ran"
end
m = [:run, :to_s][ARGV.size]
puts Job.new.send(m)
```

| | result |
|---|---|
| CRuby | `wrong number of arguments (given 1, expected 0) (ArgumentError)`, exit 1 |
| master, p1 (same C d7f8df015f) | the same ArgumentError, exit 1 |
| p2, p3 (same C 7b7237425f) | prints `ran`, exit 0 |

The same with `Job = Struct.new(:send, :at)` (`find/f1_struct_member.rb`: master and p1 raise as CRuby, p2 and
p3 print `ran`) and with `attr_accessor :send` (`find/f1_attr_writer_form.rb`). Cause, read in the source:
`an_send_may_be_own` asks only for scopes named `send` and for `comp_method_in_chain`; a reader made by
`attr_reader` or a Struct member is neither, so the call is lowered as if the receiver had none.
Twin, by script (`find/f1_attr_alone.rb`, the same program without the Mailer class): master itself prints
`ran` where CRuby raises. So master has the fault when the reader is the only `send` in the program (side
find 3) and piece 2 spreads it to the program above, which master has right. The twin does not excuse it:
rule (a) is about the program above.
The harness found the same: `a1_attr_reader_s_own_interp_b`, `a1_attr_reader_s_ary_elem_own_symidx_b`.

### Finding 2 (piece 2, rule (b)): a bare computed send in a top-level def

`/home/claude/r8/p175s/find/f2_top_def.rb`

```ruby
class Own
  def send(msg, flags = 0) = "own:#{msg}:#{flags}"
  def go(m) = helper(m)
end
def ping = "top#ping"
def helper(m) = send(m)
m = [:ping, :to_s][ARGV.size]
puts Own.new.go(m)
```

| | result |
|---|---|
| CRuby | `own:ping:0` |
| master, p1 | refused: `spinel: 2 refusals, nothing written` (unsupported call `send`) |
| p2, p3 (same C adcb95c9c6) | prints `top#ping`, exit 0 |

A top-level def is a private method of Object, so self there is whatever object called it; here it is an Own,
and its own send takes the call. Cause, read in the source: the main-scope arm of `an_send_may_be_own`
(`if (!ss || ss->class_id < 0 ...) return sp_streq(nm, "public_send");`) answers "not own" for every bare
`send` and `__send__` outside a class, and that covers the body of a top-level def.
Variants, all silently wrong on p2 and p3: `self.send(m)` in the def (`find/f2_top_def_self.rb`: master and p1
raise NoMethodError "undefined method 'send' for an instance of Object", exit 1; p2 prints `top#ping`),
`__send__(m)` (`_dsend`), the send inside a block in the def (`_block`), the def reached through
`instance_eval` (`_ie`).
Twin, by script, both halves:
- `find/f2_top_def_twin.rb` (the def in Own renamed `zend`, so the program has no own send): CRuby `top#ping`,
  master, p1, p2, p3 `top#ping`. The lowering is right where no class owns the name. So the wrong line on p2
  is not master's fault reached by a new road: it is the piece applying the lowering where an own send exists.
- `find/f2_top_def_twin2.rb` (`zend`, and Own has its own `ping`): CRuby `Own#ping`; master, p1, p2, p3 print
  `top#ping`. That one is master's own silent wrong (side find 4) and is not counted against the piece.

Beside it, not counted against the piece (`tmp/psend_main.rb`): `class Own; def send(msg, flags = 0)`, a
top-level `def ping`, then `p public_send(m)` at the top level. CRuby raises NoMethodError (private method
'ping' called for main); master and p1 refuse; p2 prints `"top#ping"`. The twin without the Own class prints
`"top#ping"` on master too: master's lowering lets a bare `public_send` call a private top-level def (side
find 7), and piece 2 reaches it. (The sentence in the commit message about a bare `public_send` is about a
program that defines `public_send` itself: the question is asked per name.)

### Finding 3 (piece 2, a note, not a rule count): a bare computed send in a class method

`/home/claude/r8/p175s/find/f6_cmeth_valid.rb`

```ruby
class Own
  def __send__(msg, flags = 0) = "own:#{msg}:#{flags}"
end
class Plain
  def self.ping = "Plain.ping"
  def self.go(m) = __send__(m)
end
m = [:ping, :secret][ARGV.size]
p Plain.go(m)
```

| | result |
|---|---|
| CRuby | `"Plain.ping"` |
| master, p1 (same C) | builds; raises `undefined method '__send__' for an instance of Plain (NoMethodError)`, exit 1 |
| p2 | the C does not build: gcc `passing argument 1 of 'sp_box_str' makes pointer from integer without a cast`, clang `incompatible integer to pointer conversion passing 'int' to parameter of type 'const char *'` |

Loud before, not building after: no rule is broken by this program. With the names swapped
(`find/f6_cmeth_nobuild.rb`, `m = [:secret, :ping][ARGV.size]`) CRuby raises NoMethodError (undefined method
'secret' for class Plain) and master raises NoMethodError too, but for the other reason and with the other
message; the harness counts that as "right on master" by exception class (`a2_d_cmeth_impl_private`), I do not.
Twin by script (`find/f6_cmeth_twin_valid.rb`, the Own class removed): master, p1 and p2 all fail to build the
same way. So this is master's fault (side find 5), which piece 2 now reaches in a program with an own send.
The body's "Every other call is lowered as it is in a program that defines none" holds here to the letter.

### Finding 3b (piece 2, a note, not a rule count): forwarding beside an own send that takes a block

`/home/claude/r8/p175s/find/f8_dots_nobuild.rb`

```ruby
class Own
  def send(msg, *rest, **kw, &b) = "own:#{msg}:#{rest.size}:#{kw.size}:#{b ? b.call(5) : 'nb'}"
end
class Plain
  def one(a = 0, k: 1) = "Plain#one #{a} #{k} #{block_given? ? yield(3) : 'nb'}"
  def uno(a = 0, k: 1) = "Plain#uno #{a} #{k} #{block_given? ? yield(3) : 'nb'}"
end
def relay(...) = $t.send(...)
m = [:one, :uno][ARGV.size]
$t = Plain.new
p relay(m, 1)
```

| | result |
|---|---|
| CRuby | `"Plain#one 1 1 nb"` |
| master, p1 (same C) | builds; raises `undefined method 'send' for an instance of Plain (NoMethodError)`, exit 1 |
| p2 | the C does not build: gcc `incompatible types when assigning to type 'const char *' from type 'sp_RbVal'`, clang `assigning to 'const char *' from incompatible type 'sp_RbVal'` |

Loud before, not building after: no rule is broken. But here the twin by script
(`find/f8_dots_twin.rb`, the def in Own renamed `zend`) builds on master, p1 and p2 and prints CRuby's line.
So unlike finding 3 this is not master's fault reached: the call is not "lowered as it is in a program that
defines none". With `def send(msg, *rest)` in Own (no `**kw`, no `&b`) p2 builds and is right
(`tmp/w1.rb`, `tmp/w4.rb`, `tmp/w5.rb`). In the harness: `a5_dots_plain_s_comp`, `a5_dots_plain_s_lit`,
`a5_dots_lead_plain_p_comp`.

### Finding 4 (piece 2, carry): the cut carries the old `computed_send_object_send` test

The piece 2 commit (and the piece 3 tree) carries `test/computed_send_object_send.rb` as it was before commit
e4d1cdfe. Run by script on each tree, gcc and clang, stress unset, 1, 2:

| test | master, p1 | p2 | p3 |
|---|---|---|---|
| computed_send_beside_own_send (16 lines) | refused | PASS 6 of 6 | PASS 6 of 6 |
| computed_send_object_send, as the cut carries it (12 lines) | refused | PASS 5, **FAIL gcc stress 2** (exit 0, 12 lines, line 1 differs) | the same: PASS 5, FAIL gcc stress 2 |
| computed_send_object_send from e4d1cdfe (12 lines, same .expected) | refused | PASS 6 of 6 | PASS 6 of 6 |
| own_send_boxed_receiver (25 lines) | 2 lines, then exit 1 (FAIL 6 of 6) | as master (FAIL 6 of 6) | PASS 6 of 6 |

The four `.expected` files equal CRuby 3.3.6's output with `--enable-frozen-string-literal`.
The failing row is master's fault, not the piece's: an empty rest parameter collected under stress 2 (side
find 1). But the commit as cut puts a test into the suite that fails one row; the cut must take the test from
e4d1cdfe.

### Finding 5 (piece 3, rule (a)): a Hash answer read through the split call does not build

`/home/claude/r8/p175s/find/f5_p3_nobuild.rb`

```ruby
class Mailer
  def send(msg, flags) = "#{msg}:#{flags}"
end
class A
  def table(k) = { k => "v", 9 => "w" }
end
class B
  def table(k) = { k => "x" }
end
[A.new, B.new].each do |x|
  t = x.send(:table, 1)
  p t[1]
end
```

| | result |
|---|---|
| CRuby | `"v"` `"x"` |
| master, p1, p2 (same C dcca9d8f6c), gcc and clang | `"v"` `"x"` |
| p3 (C 7769b46106) | the C does not build: gcc `incompatible types when initializing type 'const char *' using type 'sp_RbVal'`, clang `initializing 'const char *' with an expression of incompatible type 'sp_RbVal'` |

The box never holds a Mailer. p3's C has `sp_RbVal lv_t` (the split's two arms give a String or a Hash) and
then `{ const char *_t22 = sp_poly_arr_get_hash(lv_t, 1LL); ...`: the read `t[1]` kept the String type it had
when `t` was a Hash of Strings, while `t` itself became boxed.
Twin by script (`find/f5_twin_by_hand.rb`: the split written by hand,
`t = x.is_a?(Mailer) ? x.zend(:table, 1) : x.table(1)` with the method renamed `zend`): master and p3 build it
(same C) and print `"v"` `"x"`. So master can compile the shape the piece makes; the fault is in the piece's
late rewrite (inferred: a type settled before the rewrite is not asked again in the extra rounds).
Width, by hand on p2 and p3 with gcc (`tmp/v_*.rb`): answers of Integer, Float, Symbol, String, an Array read
with `[0]`, a Hash of Integers read with `[1]`, a Hash of Strings read with `.size` all build and are right on
p3; only the Hash of Strings read with `[]` fails.

The same cause has a second face, which breaks no rule (wrong before, loud after) but is a case the title
promises: `/home/claude/r8/p175s/find/f7_p3_typeerror.rb`

```ruby
class Own
  def send(msg, flags) = [msg, flags]
  def val(k) = [k, 1]
end
class Plain
  def val(k) = [k, 2]
end
x = ARGV.size == 0 ? Own.new : Plain.new
r = x.send(:val, 1)
p r.first
```

CRuby `:val`; master and p2 (same C) print `1` (the wrong answer the piece is about); p3 raises
`an Array holding Symbol reached a slot typed as an Integer Array (TypeError)`, exit 1, with gcc and clang.
The split by hand (`find/f7_twin_by_hand.rb`) prints `:val` on master, p2 and p3. So where the own send's
answer and the retargeted method's answer are two different Array or Hash types, the variable keeps the
type of the retargeted answer.

### Finding 6 (piece 3, cost not stated)

The body and the commit message state no cost. Measured (section 8):

- Compile time grows with the number of marked calls in one method: 500 literal sends on a boxed parameter in
  one method, in a program with an own send: 0.09 s on master, 0.10 s on p2, 0.94 s on p3; 2,000: 0.36 s,
  0.37 s, 11.85 s (about 32 times; the C grows from 896 K to 2,323 K). The same programs with no own send:
  0.36 s, 0.39 s, 0.38 s and the same C. That is not the same order of compile cost.
- Run time, callgrind instructions, gcc: every literal send on a boxed receiver, in a program that has an own
  send anywhere, pays the `is_a?` test even where the box never holds the owner: 22,566,871 on master and p2,
  25,266,888 on p3 (+12%) for 600,000 sends on a box of Peer or Integer; 58,563,916 against 67,566,204 (+15%)
  for a box of String or Array.
- The owner's typed callers pay too: with one `[Peer.new, Peer2.new].each { |c| puts c.send(:hello, "world") }`
  in the program (a box that never holds a Conn), `sp_Conn_send` changes from
  `sp_int sp_Conn_send(sp_Conn *self, const char * lv_msg, sp_int lv_flags)` on p2 to
  `sp_RbVal sp_Conn_send(sp_Conn *self, sp_RbVal lv_msg, sp_RbVal lv_flags)` on p3, and 300,000 typed calls
  `conn.send("abc", i)` cost 27,971,735 instructions on p2 and 71,176,586 on p3 (2.5 times).

A program with no own `send`, `__send__` or `public_send` is not touched (same C, see cident, section 7).

## 4. Findings on the ground (piece 1), reached unchanged by pieces 2 and 3

### G1 (rule (a) on piece 1): the C does not build

`/home/claude/r8/p175s/find/g1_ground_nobuild.rb`

```ruby
class Mailer
  def send(msg, flags) = "#{msg}:#{flags}"
end
class A
  def count(k) = k + 2
end
class B
  def count(k) = k + 3
end
[A.new, B.new].each do |x|
  r = x.send(:count, 1)
  p [r].sum, r << 2
end
```

| | result |
|---|---|
| CRuby | `3` `12` `4` `16` |
| master (C a42f0db715), gcc and clang | `3` `12` `4` `16` |
| p1, p2 (same C 7f235b5a8f) | does not build: gcc `passing argument 1 of 'sp_box_nullable_obj' makes pointer from integer without a cast`, clang `incompatible integer to pointer conversion passing 'sp_int'` |
| p3 (C 62f4bfe327) | does not build, the same error |

The failing C has `sp_PolyArray_push(_t47, sp_box_nullable_obj(lv_r, SP_BUILTIN_STRBUF))` where master has
`sp_IntArray_push(_t47, lv_r)`. Each of `[r].sum` and `r << 2` alone builds. Inferred, not proved: while
piece 1 waits on the untyped receiver the call is read as the program's own send, and its String answer
stays on the array literal after the call is retargeted.

### G2 (rule (a) on piece 1): a nil receiver gets the program's own send

`/home/claude/r8/p175s/find/g2_nil_only.rb`

```ruby
class Own
  def send(msg, flags = 0) = "own:#{msg}:#{flags}"
end
def pick(i) = i == 0 ? Own.new : nil
x = pick(ARGV.size + 1)
p x.send(:to_s)
p x.send(:nil?)
```

| | result |
|---|---|
| CRuby | `""` `true` |
| master (C 03ab8962d0), gcc and clang | `""` `true` |
| p1, p2, p3 (same C 57cb5a65b1), gcc and clang | `"own:to_s:0"` `"own:nil?:0"`, exit 0 |

With an instance variable read in the own send (`find/g2_nil_only_ivar.rb`): master `""`; p1, p2, p3 with gcc
die of SIGSEGV, with clang print `"t:to_s:0"`. In the harness the same shape gave a segfault with gcc and an
endless loop with clang (`b1_case_when_own_nil_noparen1_s`, `b1_attr_own_nil_lit0_s`).
Where the slot holds an Own first and nil second (`find/g2_nil_recv.rb`), master has the Own line wrong
(`false` for `"own:==:"`) and the nil line right; piece 1 has the Own line right and the nil line wrong.
I did not read the first reader's report on piece 1; if this was accepted there as the general rule for nil
in an object slot, it should be said in piece 1's text, because for `send` CRuby has an answer on nil and
master gives it.

### G3 (rule (a) on piece 1): an own send that forwards

`/home/claude/r8/p175s/find/g3_super.rb`

```ruby
class Own
  def send(msg, *rest) = super(msg, *rest)
  def ping = "Own#ping"
end
p Own.new.send(:ping)
```

| | result |
|---|---|
| CRuby | `"Own#ping"` |
| master (C 90988b6eb2), gcc and clang | `"Own#ping"` |
| p1, p2, p3 (same C 457c5e631d), gcc and clang | `super: no superclass method 'send' for an instance of Own (NoMethodError)`, exit 1 |

Master is right here because its retarget steps over the own send, and this own send only forwards. Piece 1
lets the own send take the call, and its body is a computed send that nothing answers. Two more of the kind:
- `find/g3_method_call.rb` (`def send(msg, *rest) = method(msg).call(*rest)`): master `"Own#ping"`; p1, p2, p3
  `stack level too deep (SystemStackError)`.
- `find/g3_dsend.rb` (`def send(msg, *rest) = __send__(msg, *rest)`): master `"Own#ping"`; p1 refuses
  (`1 refusal, nothing written`); p2 and p3 print `"Own#ping"` again. So piece 2 mends this one, and piece 1
  alone, without piece 2, refuses a program master has right.
In the harness: `a6_super_args_own_lit_s`, `a6_super_sym_own_lit_s`, `a6_method_call_own_lit_s`,
`a6_dsend_own_lit_p`, `a6_dsend_str_own_lit_s`.

## 5. Counts from my own generators

Programs are mine (`gen_a.rb`, `gen_b.rb`, `gen_bh.rb`, `gen_c.rb`), run by `harness.rb` under CRuby 3.3.6 and
each tree; a row is one program with one C compiler at one stress level (6 rows a program: gcc and clang by
unset, 1, 2). R right, W silent wrong, L loud (raise or other exit), X refused or not building, C crash or
hang. A program whose C is the same on both trees (or that both refuse) is "unchanged" and was not built
(`--skip-same`).

Programs run: `ga` 534 (piece 2: routes to an own send by receivers, name computations, arities,
callee shapes, forwarding, own sends that call super or `__send__`, rescued twins), `gc` 45 (corpus tests
that use send, with a class owning `send(msg, flags)` appended), `gb` 315 (piece 3: ways of boxing by what the
box holds by call forms, own-send shapes, argument and receiver expressions with ticks, blocks and rescue,
result types, forwarding and recursion, rescued twins), `gbh` 158 (the split call in value positions and
under iterators; gcc only).

### Piece 2

**ga, p1 -> p2**

```
programs 534; C the same on p1 and p2: 290; C changed: 244
ROWS (p1 -> p2):
  L->C: 4
  L->L: 164
  L->R: 1002
  L->X: 30
  R->L: 6
  R->R: 30
  R->W: 6
  R->X: 6
  W->L: 6
  W->R: 48
  W->W: 18
  W->X: 6
  X->L: 18
  X->R: 114
  X->W: 6
  unchanged (same C or refused by both): 1740
PROGRAMS:
  C changed, right before and after: 5
  RULE_A (right on base, not right on piece): 3
  RULE_B candidate (loud/refused on base, silent wrong or crash on piece): 2
  changed, class kept or loud-to-loud (L->L): 27
  changed, class kept or loud-to-loud (L->X): 5
  changed, class kept or loud-to-loud (W->L): 1
  changed, class kept or loud-to-loud (W->W): 3
  changed, class kept or loud-to-loud (W->X): 1
  changed, class kept or loud-to-loud (X->L): 3
  made right (all rows right on piece, some not right on base): 194
  unchanged: 290
```
**ga, master -> p2**

```
programs 534; C the same on m and p2: 284; C changed: 250
ROWS (m -> p2):
  C->C: 4
  L->C: 4
  L->L: 178
  L->R: 996
  L->X: 30
  R->C: 4
  R->L: 20
  R->R: 48
  R->W: 6
  R->X: 6
  W->L: 6
  W->R: 48
  W->W: 18
  W->X: 6
  X->L: 18
  X->R: 102
  X->W: 6
  unchanged (same C or refused by both): 1704
PROGRAMS:
  C changed, right before and after: 8
  RULE_A (right on base, not right on piece): 6
  RULE_B candidate (loud/refused on base, silent wrong or crash on piece): 2
  changed, class kept or loud-to-loud (C->C L->L): 1
  changed, class kept or loud-to-loud (L->L): 29
  changed, class kept or loud-to-loud (L->X): 5
  changed, class kept or loud-to-loud (W->L): 1
  changed, class kept or loud-to-loud (W->W): 3
  changed, class kept or loud-to-loud (W->X): 1
  changed, class kept or loud-to-loud (X->L): 3
  made right (all rows right on piece, some not right on base): 191
  unchanged: 284
```
**gc, p1 -> p2** (right and wrong read against the corpus test's own `.expected` plus the appended line)

```
ROWS (p1 -> p2):
  C->R: 2
  L->L: 12
  L->R: 58
  W->R: 6
  X->L: 6
  X->R: 30
  unchanged: 156
PROGRAMS:
  made right: 16
  other (L->L): 2
  other (X->L): 1
  unchanged: 26
other (L->L): ca_dynamic_send_many_literals ca_send_splat_runtime_length_into_builtin_optional_args
other (X->L): ca_send_name_past_literal_cap
```
**gc, master -> p2**

```
ROWS (m -> p2):
  X->C: 2
  X->L: 36
  X->R: 232
PROGRAMS:
  RULE_B candidate: 1
  made right: 38
  other (X->L): 6
other (X->L): ca_dynamic_send_many_literals ca_includer_override_hides_module_method ca_method_runtime_name_arity ca_proc_form_kwrest_forward ca_send_name_past_literal_cap ca_send_splat_runtime_length_into_builtin_optional_args
RULE_B candidate: ca_post_rest_keyword_hash
```
### Piece 3

**gb, p2 -> p3**

```
programs 315; C the same on p2 and p3: 109; C changed: 206; CRuby timed out: 1
ROWS (p2 -> p3):
  R->R: 631
  W->L: 6
  W->R: 575
  W->W: 18
  unchanged (same C or refused by both): 654
PROGRAMS:
  C changed, right before and after: 104
  changed, class kept or loud-to-loud (R->R W->W): 2
  changed, class kept or loud-to-loud (W->L): 1
  changed, class kept or loud-to-loud (W->W): 1
  made right (all rows right on piece, some not right on base): 94
  partly made right: 3
  unchanged: 109
```
**gb, master -> p3**

```
programs 315; C the same on m and p3: 95; C changed: 220; CRuby timed out: 1
ROWS (m -> p3):
  R->R: 631
  W->C: 42
  W->L: 6
  W->R: 617
  W->W: 18
  unchanged (same C or refused by both): 570
PROGRAMS:
  C changed, right before and after: 104
  changed, class kept or loud-to-loud (R->R W->W): 2
  changed, class kept or loud-to-loud (W->C): 7
  changed, class kept or loud-to-loud (W->L): 1
  changed, class kept or loud-to-loud (W->W): 1
  made right (all rows right on piece, some not right on base): 101
  partly made right: 3
  unchanged: 95
```
**gbh, p2 -> p3 (gcc only: 3 rows a program)**

```
programs 158; C the same on p2 and p3: 5; C changed: 153
ROWS (p2 -> p3):
  (row not run: this C compiler was left out): 459
  R->R: 219
  W->R: 234
  X->R: 6
  unchanged (same C or refused by both): 30
PROGRAMS:
  C changed, right before and after: 73
  made right (all rows right on piece, some not right on base): 80
  unchanged: 5
```
**gbh, master -> p3**

```
programs 158; C the same on m and p3: 5; C changed: 153
ROWS (m -> p3):
  (row not run: this C compiler was left out): 459
  R->R: 219
  W->R: 234
  X->R: 6
  unchanged (same C or refused by both): 30
PROGRAMS:
  C changed, right before and after: 73
  made right (all rows right on piece, some not right on base): 80
  unchanged: 5
```

### Reading the tables

Piece 2 (`ga`, 534 programs, p1 -> p2): 290 keep their C; of the 244 that change, 194 are made right
(1,164 rows go from loud, refused or wrong to right) and 5 were right and stay right. The rest (every one
viewed except the L->L group, of which I viewed a sample):
- "RULE_A" 3 programs: two are finding 1 (`a1_attr_reader_s_own_interp_b`,
  `a1_attr_reader_s_ary_elem_own_symidx_b`); the third (`a2_d_cmeth_impl_private`) is finding 3, which the
  script calls right on master because the exception class is the same; I do not count it.
- "RULE_B candidate" 2 programs, not counted: in `a6_method_call_plain_comp_s` the line that overflows the
  stack does so on master too once the line before it is taken out (side find 6, by script); for
  `a7_s_class_local_nil` the twin without an own send prints the same wrong exception class on master (side
  find 8, by script).
- L->X 5 programs (loud before, not building after): two are master's own fault (side find 11), three are
  finding 3b.
- W->X 1 program: finding 3 again. L->L 27, W->W 3, W->L 1, X->L 3: wrong or loud before and after (a nil or
  missing name raises another exception class than CRuby's, the receiver is boxed while the fixpoint runs).
- Finding 2 did not come from the generator (it has no bare send in a top-level def called from an object);
  it came from reading `an_send_may_be_own`.
- The master -> p2 table differs from p1 -> p2 only by the programs where piece 1 itself changes the C (5 of
  534). Three of those are the script's extra "RULE_A" there (`a6_method_call_own_lit_s`,
  `a6_super_args_own_lit_s`, `a6_super_sym_own_lit_s`): right on master, loud on p1, and p2's C is p1's. That
  is the ground's G3 (section 4), not piece 2's.

Piece 2 (`gc`, 45 corpus programs, p1 -> p2): 26 keep their C, 16 are made right, 2 stay loud, 1 goes from
refused to loud. No rule (a) or rule (b) case. The six that are loud on p2 raise
`undefined method 'send' for an instance of Machine (NoMethodError)` and the like: the receiver is a
parameter, which the body names under "Not in this change". The one "RULE_B candidate" in the master table
is side find 9 (the corpus test itself aborts at stress 2 on master).

Piece 3 (`gb`, 315 programs, p2 -> p3): 109 keep their C; of the 206 that change, 94 are made right (575
rows) and 104 were right and stay right (their C changes: this is where finding 6's cost is paid).
**No rule (a) case and no rule (b) case from the generator.** The rest, each viewed: 3 "partly made right"
and 2 "R->R W->W" are master's faults at stress 2 or with gcc (side finds 1 and 2), the same rows wrong
before and after; 1 W->L is finding 5's second face (`b5_ary_oary_first_own_plain_if_flat`); 1 W->W
(`b2_m_two_ckw_own_plain_lit_each`) is right on p3 by Ruby 4.0 (`{k: 5}`; CRuby 3.3.6 prints `{:k=>5}`);
1 program is left out because CRuby itself never ends on it (my generator's fault). In the master -> p3 table
the 7 W->C programs are a nil in the box (G2): p2's C and p3's are the same there.
Finding 5 did not come from the generator's run (its result-type family reads a Hash with `.size`, not `[]`);
it came from a hand program.

Piece 3 (`gbh`, 158 programs, gcc only): 80 made right, 73 right before and after, 5 keep their C. No rule
case. (The "unchanged" row counts 6 rows a program although only 3 were run.)


## 6. Own tests

See the table in finding 4. Run by `owntests.rb`: each test compiled by each tree with gcc and clang and run
with SPINEL_GC_STRESS unset, 1, 2, compared with its `.expected`; the `.expected` files compared with CRuby
3.3.6 run with `--enable-frozen-string-literal`.

## 7. The gate's legs that I ran

| leg | piece 2 (p2 on tip) | piece 3 (p3 on tip) |
|---|---|---|
| `make cident REF=26d456ec…` (CIDENT_JOBS=1) | `6343 identical, 7 differ, 3 refusal changes, 0 refused by both, 0 not in the reference` | `6343 identical, 8 differ, 3 refusal changes, 0 refused by both, 0 not in the reference` |
| `make share-strings-test` | pass | pass |
| `make reject-test` | pass | pass |
| `tools/refusals.sh` | pass (530 records) | pass (530 records) |
| `ruby tools/gate.rb check`, the piece staged over its parent on the tip | exit 0 | exit 0 |

cident, what differs:
- The 3 refusal changes are "no longer refused": test/computed_send_beside_own_send.rb,
  test/computed_send_object_send.rb (piece 2's tests) and test/own_send_literal_argument.rb (piece 1's test;
  the reference is master, so piece 1's change shows in both runs).
- 4 programs differ by the revision stamp alone (RUBY_DESCRIPTION holds the merge commit's short hash):
  frozen_chilled_builtin_strings, object_scoped_ruby_constants, ruby_description_shape,
  symbol_id2name_ruby_desc_minmax.
- 3 programs differ by the path of the tree alone (they embed the path of a required file):
  conditional_require_line, require_expression_lines, source_file_required. Checked directly: each compiled in
  master's tree, p2's tree and p3's tree, with the tree path and the revision replaced, gives the same hash on
  the three (also for frozen_chilled_builtin_strings).
- The 8th on p3 is test/own_send_boxed_receiver.rb, the piece's own test, which master builds (and gets wrong).
- So no corpus program outside the pieces' own tests changes its C: for the 6,350 others the pieces are not
  reached.
- Said plainly: for p3 I did not build a second reference. I seeded p3's reference cache with p2's (same REF,
  same corpus apart from the one new test) and added master's C for test/own_send_boxed_receiver.rb, made
  with the master tree's compiler.

`gate.rb check` warned "no Ruby 4.0 … .expected not checked against CRuby" (this machine has 3.3.6).
Function lengths by gate.rb's own rule (limit 1,000 lines; `emit_call_body` may only shrink):

| function | before | after |
|---|---|---|
| piece 2: desugar_dynamic_send | 323 | 331 |
| piece 2: emit_dynamic_send | 101 | 105 |
| piece 2: infer_call_inner | 985 | 985 (one line changed) |
| piece 2: an_send_may_be_own (new) | | 33 |
| piece 2: send_owned_at_or_below (new) | | 7 |
| piece 2: emit_call_body | 616 | 616 (not touched) |
| piece 3: an_phase_infer_fixpoint | 467 | 272 |
| piece 3: an_infer_fixpoint_rounds (new, cut out of the above) | | 206 |
| piece 3: desugar_public_send_recv | 85 | 101 |
| piece 3: send_split_boxed (new) | | 63 |
| piece 3: desugar_send_settled (new) | | 35 |
| piece 3: send_recv_elem_has_none (new) | | 22 |
| piece 3: send_put_back (new) | | 18 |
| piece 3: send_as_parens (new) | | 10 |

`infer_call_inner` stands at 985 of 1,000 lines on master already; piece 2 does not add to it.

## 8. Cost (measured)

Compile time is CPU seconds of `spinel -c` (user + system), one run each on a loaded machine, so read the
orders, not the last digit. m / p2 / p3:

| program | m | p2 | p3 |
|---|---|---|---|
| 500 literal sends on a boxed parameter in one method, own send in the program | 0.09 | 0.10 | 0.94 |
| 2,000 of the same | 0.36 | 0.37 | 11.85 |
| 500, box holding Peer or Integer | 0.08 | 0.09 | 1.06 |
| 2,000 of the same | 0.42 | 0.36 | 13.02 |
| 2,000, no own send in the program (same C on the three) | 0.36 | 0.39 | 0.38 |
| 2,000 sites spread over 200 methods of 10 | 0.54 | 0.58 | 1.86 |
| block parameter over an Array typed in the re-narrow, 2,000 sites, own send | 2.52 | 2.88 | 3.39 |
| the same, no own send | 2.50 | 2.65 | 2.92 |
| piece 2: 2,000 computed sends on a typed receiver, own send | 0.53 | 0.64 | 0.53 |
| the same, no own send | 0.50 | 0.60 | 0.64 |
| piece 2: 500 classes each with a bare computed send, no own send | 11.33 | 10.94 | 11.01 |
| the same, with an own send in one more class | 0.32 (master lowers none; they raise at run time) | 13.58 | 14.10 |

Piece 2's cost is of the same order as the lowering it turns on (13.58 s against 10.94 s for the twin with no
own send: the per-call question costs about a quarter more on that program). Piece 3's is not (finding 6).

Run time (callgrind instruction counts, gcc -O2 as spinel builds, one run each):

| program | m | p2 | p3 |
|---|---|---|---|
| 600,000 literal sends on a box of Peer or Integer, no own send in the program | 22,566,871 | 22,566,871 | 22,566,871 |
| the same, own send in the program (the box never holds the owner) | 22,566,871 | 22,566,871 | 25,266,888 |
| box of String or Array, no own send | 58,563,916 | 58,563,916 | 58,563,916 |
| the same, own send in the program | | 58,563,916 | 67,566,204 |
| box that does hold the owner (p2's answer is wrong there) | | 6,066,680 | 6,966,688 |
| 300,000 typed calls of the own send, plus one boxed literal send elsewhere | | 27,971,735 | 71,176,586 |

## 9. The texts, sentence by sentence

Read: `texts/own-send-175-p2-title.txt`, `-p2-body.md`, `-p2-commit-message.txt`, and the three for p3.
Form, both pieces: the commit-message files equal the commits' messages (one trailing newline apart); one
`Co-Authored-By: Claude Code <noreply@anthropic.com>` each; no number sign followed by a digit; no model
name; no session link; titles 64 and 64 characters; one code line of 73 characters in piece 3's message.

### Piece 2

| sentence | verdict |
|---|---|
| Title: "A computed send beside a class's own send still names its method" | true for the reproducer (run) |
| Body line 1, the template comment | TEXT FIX: it is the old first line. Master's template now reads `<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->` |
| The reproducer "raises `NoMethodError` on master (undefined method 'send' for an instance of Array)" | true (run on master; `spinel diff` says "exception-diff … NoMethodError: undefined method 'send' for an instance of Array") |
| "A bare `send("on_#{ev}")` in a class with no `send` of its own, `door.public_send(m)` and `door.__send__(m)` are refused." | true (each run on master: refused) |
| "`desugar_dynamic_send` stood down for the whole program as soon as any scope was named `send`, `__send__` or `public_send`, and every other computed send was left an ordinary call that nothing answers." | true (read in master's source; seen in the runs) |
| "Now the lowering stands down for a call only where the program's own method can take it (`an_send_may_be_own`): …" | NOT TRUE in two places: a reader made by `attr_reader` or a Struct member can take the call and the lowering does not stand down (finding 1); self in a top-level def can be an object whose class owns the name and the lowering does not stand down (finding 2) |
| the list "the receiver's class, or a class under it, has the name in its chain; the receiver is boxed or has no type yet; self in a module's method or an `instance_eval` block; the program has a top-level def of the name; or a builtin the program reopened defines it" | arms seen in runs: class and subclass (routes a1), module method and instance_eval (a2), reopened Object (the piece's test, `tmp/reopen_obj.rb`), Kernel (`tmp/reopen_kernel.rb`), Comparable and Hash (a1): master's C is kept and is right. The body leaves out the bare `public_send` at the top level, which the commit message has |
| "Every other call is lowered as it is in a program that defines none." | true as far as the piece's own question goes; see findings 1 and 2 for calls that should not be among "every other" |
| "The arms are made while the receiver has one type and a later round can widen it, so the two readers of `dyn_send_arms` ask again and leave the call as it was when the receiver has become one the own method can take." | read in the diff (infer_call_inner, emit_dynamic_send); my widening programs (param_both and hand/a29) came out with master's C, so I did not see this path change an answer |
| "Not in this change: a computed send on a receiver that is boxed while the fixpoint runs, in a program that defines the name." | true (hand/a29: same C as master, the Plain call still raises NoMethodError where CRuby prints) |
| "`test/computed_send_beside_own_send.rb` prints 16 lines and `test/computed_send_object_send.rb` 12; master refuses both." | true (run) |
| Gate block | TEXT FIX: still the placeholder "paste the Tests:, scale-test and gate: lines here", boxes open |
| "Depends on: # (A class's own send takes a literal first argument)" | fine as words; to be filled when piece 1 has a number |
| Commit message: "A public_send written bare at the top level is left as written too: a top-level def is private, which public_send does not call, and the lowering keeps no list of them." | true only for a program that defines `public_send` itself (read in the source: the question is asked per name). In a program that defines `send` alone, a bare `public_send(m)` at the top level is lowered and calls the private top-level def (`tmp/psend_main.rb`: master refuses, p2 prints `"top#ping"`, CRuby raises NoMethodError); the twin with no own send does the same on master. TEXT FIX: say "in a program that defines public_send" |
| Commit message: "`class Object; def send` is every receiver's method, and the chains asked here do not place a builtin among a class's ancestors, so there every computed send stays as written." | true (run: reopened Object, Kernel, Comparable, Hash keep master's C) |
| Commit message: "A program that defines none of the three names never asks, and compiles to the same C." | second half true (cident: the corpus keeps its C). First half inexact: `infer_call_inner` and `emit_dynamic_send` do call `an_send_may_be_own` for every call with arms; it scans the scopes and answers no |
| Commit message: "Tests: … (expected from CRuby 3.3.6 with --enable-frozen-string-literal)" | true (compared) |

### Piece 3

| sentence | verdict |
|---|---|
| Title: "A boxed receiver that holds an object with its own send calls it" | true for the reproducer and for the generator's programs (section 5) |
| Body line 1, the template comment | TEXT FIX: the old first line, as in piece 2 |
| The reproducer "prints `Conn#hello 0` on master" | true (run; `spinel diff`: "output-diff: -a:hello:0 / +Conn#hello 0") |
| "The block parameter is boxed while the fixpoint runs, so the retarget in `desugar_public_send_recv` cannot read off whose `send` it is, and waiting does not help: the Array gets its class only in the re-narrow, after the last round." | read in the source; consistent with the runs; not proved by me |
| "Now, in a program that defines the name, the retarget on a boxed receiver goes ahead as before and marks the call. Once the re-narrow has run, `desugar_send_settled` asks again." | read in the diff |
| "A receiver now typed with a class that owns the name gets its call back." | true (family b1, "own only" holds: right on p3, wrong on p2) |
| "One still boxed becomes `(__r = recv; __r.is_a?(Conn) ? __r.send("hello", 0) : __r.hello(0))` over the classes that define the name, the shape `desugar_builtin_enum_calls` gives a boxed receiver beside a class's own `each`." | true as to the shape (seen in the C: `lv___sendrecv_N`); receiver and arguments evaluated once: true (family b3 with ticks). It leaves out what the shape costs (finding 6) and that the owner arm is typed even where the box never holds the owner (finding 5 comes from that) |
| "Every other call stays the retargeted call it was." | true where I looked; the commit message names the case of a block's parameter over an Array typed with a class that has no such method, the body does not |
| "A call that changed is one no round has seen, so the rounds run once more for it (`an_infer_fixpoint_rounds`); a program that defines none of the three names is never marked." | read in the diff; second half true (cident). The extra rounds are where the compile cost of finding 6 is paid, and finding 5 shows a type they do not settle again |
| "Not in this change: a send that carries a block, a send of a send, and a program where a singleton, an unnamed Struct or a reopened builtin defines the name are retargeted as before." | true for the four I ran (`tmp/nc/`: a send with a block, a send of a send, a singleton def, a reopened Integer: same C on master, p2, p3). The unnamed Struct was not run |
| "`test/own_send_boxed_receiver.rb` prints 25 lines; master prints 2 and raises NoMethodError." | true (run: 2 lines, then exit 1) |
| Gate block | TEXT FIX: still the placeholder, boxes open |
| "Depends on: # (…; …)" | fine as words |
| Commit message: "with `def send(msg, flags)` on Conn called Conn#hello where the class has one, a silent wrong answer, and raised NoMethodError where it has none." | true (both run on master) |
| Commit message: "The second arm is the retargeted call as it was, with its `&.` and its visibility stamp; receiver and arguments are evaluated once" | `&.` forms right on p3 (b1 "safe" forms, hand/b11); private own send right (hand/b25) |
| Commit message: "an_infer_fixpoint_rounds, the fixpoint without its re-narrow; types only widen there" | read; finding 5 is a case where a type should have widened and did not |
| Commit message: "So is a send of a send, `c.send(:send, :open)`: it is retargeted twice, the call left is not the one written, and it carries no mark (send_hop)." | true as to the result (same C as master) |
| Commit message: "A program that defines none of the three names is never marked and compiles to the same C." | true (cident; cost twins) |
| Missing in both texts | TEXT FIX: the cost (finding 6), by the house rule that a fix with a cost states it |

## 10. What was NOT run

- `make gate` and `make test` as a whole (the legs in section 7 were run one by one).
- Ruby 4.0: this machine has CRuby 3.3.6; every "CRuby" above is 3.3.6.
- The cut commits on their own base 06064727 (only the tip merges were built).
- Anything on upstream master 5390d3002886 beyond the three `git merge-tree` lines.
- A second cident reference for p3 (seeded from p2's, see section 7).
- Most of what my generators wrote. Written: 2,138 programs for piece 2 (`ga`), 417 corpus tests with an own
  send added (`gc`), 2,021 for piece 3 (`gb`, `gb2`), 392 for the split in value positions (`gbh`). Run: 534,
  45, 315 and 158 (section 5). The rest stands in `ga_held/`, `gb_held/`, `gb2/`, `gbh_held/`, `gc_held/`,
  `gc_held2/`. The samples were cut by family so that every family has programs in the run, but a finding
  can hide in what was held; two of my findings (2 and 5) came from hand programs, not from the run.
- p1 as a fourth tree in the piece 3 runs (m, p2, p3 there) and p3 in the piece 2 runs (m, p1, p2 there);
  149 piece 2 programs and 26 piece 3 programs ran on all four. In 529 of the 534 piece 2 programs p1's C
  equals master's.
- A true master column for the corpus family `gc`: master refuses all 45, because the line I appended
  (`ZzMailer.new.send("x", 1)`) is piece 1's own case. So for `gc` only the p1 -> p2 table says what piece 2
  changes; the master -> p2 table says only how p2 ends.
- clang for the `gbh` family (gcc only, three stress levels).
- The corpus bystander scan for piece 3 (`scan3.rb`: corpus tests with a class owning send added, compared
  p2 against p3) was written and not run.
- The compile-cost program with 2,000 classes (master alone needs minutes); 500 classes were run.
- `--share-strings` harness runs of my programs (`make share-strings-test` was run).
- The unnamed Struct of piece 3's "Not in this change".

## 11. The harness fault, and a mistake of mine

- The harness is the fixed copy from `/home/claude/r8/rr/harness.rb` (UTF-8 default, `scrub`), put in place
  before any long run. Checked: every `.jsonl` has one record per program of its directory at the end of its
  run (ga 534 records, all 511 programs of the directory among them; gb 315 of 315; gbh 158 of 158; gc 45 of
  45): the logs hold no "terminated with exception" and no "HARNESS-LOST" line. Records that showed "does
  not build" with no error text, a timeout or a signal were listed by `recheck.rb`; the ones with no error
  text were cut-off builds (the restart, or my own stop of a run), were dropped and built on the second run.
  What stays flagged at the end: in ga, 7 programs that do not build on p2 with an error text (findings 3
  and 3b, side find 11) and 3 that run out of stack and time out under stress (G3, side find 6); in gb, 7
  programs with a nil in the box (G2) and the one CRuby itself never ends on; none in gbh; in gc, two
  aborts at stress 2 (side find 9, and p1's abort while raising in `ca_public_send_computed_name_shape`,
  which p2 has right).
- At about 06:02 UTC I ran a loop that worked out the parent pids of one of my harness processes and killed
  them. It walked one level too far and its kill list held pid 1 and process group 0. The container restarted
  at that minute and every reader's background jobs died. It is very probably my command that did it. Since
  then I kill only exact pids read from `ps`, never a computed parent.

## 12. Side finds on master 26d456ec (for the miner; none of them is the pieces')

1. An empty rest parameter read under SPINEL_GC_STRESS=2 with gcc (`side/empty_rest_1.rb`, no send in it):
   `class Object; def relay(m, *a) = "Object#relay #{m} #{a.size}"; end` … `puts Door.new.relay(m)` prints
   `Object#relay open -2604246222170760229`; right with stress unset and 1, and with clang. Also seen as
   `*a, **k` sizes with clang at stress 2 (`b2_m_kw_c0_two_owners_lit_each`). The builder knows it (the new
   computed_send_object_send test steps around it).
2. Range ends are evaluated right to left with gcc (`side/range_order.rb`): `p (tick(1)..tick(3)).sum` prints
   `tick 3` before `tick 1`; clang prints them in CRuby's order.
3. A reader named `send` as the only send in the program (`find/f1_attr_alone.rb`): `attr_reader :send`, then
   `Job.new.send(m)` with a computed name: CRuby raises ArgumentError, master prints `ran`.
4. A bare computed send in a top-level def called from inside an object (`find/f2_top_def_twin2.rb`): CRuby
   calls the object's own `ping`, master calls the top-level `ping`.
5. A bare computed send in a class method does not build (`side/cmeth_bare_send.rb`):
   `def self.go(m) = send(m)` gives C that gcc rejects with "passing argument 1 of 'sp_box_str' makes pointer
   from integer without a cast".
6. A computed send to an object whose own `send` calls `method(msg).call(*rest)` (`tmp/a6m.rb`): CRuby
   prints `"Own#ping"`, master raises SystemStackError.
7. A bare `public_send(m)` at the top level calls a private top-level def (`tmp/psend_main_twin.rb`): CRuby
   raises NoMethodError (private method 'ping' called for main), master prints `"top#ping"`.
8. A computed send whose name is nil (`tmp/a7twin.rb`): CRuby raises TypeError (nil is not a symbol nor a
   string), master raises NoMethodError.
9. The corpus test test/post_rest_keyword_hash.rb aborts under SPINEL_GC_STRESS=2 on master, with gcc (two runs of two) and
   with clang (one run): `*** SPINEL_GC_STRESS: the mark reached a freed slot ***`, exit 134;
   it is right with stress unset and 1. (Seen because one of my corpus programs is that test plus a class.)
10. A literal send on an object-or-nil slot holding the owner: master calls the retargeted method, not the own
   send (`find/g2_nil_recv.rb` prints `false` for `"own:==:"`); this is what piece 1 is about, named here only
   because the nil line beside it is G2.
11. A computed send that carries a block does not build (`side/send_block_map_select.rb`):
   `m = [:map, :select][ARGV.size]`, `r = [3, 1, 2].send(m) { |v| v > 1 }`, `p(r)`: gcc
   `incompatible types when assigning to type 'sp_RbVal' from type 'sp_int'`; CRuby prints
   `[true, false, true]`.
