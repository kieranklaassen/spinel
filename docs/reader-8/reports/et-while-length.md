# Second reading, reader 8: brief ET, the two "while length" commits

Read on upstream master 8684d54ce75ffe60dba47b754acd2104e502aaa7, CRuby 3.3.6
(`--enable-frozen-string-literal`), gcc 13.3 and clang 18.1.3, x86_64 Linux,
valgrind 3.22.  Branch `claude/while-length-read-on-2f204adb`.

- commit 1  e84ea6f32f3b (tree 11871b95087e) "A while's String length is read
  ahead of the loop only where its first test reads it"; merged alone into
  master: tree 070bcbf9446b (as the builder says).
- commit 2  20e643c58f0b (tree 1500e06e0555) "A loop that can change a String
  reads its length at every test"; merged tip: tree ad6d805c6b45 (as the
  builder says; the same tree by cherry-picking both over master).

Trees used: m (master), p1 (master + commit 1), p2 (master + both), h0 (master
with the hoist switched off: `int hr = -1;` in emit_while).  h0 is the oracle:
both commits can only take hoists away, so wherever the piece's C is h0's C the
piece is "master with no hoist", and wherever it keeps a hoist its output must
be h0's output.

## VERDICTS

1. commit 1: **PASS WITH TEXT FIXES** (findings 1.1, 1.2, 1.3).
2. commit 2: **PASS WITH TEXT FIXES** (findings 2.1 to 2.5).  2.1 and 2.2 are
   about the stated cost, which is this commit's ruling ("fix with a stated
   cost": the cost first, with numbers and the smallest program): the cost in
   the body is neither first nor whole.  If the coordinator reads an understated
   cost as NOT READY, it is findings 2.1 and 2.2 that decide; no program was
   found that the code makes wrong.

Rule (a), both commits: 0 rows in every family.
Rule (b): 12 rows (2 programs), commit 1, twin test passed by script (1.1).

## COUNTS

Rows are program x C compiler x SPINEL_GC_STRESS (unset, 1, 2); classes against
CRuby: R right, W silent wrong, L loud, X refused or not built, ? CRuby itself
does not end.

### Family C (gen_c.rb): where in the test the length read stands. 969 programs, 5,814 rows.

43 guard forms x 10 test forms (pruned) x while/until x block, modifier and
post-test loop x method, top level and block parameter x rescued and unrescued,
each over "abc", "", nil.

| | m -> p1 | m -> p2 | p1 -> p2 |
|---|---|---|---|
| programs whose C changes | 543 | 576 | 33 |
| R = R | 3,426 | 3,426 | 5,676 |
| L -> R (raise cured) | 840 | 840 | 0 |
| W -> R (rescued raise cured) | 1,410 | 1,410 | 0 |
| L -> W (rule (b) candidates) | 12 | 12 | 0 |
| L = L | 24 | 24 | 24 |
| W = W | 90 | 90 | 102 |
| ? = ? | 12 | 12 | 12 |
| R -> anything else (rule (a)) | 0 | 0 | 0 |
| programs that keep a hoist | 215 | 182 | |
| rows where a kept hoist's output differs from h0 | 0 | 0 | |

Every guard the body of commit 1 names is cured: `s &&`, `!s.nil? &&`,
`until s.nil? ||`, the ternary, the `if` modifier, `&.`, a flag, the right of
`||`, `(i += 1) < s.length`.  The L = L and W = W rows are master's own (the
`respond_to?` guard the body names; `defined?` in rescued form; post-test loops,
which never hoisted).

### Family B (gen_b.rb): builtin names the program redefines, overrides, default blocks. 1,257 programs.

By generated C: 139 refused on m and p2 alike (singleton, `class << s`, extend
on a String, compare_by_identity); p2 keeps a hoist in 380.  Those 380 and the
trap program were run whole: 381 programs, 2,286 rows.

