# encoding: utf-8
Encoding.default_external = Encoding::UTF_8
f = "pr175-pieces-2-3.md"; s = File.read(f)
def rep(s, a, b) = (s.sub!(a) { b } or abort("no match: #{a[0, 60]}"))
counts = File.read("/home/claude/r8/p175s/counts.out")

rep(s, "@@COUNTS@@", counts + <<'T')

### Reading the tables

Piece 2 (`ga`, 534 programs, p1 -> p2): 290 keep their C; of the 244 that change, 194 are made right
(1,164 rows go from loud, refused or wrong to right) and 5 were right and stay right. The rest, each viewed:
- "RULE_A" 3 programs: two are finding 1 (`a1_attr_reader_s_own_interp_b`,
  `a1_attr_reader_s_ary_elem_own_symidx_b`); the third (`a2_d_cmeth_impl_private`) is finding 3, which the
  script calls right on master because the exception class is the same; I do not count it.
- "RULE_B candidate" 2 programs: `a6_method_call_plain_comp_s` (side find 6) and `a7_s_class_local_nil` (side
  find 8). For both the twin without an own send is wrong on master in the same way, by script; not counted.
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
T

rep(s, "Outputs are from runs with gcc and clang; where one line is given, both C compilers and the three stress
levels agree unless said otherwise. CRuby is 3.3.6.",
"Outputs are from runs with gcc and clang. The finding programs themselves (findings 1, 2, 5 and its second
face, G1, G2) were run with SPINEL_GC_STRESS unset, 1 and 2 and agree on all six rows; their variants and
twins, and findings 3, 3b and G3, were run with stress unset. CRuby is 3.3.6.")

rep(s, "### Finding 4 (piece 2, carry)", <<'T'.chomp)
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

### Finding 4 (piece 2, carry)
T

rep(s, "## 5. Counts from my own generators", <<'T'.chomp)
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
T

rep(s, "  on piece 1, and so not on pieces 2 and 3 either (G1: the C does not build; G2: a nil receiver gets the
  program's own send, a silent wrong line or a segfault). Neither comes from piece 2 or 3 (same C on p1, p2;
  p3's differs for G1 and fails the same way). They are in section 4 because both pieces stand on them.",
"  on piece 1, and so not on pieces 2 and 3 either (G1: the C does not build; G2: a nil receiver gets the
  program's own send, a silent wrong line or a segfault; G3: an own send that forwards with `super` or
  `method(msg).call` raises). None comes from piece 2 or 3 (same C on p1 and p2; p3's differs for G1 and
  fails the same way). They are in section 4 because both pieces stand on them.")
rep(s, "- **The ground (piece 1, 9de0751585f2, passed before me)**: two programs that master has right are not right",
"- **The ground (piece 1, 9de0751585f2, passed before me)**: three kinds of program that master has right are not right")

rep(s, "about the first 150 piece 2 programs and the first 50 piece 3 programs ran on all four. In every piece 2
  program run (`ga`), p1's C equals master's, so the two piece 2 tables are the same table.",
"149 piece 2 programs and 26 piece 3 programs ran on all four. In 529 of the 534 piece 2 programs p1's C
  equals master's.")

rep(s, "- Most of what my generators wrote. Written: 2,138 programs for piece 2 (`ga`), 417 corpus tests with an own
  send added (`gc`), 2,021 for piece 3 (`gb`, `gb2`), 392 for the split in value positions (`gbh`). Run: the
  numbers in section 5. The rest stands in `ga_held/`, `ga_held2/`, `gb_held/`, `gb_held2/`, `gb2/`,
  `gbh_held/`, `gbh_held2/`, `gc_held/`, `gc_held2/`. The samples were cut by family so that every family has
  programs in the run, but a finding can hide in what was held.",
"- Most of what my generators wrote. Written: 2,138 programs for piece 2 (`ga`), 417 corpus tests with an own
  send added (`gc`), 2,021 for piece 3 (`gb`, `gb2`), 392 for the split in value positions (`gbh`). Run: 534,
  45, 315 and 158 (section 5). The rest stands in `ga_held/`, `gb_held/`, `gb2/`, `gbh_held/`, `gc_held/`,
  `gc_held2/`. The samples were cut by family so that every family has programs in the run, but a finding
  can hide in what was held; two of my findings (2 and 5) came from hand programs, not from the run.")

rep(s, "  run; the logs hold no \"terminated with exception\" and no \"HARNESS-LOST\" line. Records that showed \"does not
  build\" with no error text, a timeout or a signal were listed by `recheck.rb` and each was run again alone
  or dropped and re-run: the ones with no error text were cut-off builds (a restart, or my own stop of the
  run) and built on the second run; the signals and hangs that stayed are G2.",
"  run (ga 534 records, all 511 programs of the directory among them; gb 315 of 315; gbh 158 of 158; gc 45 of
  45): the logs hold no \"terminated with exception\" and no \"HARNESS-LOST\" line. Records that showed \"does
  not build\" with no error text, a timeout or a signal were listed by `recheck.rb`; the ones with no error
  text were cut-off builds (the restart, or my own stop of a run), were dropped and built on the second run.
  What stays flagged at the end: in ga, 7 programs that do not build on p2 with an error text (findings 3
  and 3b, side find 11) and 3 that run out of stack and time out under stress (G3, side find 6); in gb, 7
  programs with a nil in the box (G2) and the one CRuby itself never ends on; none in gbh; in gc, two
  aborts at stress 2 (side find 9, and p1's abort while raising in `ca_public_send_computed_name_shape`,
  which p2 has right).")

rep(s, "10. A literal send on an object-or-nil slot holding the owner:", "11. A computed send that carries a block does not build (`side/send_block_map_select.rb`):
   `m = [:map, :select][ARGV.size]`, `r = [3, 1, 2].send(m) { |v| v > 1 }`, `p(r)`: gcc
   `incompatible types when assigning to type 'sp_RbVal' from type 'sp_int'`; CRuby prints
   `[true, false, true]`.
10. A literal send on an object-or-nil slot holding the owner:")
File.write(f, s)
puts "patched"