| m -> p2 | rows |
|---|---|
| R = R | 1,812 |
| W = W | 216 |
| L = L | 258 |
| rule (a), rule (b) | 0, 0 |
| rows where the kept hoist's output differs from h0 | 6 (one program: finding 2.3) |

The W = W rows are master's faults (a redefined builtin that master never
calls: side finds), the same with the hoist off.

### Family A (gen_a.rb): a String changed through any holder. 1,302 programs.

Holders (a second local, a parameter, an Array, a Hash, an ivar, an attr, a
Struct, a lambda, a block, a yielder, a method's return, `ensure`, `rescue`,
...) x 30 mutators x where the change stands (body, test, nested loop, callee).

By generated C (all 1,302, plain and `--share-strings`):

| | plain | --share-strings |
|---|---|---|
| refused on p2 (and on m: 0 refused by p2 alone) | 39 | 176 |
| C changed m -> p2 | 1,178 | 1,041 |
| p2 keeps a hoist (C differs from h0) | 7 | 7 |

The 7 are the controls (`t += "!"`: a rebind, the String itself is not
changed), and they are right.  Every other program's C on p2 is h0's C byte for
byte, so the piece there is master with the read in the test.

Run whole: only 84 of the 1,302 (the first 63 in name order and 42 of every
third; the machine was shared with four other readings and the run was cut
short).  504 rows: W -> R 502, L = L 2, rule (a) 0, rule (b) 0, 0 rows differ
from h0, no timeouts.  The rest stands on the C comparison above.

### Family A2 (gen_a.rb with A2=1): the same roads with a change that keeps the length. 580 programs.

This is rule (a)'s family: master's count is right because the length does not
move; does reading it at each test break one?  By C: p2 keeps a hoist in 0,
refused 8 (plain) and 35 (`--share-strings`), C changed 525 and 498.

Run whole: every third program, 193 programs, 1,122 rows (plain): R = R 1,050,
W = W 64, L = L 8; rule (a) 0, rule (b) 0; 0 rows differ from h0; no timeouts.
The W = W and L = L rows are byte-identical on m and p2 (master's own faults in
`replace`, `gsub!`, `succ!`, `tr!` through a constant, a String method or a
yielder: the String the loop names is not the one changed).  Not run under
`--share-strings` (compared by C only).

### Family D (gen_d.rb): code the loop runs with no visible call. 224 programs.

A program class's `to_s` under interpolation and `puts`, `+ - == != < <=> []
[]= hash eql? === each call to_str to_a coerce`, `nil?`, `!`, `-@`, a writer,
a reader method, `method_missing`, an exception's `message`, a module function,
blocks, lambdas, `&:sym`, `for`, Comparable and Enumerable through `<=>` and
`each`, each appending to the String through an object that holds it.

By C: 6 refused, p2 keeps a hoist in 20 (10 bodies x top level and method):
`x = t.length` (a second name read), `x = k && 1`, `x = k.v` (an attr_accessor
field), `x = BOX.s.length`, `x = BOX.s`, `x = 1 if k`, `x = 1 unless k`,
`x = k ? 1 : 2`, a nested `while j < t.length`, `return 5 if ...`.  None of the
ten runs code.  198 lose it.

Run whole: 71 of the 224 when the verdict went out (426 rows): R = R 162,
W -> R 126, W = W 126 (master does not run the program's method at all there,
with the hoist or without); rule (a) 0, rule (b) 0; 0 rows differ from h0.

### Family F (hand probes, w/gf): 25 programs.

`sa[0] <<= "!"`, `b.s <<= "!"`, `@s <<= "!"`, `h["k"] <<= "!"`, `t ||= s` then
`t << "!"`, `prepend` and `include` on String, a reader redefined by a later
`def`, by `alias`, by `define_method`, by a prepended module, by a singleton
`def b.n`, a writer `def n=`, a Struct block's reader, `def Integer.sqrt`, a
program `==` with an Integer argument, a change inside `ensure`, in the test
(`while i < s.length && grow(s)`), in a modifier loop's statement, through
`s.to_s` and `s.to_str` (which answer the String itself), in a nested loop, in a
`return`'s value.  p2 loses the hoist in 23, keeps it in 1 (a constant String
only read: right), 1 is refused by all three.  No program differs from h0.
Where p2 is still wrong it is h0's answer (side finds 5 to 8).

### The piece's own tests (gcc and clang, stress unset, 1, 2: 6 rows each)

- `test/while_length_guarded.rb`: master exits 1 (NoMethodError, 9 lines
  short); p1 and p2 print the `.expected`, all 6 rows.
- `test/while_length_changed.rb`: master and p1 have 12 of 18 lines wrong; p2
  prints the `.expected`, all 6 rows.
- Both `.expected` files are CRuby 3.3.6's output byte for byte (4.0 not here).

### Gate legs

- `make cident REF=8684d54c`, commit 1 (tree 070bcbf9446b): 6,337 identical, 5
  differ: `test/while_length_guarded.rb` and four programs that print
  RUBY_DESCRIPTION (the revision stamp of my local merge commit, not the piece:
  frozen_chilled_builtin_strings, object_scoped_ruby_constants,
  ruby_description_shape, symbol_id2name_ruby_desc_minmax).
- `make cident REF=8684d54c`, tip (tree ad6d805c6b45): 6,311 identical, 32 differ: the two new tests, the same four RUBY_DESCRIPTION programs, and 26 corpus programs (cgi 2, net/http 8, optparse 12, uri 2, test/hash_local_not_a_strbuf.rb, test/uri_decode_bad_escape.rb): the body's 26.
- `make share-strings-test`: pass.  `make reject-test`: pass.
  `tools/refusals.sh`: pass (530 records).  All on the tip.
- `ruby tools/gate.rb check` with each commit staged over its parent: exit 0
  both (function-size rule holds; the `.expected` against CRuby 4.0 is skipped,
  no Ruby 4.0 here).
- 67 benchmarks and examples: generated C identical on m and p2.
- NOT RUN: `make gate`, `make scale-test`, `make test`, ruby/spec, optcarrot.

### Cost (callgrind Ir, 8684d54c)

The body's three programs, re-measured (m -> p2):

| program | master | tip | |
|---|---|---|---|
| uri_decode.rb | 1,354,102,877 | 1,436,001,091 | +6.05% |
| cgi_entity.rb | 1,072,815,579 | 1,107,614,249 | +3.24% |
| hash_store.rb | 886,661,688 | 965,498,372 | +8.89% |
| tight_ascii.rb | 2,212,868,587 | 2,212,868,587 | 0 (hoist off: 10,012,668,585, 4.52x) |

The percentages are the body's (its absolute figures are 2f204adb's).

Loops that change no String and now re-read (w/cost, each 2,000 passes over a
900 or 1,000 character String; one `sp_str_length_m` call is about 44 Ir a
pass):

| program | master | tip | |
|---|---|---|---|
| lex_case.rb (`case s.getbyte(i) when 32 ... when 43 ...`) | 34,180,444 | 113,962,448 | 3.33x |
| gvar_read.rb (`tot += s.getbyte(i) + $k`) | 48,794,549 | 140,762,547 | 2.88x |
| arr_push.rb (`a << s.getbyte(i)`) | 62,791,252 | 140,807,598 | 2.24x |
| digit_rng.rb (`n += 1 if (48..57).include?(s.getbyte(i))`) | 180,370,450 | 248,762,450 | +37.9% |
| case_str.rb (`case s[i] when " " ... when "+" ...`) | 511,972,245 | 582,770,245 | +13.8% |

Commit 1, guarded loops over a String that is never nil (m -> p1; p2 the same):

| program | master | commit 1 | |
|---|---|---|---|
| guard_and.rb (`while s && i < s.length`) | 36,866,554 | 116,850,554 | 3.17x |
| guard_flag.rb (`while on && i < s.length`) | 22,856,554 | 100,840,539 | 4.41x |
| guard_lim.rb (`while i < lim && i < s.length`) | 22,862,555 | 104,840,553 | 4.58x |

Compile time: a 64,007-line program of 2,000 hoisting loops: 105.1 s (m), 106.0
s (p1), 106.9 s (p2); a deeply nested one about 0.12 s on each.  Same order.

## FINDINGS, commit 1

### 1.1 (text) A `defined?(s.length) &&` guard goes from a raise to a wrong count; the body does not name it

```ruby
def run(s)
  i = 0
  while defined?(s.length) && i < 3
    i += 1
  end
  i
end
p run("abc")
p run(nil)
```

CRuby: `3`, `0`.  master: `3`, then NoMethodError (exit 1).  p1, p2 and h0:
`3`, `3` (exit 0).  12 rows (this and its modifier form, gcc and clang, three
stress levels).

Twin, by script (w/b/defd_twin.rb: the same program with `defined?(s.upcase)`,
nothing else changed): master prints `3`, `3`.  So master already answers
"method" for `defined?(x.m)` on a nil String-typed local; the hoisted read
raised ahead of it by accident.  p1's C for the program is h0's C byte for
byte, and differs from master's only by the hoist line and the temp numbers.
Reached, not made.  The body must say so in one sentence under "Left alone",
beside the `respond_to?` sentence (which is the same shape and is named).

### 1.2 (text, class) The commit moves cost for right programs and the body gives no number

A loop whose guard is not about nil at all (`while on && i < s.length`,
`while i < lim && i < s.length`) or whose String is never nil
(`while s && i < s.length`) was right on master and is right on the piece, and
now calls `sp_str_length_m` at every test: 3.17x, 4.41x and 4.58x Ir on the
tight loops in the table above.  No corpus program has such a loop (cident:
only the new test differs), which is worth a sentence too.  The body says "Any
other loop reads the length in its test, as a loop with nothing to hoist does"
and stops.  Either the class is "fix with a stated cost" like commit 2, with
the number and the program first, or the coordinator rules that a sentence with
the number is enough.  (A read ahead that is made only where `s` is not nil,
with the test reading in place where it is nil, would keep these hoists; the
builder's call, not asked for.)

### 1.3 (text) "Checked" is measured at 2f204adb

"`make cident REF=2f204adb`: 6,339 identical, 1 differ".  On 8684d54c: 6,341
programs, the new test the only one the piece changes.  The body's "optcarrot's
C is identical" was not re-checked by me (optcarrot is not in this container).
The row is to be re-measured on the master it is opened on.

## FINDINGS, commit 2

### 2.1 (text, the ruling) The cost does not stand first

The ruling for this commit is "fix with a stated cost: the cost must stand
first in its body with numbers and the smallest program".  The body opens with
the reproducer; the cost is the fifth bullet of "Checked" and the first of
"Left alone".

### 2.2 (text) The stated cost is short of the measured one, in reach and in size

Body: "A loop that calls a method of the program, appends to another String or
stores into a Hash reads the length at each test even where none of that
reaches the String ... That is the cost above" (+3.25% to +8.89%).

Measured (family E, gen_e.rb: 104 scanner-loop bodies that change no String,
all hoisted on master): p2 keeps the hoist in 51 and loses it in 53.  Lost,
besides the three roads the body names:

- a global read or write (`n += $k`, `$n = i`);
- `puts`, `print`, `p`, `raise`, `format`, `Integer(...)` (any call with no
  receiver);
- an Array append (`a << i`, `a.push(i)`), `a.include?(i)`, `[n, i].max`;
- `case s[i] when "a"`, and `case s.getbyte(i) when 32`;
- `"#{i}"`, `i.to_s`, `(n + 1).chr`;
- a Regexp match (`=~`, `match?`), a Range test (`(48..57).include?(b)`,
  `("a".."z").cover?(c)`), `b.between?(48, 57)`;
- `sy == :a`, `s[i].nil?`, `s.is_a?(String)`, `s[i].freeze`, `s.dup`;
- String readers outside the list: `tr`, `sub`, `gsub`, `delete`, `succ`,
  `hex`, `center`, `ljust`, `split`, `bytes`, `chars`, `unpack1`;
- a block (`2.times { }`, `sa.each { }`), `begin ... rescue ... end`;
- `k.v = i` (an attr writer), `K.new(i)`, `f = f * 1.5`, `x, y = i, n`,
  `h.fetch(k, 0)`, `h["a"] += 1`.

And the size: where the body is cheap the loop pays the whole hoist, which the
body's own tight_ascii line prices at 4.5x.  Smallest program (lex_case.rb):

```ruby
s = "ab cd+ef " * 100
n = 0
2_000.times do
  i = 0
  while i < s.length
    case s.getbyte(i)
    when 32 then n += 1
    when 43 then n += 2
    end
    i += 1
  end
end
p n
```

34,180,444 -> 113,962,448 Ir (3.33x); `tot += s.getbyte(i) + $k`: 2.88x;
`a << s.getbyte(i)`: 2.24x.  The corpus reach is what the body says it is
(seven loops), so the honest sentence is both: seven loops in the corpus, +3%
to +9% there; and a byte scanner with a `case`, a global or an Array append in
it goes up to 3.3x.  matz's call needs the second half.  (Keeping the hoist for
`case` over Integer or String literals, a global read, a Symbol `==`, `nil?`
and an Integer Range test would take most of it back; the builder's call.)

### 2.3 (text or one line of code) A `Signal.trap` handler changes the String and the hoist is kept

```ruby
s = +"ab"
Signal.trap("USR1") { s << "!!!" }
system("sh -c 'sleep 0.3; kill -USR1 #{Process.pid}' &")
k = 0
i = 5
while s.length < i
  k += 1
end
p s
p k > 0
```

CRuby: `"ab!!!"`, `true`.  h0 (no hoist): the same.  master, p1 and p2: the
loop never ends (the handler runs inside the C signal handler; the length read
ahead is never read again).  Unchanged from master, so neither rule is broken,
but the body's sentence "The length is read ahead only where nothing in the
loop can change a String" is not true of it, and `len_loop_quiet`'s comment
names threads and finalizers as the only things at the loop's poll.  Either
`trap` joins `g_uses_threads || g_uses_finalizers`, or "Left alone" names it.
(The builder's hand-over lists it as a side find; it belongs in the body.)

### 2.4 (text) "Left alone": `capitalize!` on "ß" is cured, not left

Body: "`setbyte` that changes how many characters there are, `capitalize!` and
`swapcase!` on "ß", and a method added to String that changes `self` still
give a wrong count, with the read hoisted or not."

```ruby
s = +"ß"
i = 0
while i < s.length
  s.capitalize! if i == 0
  i += 1
end
p i
```

CRuby `2`, master `1`, p2 `2` (h0 `2`); the same for "ßa" (3, 2, 3).  So
`capitalize!` is one more cure.  The other three stand as written: `swapcase!`
on "ß" (CRuby 2, all trees 1: master's `swapcase!` leaves "ß"), the `setbyte`
that joins two bytes (CRuby 6, all trees 5), and `def grow!; self << "!"; end`
in `class String` (CRuby 5, all trees 2).

### 2.5 (text) "Checked" is measured at 2f204adb and 06064727

The seven corpus lines are right on 8684d54c (uri.rb 138, 164, 264, 294; cgi.rb
194; optparse.rb 213; hash_local_not_a_strbuf.rb 13).  `make cident` on the tip against 8684d54c: 6,311 identical, 32 differ: the two new tests, four RUBY_DESCRIPTION programs (my merge commit's revision stamp) and the body's 26 (cgi 2, net/http 8, optparse 12, uri 2, test/hash_local_not_a_strbuf.rb, test/uri_decode_bad_escape.rb).  The
callgrind percentages hold on 8684d54c (table above); the absolute figures and
the cident count are the older master's.  "scale-test: 1.71x, ..." and the
0.13 s / 0.52 s timing were not re-run by me (callgrind: tight_ascii identical
on m and p2, 4.52x with the hoist off).

### What holds (commit 2)

- The reproducer and its `spinel diff` report reproduce byte for byte on master.
- "one of 32 mutators": 32 counted in master's list.
- "Chosen against" (the plain-slot cure is unsound): confirmed.
  `t = s; ... t.force_encoding("BINARY") if i == 0` over "héé": CRuby 5,
  master 3, p2 5; `s`'s slot is plain and `s` is handed to no call.
- The keep-list: no program in families A, B, C, D, F keeps a hoist and differs
  from h0, the trap program apart.  It is closed against everything I could
  make the compiler accept.
- No "number sign and digits" in titles, bodies or commit messages; no model
  name, no session link; one `Co-Authored-By: Claude Code` trailer on each
  commit; upstream pull requests are not named at all.  "Depends on" of body 2
  says in words what it stands above.

## NOT RUN

`make gate`, `make test`, `make scale-test`, ruby/spec, optcarrot; CRuby 4.0
(the `.expected` files were checked against 3.3.6 only); family A and A2 whole
(run as samples, the whole sets compared by generated C); arm64; `-O0` builds.

## SIDE FINDS ON MASTER (for the miner; none built)

1. A builtin the program redefines is not called: `String#getbyte` by `def`,
   `alias` and `define_method`; `Hash#member?`; `def Math.sqrt` and `module
   Math`; `String#<=>` under `<`; `String#==` under `!=`; `Array#[]` and `[]=`
   under `ia[0] += 1`.  Silent wrong answers.
2. `defined?(s.length)` answers "method" for a nil String-typed local (finding
   1.1's twin); `s.respond_to?(:length)` answers true for it.
3. `f = 0.5; while ...; f = f * 2.0; end` boxes `f` (sp_poly_mul).
4. `String.class_eval do def ... end end`: NoMethodError at run time.
5. `sa = [s]; sa[0] <<= "!"` and `@s <<= "!"` (with `s = @s`) do not change the
   String `s` names (CRuby: they do; loop count 5, Spinel 2 with or without the
   hoist).
6. `def Integer.sqrt(x)` is never called (`Integer.sqrt(16)` takes the builtin).
7. `def b.n` on one object of a class with `attr_reader :n` is never called.
8. `class String; def grow!; self << "!"; end; end`: the caller's String does
   not change.  `swapcase!` leaves "ß".  `prepend`/`include` of a module into
   String whose method calls `length` with no receiver: "undefined local
   variable or method 'length'" at run time.
9. A `Signal.trap` block runs inside the C signal handler (finding 2.3).
10. `t <<= "!"` on a String local is refused ("unsupported operator
    assignment") though `b.s <<= "!"` builds.

## ADDED 05:15 UTC: the tip 26d456ec1035

Both commits merge clean into 26d456ec1035 (commit 1 alone: tree ec1d9582f413;
tip: tree 7153687b73c7).  Built; the two tests there, gcc and clang, stress
unset, 1, 2: `while_length_guarded` exits 1 on the new master and is right on
the merged tip, `while_length_changed` prints wrong lines on the new master and
is right on the merged tip (12 rows each way).  No cident on this tip: the
coordinator ruled (04:50) that no more reading is owed until the repair exists.
Family D stopped at 71 of 224 programs, family A at 84 of 1,302 (see above).

## ADDED 05:45 UTC: one program the harness lost

The harness dropped one family A2 program without a record (a C compiler error
message with a non-ASCII quote killed a worker thread): `a_lambda__setbyte__body_lt_meth`.
Run by hand: its C does not build on m, p2 and h0 alike (gcc and clang:
"lv_s undeclared"), so it is X = X, 6 rows, master's fault (side find 11: a
lambda that calls `setbyte` on a String parameter of the method it is made in
does not build).  No other ET run lost a program (logs checked).
