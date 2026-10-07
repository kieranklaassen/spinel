# Second reading: fork pull request 219, two stacked commits

Commit 1 "A boxed exception of a program's own class answers is_a?, instance_of? and when"
Commit 2 "Name = Class.new(Base) with no block defines the class Name < Base"

Reader: second reader 8, adversarial, independent of the builder. Nothing was
pushed, posted or opened. Everything below was measured by running unless a
line says "by reading".

Masters. **M84** is upstream master 8684d54ce75ffe60dba47b754acd2104e502aaa7
(the master the reading was done on). **M26** is upstream master
26d456ec103513fd8d7d9367dbbc9060854f3116 (the master it moved to; only
section 9 is on M26). Every number carries its master.

## 0. Verdict

- **Commit 1: NOT READY by the letter of rule (a), for one small repair
  (finding C1-1); with that repaired or ruled out of scope by the coordinator,
  PASS WITH TEXT FIXES (C1-2, C1-3).**
- **Commit 2: NOT READY.** Five families of programs that are right on M84
  are not right on the piece (findings C2-1 to C2-5): four silently, one
  refused or not building. The "stated cost" is the first of them; it is not a cost of the
  narrow kind, it is not acceptable as worded, and it is not said first.
  Rule (b): no row fails the twin test.

## 1. What was read, and on which trees

| what | commit | tree |
|---|---|---|
| M84, built at /home/claude/r8/m | 8684d54ce75f | c8df18687690 |
| recut commit 1 (branch `claude/class-new-parent-no-block-on-8684d54c`) | 798cc501e4fa | c834e70129af |
| recut commit 2 | 9ac6f96abcbc | 595f43c01821 |
| my build of commit 1 on M84, `p219/c1-merged-tree-219` ("c1") | 6af6ed2187e6 | c834e70129af |
| my build of the tip on M84, `p219/tip-merged-tree-219` ("tip") | dc9991537a31 | 595f43c01821 |
| commit 1 merged into M26 (`git merge-tree --write-tree`, clean) | not built | 3a0cd939f03e |
| the tip merged into M26, `p219/tip-on-26d456ec-219` ("tip26") | ba1ae8a3533a | 57ed9c6bb8e1 |

**The recut changes nothing measured.** `git rev-parse` gives tree
c834e70129af for 798cc501e4fa and for my c1 build, and tree 595f43c01821 for
9ac6f96abcbc and for my tip build: the trees I built and measured are exactly
the two recut trees, so every number below stands for the recut. The recut is
two commits on M84, the first the parent of the second; their messages are
byte for byte the handoff files `commit-message-1.txt` and
`commit-message-2-v2.txt`; each has the one co-author trailer and no link.

Texts read: the seven files on `origin/claude/pr-text-handoff`
(`class-new-parent-no-block-title-1.txt`, `-body-1.md`,
`-commit-message-1.txt`, `-title-2.txt`, `-body-2.md`,
`-commit-message-2-v2.txt`, `-twin-13.txt`), copied to `p219/texts/`. They
replace the fork pull request's body. The template's first comment line in
the two bodies is not counted (it is swapped at opening).

Base of each commit: commit 1 is read against M84; commit 2 against c1
(M84 + commit 1). CRuby here is 3.3.6 with `--enable-frozen-string-literal`.
Rows are (program, C compiler, `SPINEL_GC_STRESS` unset / 1 / 2).

Generators and families (all under /home/claude/r8/p219/):

| family | generator | programs | run with |
|---|---|---|---|
| commit 2, stated-cost group (`sc_`, `refl_`) | gen2.rb | 243 | gcc and clang, 3 stress levels |
| commit 2, the rest of family 2 (taken, left, position, named-before, names) | gen2.rb | 768 of 1,215 run: 9 groups whole (680 programs), 88 programs of 21 other groups (and 18 of the group above again) | gcc only, 3 stress levels |
| commit 2, hand-written specials | gen3.rb | 34 | gcc and clang, 3 stress levels |
| commit 2, the builder's own 13 | the builder's generator, regenerated (5,449 programs, as claimed) | 13 | gcc and clang, 3 stress levels |
| commit 2, the builder's family `cost_later_def_called_first` | the same | 58 of 58 | gcc only, 3 stress levels |
| commit 2, class names | names/run.rb, names/build.rb, names/rtscan.rb | 254 names x 2 places, and 38 runtime type names | C by c1 and the tip for all; the 159 + 38 the tip takes built with the tip and run, gcc, stress unset |
| commit 1 | gen1.rb | 233 of 591 run (5 groups whole, 69 of the 187 of `plain`, 3 of each of the other 14) | gcc only, 3 stress levels |

**The harness fault the coordinator reported (a worker thread dying on a
non-ASCII byte in the C compiler's error text, and the program it held
getting no record) was checked for.** My copy (h219.rb) passed the
compiler's text through a scrub before every `grep`, so it did not have the
fault; I added the two lines asked for all the same (`Encoding.default_external`,
`scrub` in `run_cmd`) and the same to the other scripts. Checked: no log
holds "terminated with exception"; every `.jsonl` has one record for every
program of its directory or of its `--only` subset (f2.jsonl 243 of 243; f3.jsonl 34 of 34, the directory's other 6
files being required libraries and no programs; bk13.jsonl 13 of 13; the
builder's five shapes 7 of 7; bk58.jsonl 58 of 58; names.tsv 508 of 508,
build.tsv 159 of 159, rtscan.tsv 38 of 38; f2g.jsonl and f1g.jsonl by group,
groupcount.rb: every group run whole has all its programs, the others are
the stated samples of section 8). After the
container restart every `.jsonl` line still parses, and the harness resumed
the one run that was cut (family 1). Records of
a C that did not build exist, with gcc's curly quotes in them
(`pre_subclasses_parent__plain`: `NOBUILD: ... passing argument 1 of
‘sp_PolyArray_length’ ...`, on the base and on the tip alike). **Lost
programs: none.**

## 2. The builder's 13 "stated cost" programs: judgement

**Not acceptable as a stated cost, and not acceptable as worded. They are
rule (a) rows; the inverted test has to take them back.**

What they are. The builder's family `cost_later_def_called_first` puts this
above the assignment and a use below it:

```ruby
begin
  early
  puts "there"
rescue NameError
  puts "not yet"
end
MyErr = Class.new(StandardError)
def early = MyErr.new("e")
```

That is also the smallest program. CRuby 3.3.6 prints `not yet` (a bare
`early` is a NameError there). M84 prints `not yet`. c1 prints `not yet`.
The tip prints `there`. gcc and clang, stress unset, 1 and 2.

Measured on the builder's 13 (regenerated with the builder's generator, run
through my harness, M84 against the tip, gcc and clang, three stress levels,
78 rows):

| | programs | rows |
|---|---|---|
| right on M84, not right on the tip | 13 | 76 |
| of those, silently wrong on the tip (exit 0, other stdout) | 12 | 70 |
| of those, same exit status and exception as CRuby, other stdout (`uncaught`) | 1 | 6 |
| wrong on M84 and on the tip (`full_message_name` at stress 2: `puts e.class.name` prints freed bytes on M84, on the tip and on the keyword twin) | 0 | 2 |

The twin file (`twin-13.txt`), checked against my own runs:

- Each of the 13 twins differs from its program in exactly one line, the
  assignment, which becomes `class MyErr < StandardError; end`. Only the
  cured expression changes. (diff of the 13 pairs.)
- Half 1 by script: the 13 twins, built and run on M84 on their own, print
  on all 78 rows (stdout, exit status, exception class) what the tip prints
  for the program. 13 of 13.
- Half 2 by script: the tip's C for the program is M84's C for the twin,
  byte for byte. 13 of 13.
- The 13 names and the lines in the file agree with my runs at stress unset.
  The file does not show stress 1 and 2; they agree too, the two rows above
  included.

The builder's whole family of that name, 58 programs (regenerated; M84
against the tip, gcc, stress unset/1/2, out/bk58.jsonl), to see whether 13
is the right number: it is. Right on M84 and not right on the tip: 13
programs, 38 rows, the 13 of the twin file and no other. Of the other 45:
34 are loud or refused on M84 and silently wrong on the tip (rule (b) rows,
twin passed), 8 are wrong on both, 2 are loud on M84 and refused on the tip,
1 is refused on M84 and raises on the tip (`sub_keyword_body`, section 6).
None of the 58 is right on the tip. Half 2 against the twin compiled by c1,
the true base of commit 2 (bk58twin.rb): byte-equal for 55 (for 2 of them
but for the file's own path in a `sp_Fiber_at` argument), node numbers only
for 1 (`kept_exceptions`), the same refusal on both for 2.

So the twin test passes, both halves, for all 13. It does not decide them:
the twin is rule (b)'s test and never excuses rule (a), and these programs
were **right on master**. They are not the narrow stated-cost case either:
that case is a program right by accident that becomes LOUD, and these become
silently different (12) or keep CRuby's exit status with another stdout (1).

Is it ONE cost matz can weigh? No. My own generator (gen2.rb, group `sc_`;
gen3.rb) finds the family is wider than the body's sentence "a method can be
called above its `def`":

| what stands above the assignment | smallest program (section 3) | CRuby / M84 / c1 | tip |
|---|---|---|---|
| a call of a method defined below it (9 shapes: `def`, `def` with a block, a chain of two, class method, instance method, `initialize`, module function, `to_s` through an interpolation, through a method defined above) | C2-1a | `not yet` | `there` |
| the same, not rescued | C2-1b | exit 1, NameError | prints, exit 0 |
| a method of a class declared below it (`Helper.make`) | C2-1c | `NameError` | `there` |
| `Base.subclasses` | C2-2a | `[]` | `[MyErr]` |
| `Object.const_get` of a computed name | C2-2b | `not yet` | `there` |

Counts, c1 against the tip. M84 as base gives the same lines: c1's C is M84's
C for every program of the two families of mine (`spinel -S` on both trees;
one program differs only in the tree's own path inside `#line` lines):

| family | programs | right on c1, not right on the tip | rows |
|---|---|---|---|
| stated-cost group, mine | 243 | 92 (90 later-method, 2 `subclasses`) | 552 of 1,458, all silent |
| specials, mine | 34 | 14 | 76 of 204 (72 silent, 4 a new raise) |
| the builder's 13 (M84 against the tip) | 13 | 13 | 76 of 78 |

The repair is of the piece's own kind (text alone). I wrote the two lists and
ran them over the stated-cost group (declist.rb, listcheck.rb): L1, "before
the assignment a receiverless call, or `send` / `method` / `public_send` with
a literal name, names a method defined after it, or a constant names a class
or module declared after it"; L2, "before the assignment a call named
`subclasses`, `constants` or `each_object`, or `const_get` /
`const_defined?` with an argument that is no literal". Declining on L1 or L2
takes back all 92 of the 92 (90 by L1, 2 by L2), and gives up 9 programs the piece makes right today (`sc_*__raise__std`: the
later method only raises the class, and `rescue StandardError` catches it now).
The builder's 13, and all 58 of the builder's family, trip L1 (by script,
declist.rb); none of the 58 is right on the tip, so declining them gives up
nothing. The lists are text alone, so they are conservative: a method body
above the assignment that names a later method and is not called until after
the assignment also trips L1, and that program then stays the call it is on
master, never newly wrong.

If the coordinator rules that it stays a stated cost, the wording still fails
three ways: it is the fifth block of body 2 (line 33), not the first; it is
headed "Not here:", which reads as a thing left unfixed while it is a thing
changed; and it names one of the five shapes above.

## 3. Findings, commit 2 (base c1 = M84 + commit 1; piece = tip)

Each program below was run under CRuby 3.3.6, c1 and the tip; "base" is c1,
and M84 prints what c1 prints for every one of them (same C, section 2).

### C2-1 (rule a, silent). A method or class defined below the assignment, used above it

a. Smallest (the builder's own stated cost):

```ruby
begin
  early
  puts "there"
rescue NameError
  puts "not yet"
end
MyErr = Class.new(StandardError)
def early = MyErr.new("e")
```

CRuby `not yet`. Base `not yet`. Tip `there`. gcc, clang, stress unset/1/2.

b. Not rescued:

```ruby
puts "start"
early
puts "there"
MyErr = Class.new(StandardError)
def early = MyErr.new("e")
puts "end"
```

CRuby prints `start` and exits 1 with NameError. Base the same (stdout, exit
status, exception class). Tip prints `start`, `there`, `end` and exits 0.

c. A class declared below (the body's sentence does not cover it; no method
is called above its `def` by a bare name):

```ruby
begin
  Helper.make
  puts "there"
rescue NameError => e
  puts e.class
end
MyErr = Class.new(StandardError)
class Helper
  def self.make = MyErr.new("e")
end
```

CRuby `NameError`. Base `NameError`. Tip `there`.

Counts: section 2 (90 programs of my stated-cost group, 8 of my specials,
the builder's 13). The twin passes for all of them and does not excuse them.
Repair: decline on list L1 of section 2 (a textual test of the piece's own
kind), extended to the enclosing module and to a required file
(`sp_later_def_in_module`, `sp_require_lib_def_called_first` are the two of
my specials the list as I wrote it misses).

### C2-2 (rule a, silent). The class exists before its assignment for reflection

a.

```ruby
class BaseErr < StandardError; end
p BaseErr.subclasses
MyErr = Class.new(BaseErr)
```

CRuby `[]`. Base `[]`. Tip `[MyErr]`.

b.

```ruby
x = "My"
begin
  Object.const_get(x + "Err")
  puts "there"
rescue NameError
  puts "not yet"
end
MyErr = Class.new(StandardError)
```

CRuby `not yet`. Base `not yet`. Tip `there`.

Counts: 7 programs. 2 of the stated-cost group (`refl_plain_parent_subclasses`,
`refl_user_parent_subclasses`), 2 of the specials, 2 of the named-before
group (`pre_const_get_dyn__plain`, `__r_own`), 1 of the plain-class group
(`p_user__subclasses_before`). Not named in the body at all.
Repair: decline on list L2 of section 2.

### C2-3 (rule a, silent; another of master's faults has to be cured beneath). `e.class.new` of a rescued builtin exception builds the program's first class

```ruby
MyErr = Class.new(StandardError)
begin
  Integer("zz")
rescue ArgumentError => e
  k = e.class
  p k.new("z").class
end
```

CRuby `ArgumentError`. Base `ArgumentError` (stress unset and 1; at stress 2
the base prints freed bytes, master's own rooting fault, side find S2). Tip
`MyErr`, at all three stress levels, gcc and clang.

The realistic shape (a copy of the exception with more context, raised
again) takes the wrong rescue arm:

```ruby
MyErr = Class.new(StandardError)
def copy(e) = e.class.new("copy of #{e.message}")
begin
  [1, 2].fetch(9)
rescue IndexError => e
  c = copy(e)
  p c.class
  begin
    raise c
  rescue IndexError => e2
    puts "caught #{e2.class}"
  rescue StandardError => e2
    puts "wrong arm #{e2.class}"
  end
end
```

CRuby and base: `IndexError`, `caught IndexError`. Tip: `MyErr`,
`wrong arm MyErr`.

With `Pt = Class.new` as the first class the tip raises "wrong number of
arguments" where CRuby and the base print `ArgumentError`
(`sp_first_class_new_plain`: right to loud).

Cause, by reading and by the twin: on master the class value of a rescued
builtin exception carries class id 0, which is the program's first class.
The Class.new program had no class of its own on master, so nothing answered
to id 0 and the fallback was right; the piece gives the program its first
class. Master's keyword twin has the same wrong answer (twin test passes),
which is the definition of two of master's faults cancelling: not a reached
case. The cure for the class-id fault is the ground of another fork pull
request (not merged in M84); this commit has to stand on it, or decline
where the program reads `.class` of a rescued exception and calls `new` on
it. With the class declared inside a module (`sp_first_class_in_module`) the
tip stays right.

Counts: 6 programs. 4 of the 34 specials (`sp_first_class_new`, `_copy`,
`_isa`, `_new_plain`) and `e_top_std__r_unused`, `e_chain2__r_unused` of
family 2.

### C2-4 (rule a, silent; two of master's faults cancelling). The exception rescued under its own name loses identity and `respond_to?`

```ruby
MyErr = Class.new(StandardError)
begin
  raise MyErr, "x"
rescue MyErr => e
  p e.equal?(e)
end
```

CRuby `true`. M84 `true`. Base `true`. Tip `false`. gcc and clang.

The same with `p e.respond_to?(:message)`: CRuby, M84 and base `true`, tip
`false` (gcc and clang, stress unset and 2). The same with
`p e.exception.equal?(e)`.

Cause: on master `raise MyErr` and `rescue MyErr => e` worked by the name
alone for a constant with no class behind it, and `e` was a plain exception
value that answers these rightly. A keyword class's rescued instance is
typed as that class, and master is wrong for it on all three (side finds S1
and S4: master prints `false` for the keyword spelling). The twin passes.
Body 2 lists `e.respond_to?(:message)` under "wrong on master for a class
written with the keyword and the same now": true of the twin, not of the
program, which was right on master when it rescued the class by its name.
(Rescued as `Exception`, `e.respond_to?(:message)` stays `true` on the tip:
`e_top_std__qx_respond`.)

Counts: 4 programs, 12 rows. 3 of the 111 programs of the main taken group
(`e_top_std__q_nil_frozen`, `__q_respond`, `__q_exception`) and
`e_chain2__q_respond`; gcc, and clang for the three and for the two smallest
above by hand. Repair: none of the piece's
own kind; these two faults of master's keyword classes are cured first, or
they are a cost said first with these three lines.

### C2-5 (rule a, loud: a program right on master is refused, or its C does not build). Seven class names

```ruby
module Lib
  Warning = Class.new(StandardError)
  def self.run
    raise Warning, "x"
  rescue Warning => e
    puts "got #{e.message}"
  end
end
Lib.run
```

CRuby `got x`. M84 `got x`. Base `got x` (stress unset and 2). Tip: refused,
`unsupported class name 'Warning': collides with the builtin module of that
name`. A library's own `Warning` or `Monitor` under its module is an
ordinary name.

Scan (names/run.rb): 254 names, each as `Lib::Name` and at top level, C
generated by c1 and the tip. Five names compile on the base, run right on
the base and on M84, and are refused on the tip, in both places (10
programs): **Warning, Monitor, Marshal, Errno, FileTest**. In my family 2
the same shows as `nm_Errno__r_own`, `nm_Marshal__r_own`,
`nm_Monitor__r_own`, `nm_Warning__r_own`: right to refused.

Cause, by reading: `cn_blockless_super` leaves a name alone when
`is_builtin_class_name`, `is_builtin_module_name` or
`is_builtin_exception_name` holds, and its comment says why ("a name a
builtin has is that builtin when written with `class`"). The class
declaration it turns the assignment into is refused on two more predicates,
`bc_builtin_module(leaf)` and `is_untabled_native_name(leaf)`
(src/analyze_scope.c, the three "collides with the builtin" refusals and
"is not a class (TypeError)"). Repair: test the name with those two as well;
then the five stay the call they were.

Two more names are worse than refused: the tip's C does not build.

```ruby
module Lib
  Addrinfo = Class.new(StandardError)
  def self.run
    raise Addrinfo, "x"
  rescue Addrinfo => e
    puts "got #{e.message}"
  end
end
Lib.run
```

CRuby `got x`. M84 `got x`. Base `got x` (gcc and clang, stress unset and
2). Tip: the C compiler stops, gcc with `conflicting types for
'sp_Addrinfo'; have 'sp_Exception'`, clang with `typedef redefinition with
different types`. The same for **SumState** (a struct of the runtime's;
found by scanning the 38 struct type names of the runtime not in my list,
names/rtscan.rb: 37 are right on the tip, SumState does not build). Master
has the same C error for the keyword class of either name (side find S14):
the collision refusal does not know these two. For these two the piece has
to keep its own list, or decline any name for which the runtime has a
`sp_Name` type.

The five refused names are the narrow stated-cost shape (right by accident,
becomes loud), but the cost is not stated, and the repair is three words.
The two that do not build are not that shape: a C compiler error is not a
refusal.

The other direction is fine: 12 names of bundled libraries (JSON, CSV, ERB,
Digest, Base64, Benchmark, OptionParser, Pathname, SecureRandom, StringIO,
StringScanner, Tempfile) were refused on the base ("is provided by the
bundled ... library") and are right on the tip (built with the tip and run
in both places, gcc: 24 of 24 print what CRuby prints). Of the 254 names the tip
takes 159 (its C differs from the base's) and leaves 78 (the builtin class,
module and exception names, C byte-identical); the 159 were each built with
the tip (gcc) in the `Lib::Name` form and run: 157 print what CRuby prints,
`Addrinfo` does not build, and `Set` raises TypeError on M84, the base and
the tip alike.

### C2-6 (rule b, reached through master's faults; twin passes; not named in the body)

All loud on the base (NameError, an uncaught exception, or refused), silently wrong on the tip, and
the tip's C is the base's C for the keyword twin, byte for byte; half 1 by
script too.

| program | CRuby | base | tip = twin on base |
|---|---|---|---|
| `class Par; class BaseErr < ArgumentError; end; end` / `class BaseErr < StandardError; end` / `class Svc < Par; MyErr = Class.new(BaseErr); end` / `p Svc::MyErr.superclass` | `Par::BaseErr` | NameError | `BaseErr` |
| the same with `include Errs` in `Svc` and `Errs::BaseErr` | `Errs::BaseErr` | NameError | `BaseErr` |
| `class BaseErr < StandardError; end` / `module App; MyErr = Class.new(BaseErr); class BaseErr < ArgumentError; end; end` / `p App::MyErr.superclass` | `BaseErr` | NameError | `App::BaseErr` |
| `class Base; def self.inherited(k); puts "inherited #{k.name.inspect}"; super; end; end` / `Sub = Class.new(Base)` / `p Sub.name` | `inherited nil`, `"Sub"` | NameError | `"Sub"` |
| `def Class.new(*a) = 42` / `MyErr = Class.new(StandardError)` / `p MyErr` | `42` | NameError | `MyErr` |
| `MyErr = Class.new(SignalException)` / `begin; raise MyErr, "x"; rescue SignalException => e; puts "got #{e.message} #{e.class}"; end` (the same with `UncaughtThrowError`) | ArgumentError, exit 1 (the parent's own `new` refuses the argument) | `x (MyErr)` uncaught, exit 1 | `got x MyErr`, exit 0 |

The first three are the piece's own third condition failing to settle the
text: "Base is a class declared before it in an enclosing body" holds for
the top-level `BaseErr`, and the name means another class (one inherited
through the superclass, one through an included module, one declared later
in the nearer body). Master is wrong in the same way for the keyword class,
so the twin passes; the body's list of faults reached ("Not here either")
does not name them. The third is cheap to decline (a nearer enclosing body
declares the parent's name after the assignment).

In the fourth and fifth the keyword twin is not the same program in CRuby (CRuby
prints `inherited "Sub"` for the twin, and `MyErr` for the twin of the last),
so the sentence "taken only where the text settles that the two are the
same program" is not true of them. The piece checks for a `Class` the
program declares, not for a singleton method on `Class`, nor for an
`inherited` hook on the parent. Low weight; they are loud on the base. The
sixth is master's fault for a keyword subclass of those two builtins (side
find S17), reached; of the 36 builtin exception parents run with this rescue shape
these two are the only ones that go from loud to silently wrong.

### C2-7 (text). Body 2, title 2 and commit message 2, sentence by sentence

Read: `texts/title-2.txt`, `texts/body-2.md`, `texts/commit-message-2-v2.txt`.

1. **The cost is not first.** Body 2 opens with the fix; the right-to-wrong
   paragraph is the fifth block (line 33). The class "with a stated cost"
   wants it first. (And by section 2 it is not a cost to state.)
2. **"Not here: a method can be called above its `def`, as with any class."**
   (body line 33, message line 30.) Reads as a thing left unfixed. What
   happens is that a program right on master prints something else. "As
   with any class" is true of Spinel's keyword classes and is the point to
   say plainly: Spinel defines classes and methods before the program runs,
   and the assignment now does too.
3. **"CRuby prints `not yet`, `early` being undefined there. Master printed
   `not yet` too, for the NameError of `Err`; it now prints `there`, which is
   what master prints with `class Err < StandardError; end` on that line,
   from the same C."** True, measured (C2-1a; C byte-equal). It covers one
   shape of five (section 2).
4. **"Not here either, wrong on master for a class written with the keyword
   and the same now, with the same C: `e.respond_to?(:message)` on an
   instance of the program's own exception class, ..."** (five things).
   Run with the builder's own programs for four of them (bk5/): `e =
   MyErr.new("q")` then `e.respond_to?(:message)`, and `raise made` then
   `e.equal?(made)` under `rescue StandardError`, are loud on the base
   (NameError) and silently wrong on the tip; `e.class.superclass ==
   BaseErr` is refused on the base and silently wrong on the tip; the
   subclass with `initialize` and another method is refused on the base and,
   on the tip, raises NoMethodError and aborts at stress 2. All four with
   the twin's C, byte for byte. The fifth ("a rescue arm for a class with a
   method of its own asked `is_a?` of a subclass") I did not reproduce with
   the two programs of the builder's family I tried (both right on the tip);
   not pursued. Three things are wrong with the sentence: (i) it is not true
   of the program for the first item when the class is rescued by its own
   name (C2-4: right on master, wrong now); (ii) the last item is not
   "wrong ... and the same": a compile-time refusal becomes a raise, and an
   abort at stress 2; (iii) the list leaves out what I found reached in the
   same way: the three parent-name rows of C2-6, `e.class <=
   StandardError` printing `nil`, and `e.class == o.class` printing `false`
   at stress 2 (side finds S5, S10).
5. **"The assignment is now the class `class Err < StandardError; end`
   defines, and the program compiles to the C that declaration compiles
   to."** Measured over 703 programs whose C the tip changed and that
   have a keyword twin: byte-equal for 687; the other 16
   differ only in node numbers inside generated names (`__bpN`,
   `lv___destr_N_0`), because the assignment and the declaration do not have
   the same number of nodes (maskcheck.rb: 0 lines differ once those numbers
   are masked). "The C that declaration compiles to, node numbers in
   generated names aside" would be exact.
6. **"It is taken only where the text settles that the two are the same
   program: ..."** The three conditions match `cn_blockless_super` (by
   reading). Two more conditions are in the code and not in the text: the
   name is no builtin class, module or exception name, and the program
   declares no `Class` of its own. And the text does not settle it in the
   first five rows of C2-6.
7. **"Any other blockless `Class.new` is the call it was and compiles as
   before: in a condition, a block or a `begin`, assigned twice, read first,
   or given a module, a builtin value class, a Struct, a path or an
   expression as parent."** Measured on 284 position programs and 60
   named-before programs of mine (gcc): the C of c1 and of the tip is byte
   for byte the same for 236 and 40 of them, every shape the sentence names
   among them. One shape the sentence says is left is taken:
   `MyErr = Class.new(StandardError) unless defined?(MyErr)` (a condition;
   right before and after). Also taken, right before and after or refused
   before and right after, and not said: `Class.new StandardError`,
   `(Class.new(StandardError))`, `Class::new(...)`, `::Class.new(...)`,
   `Class&.new(...)`, `Class.send(:new, StandardError)`,
   `Class.new(StandardError, &nil)`, a rooted parent `Class.new(::Base)`
   (the sentence says "a path"; `A::Base` is left), and the bare
   `Pt = Class.new` (the
   commit message names that one; the title, the body and
   docs/limitations.md write `Class.new(Base)` only).
8. **"`Err.new` raised NameError"**, and in the message **"and so did Pt.new
   after `Pt = Class.new`"**: true on M84, both run.
9. **"CRuby prints `got x`; Spinel died with `x (Err)`, uncaught."** True on
   M84 and c1. `spinel diff` on the reproducer: M84 and c1 report
   `exception-diff`, the tip reports `same`. Neither body carries that
   report.
10. **The gate block** is the template's placeholder ("paste the Tests:,
    scale-test and gate: lines here") in both bodies. To be filled at
    opening, from a run on the branch merged with the then-current master.
11. **"Depends on"** is in words, with the title of commit 1's pull request.
    Good. Body 1's line is the template's bare "Depends on: #": write
    "nothing" there.
12. No "#" followed by digits, no model name, no link in the seven files.
    Each commit message ends with the one trailer.
13. **docs/limitations.md.** The new text is appended to the row
    "`Class.new(parent) { ... }` (runtime class) | unsupported". It does not
    say that the class exists from the start of the program (C2-1, C2-2),
    which is the limitation a reader of that file needs; it says "Any other
    blockless one defines no class", while `Class.new(Hash)` and
    `Class.new(Array)` without a block are refused by name (two rows
    below); and the row's own "unsupported" for the block form is stale on
    M84 (the builder's side find; not this piece's to fix).

The fork pull request's present body (superseded by the handoff texts) still
has a project link on its second line and a "Generated by" footer with a
session link at its end; neither may reach the upstream text.

### C2-8 (cost). Compile time

`spinel -c`, CPU seconds, M84-based trees, this machine under load:

| program | base (c1) | tip | keyword twin on base |
|---|---|---|---|
| 200 assignments `E0 = Class.new(StandardError)` ... | 0.02 | 0.03 | |
| 2,000 assignments | 0.21 | 0.95 | 0.15 |
| a chain 200 deep (`E1 = Class.new(E0)` ...) | | 0.28 | |
| a chain 2,000 deep | 0.21 | 69.29 | 70.91 |

The walk is quadratic in the number of assignments (`cn_count_decls` scans
every node for each one, `cn_names_const` rescans the statements before):
+0.74 s for 2,000 flat assignments, which the keyword form does not pay. The
70 s of the deep chain is master's own cost for a keyword chain that deep,
not the piece's. The tip's C for the 2,000 assignments is the base's C for
the 2,000 declarations, but for the file name in `#line`. Acceptable; one
line in the body would do.

### C2-9. What holds

- The added test `test/class_new_no_block_named.rb` fails on M84 and on c1
  (exit 1 at the first raise, 13 lines off) and passes on the tip: gcc and
  clang, plain and `--share-strings`, stress unset/1/2, 0 lines off. Its
  `.expected` is what CRuby 3.3.6 prints.
- Function sizes by hand (fsize.rb): new `cn_count_decls` 10 lines,
  `cn_names_const` 16, `cn_class_before` 9, `cn_blockless_super` 42,
  `cn_blockless_walk` 37; `desugar_class_new_blocks` 152 to 153. No function
  over 1,000 lines grows.
- `ruby tools/gate.rb check` on the commit staged over c1: exit 0 (it says
  it has no Ruby 4.0 here and does not compare `.expected` with CRuby).
- New crash rows (a signal, a timeout or an exit status of 128 or more
  where the base was refused or raised): 0 in every family.

## 4. Findings, commit 1 (base M84; piece = c1)

### C1-1 (rule a, silent; two of master's faults cancelling). A class that defines the predicate itself

```ruby
class MyErr < StandardError
  def is_a?(k) = false
end
e = begin; raise MyErr, "a"; rescue => x; x; end
p [e, 3].map { |v| v.is_a?(MyErr) }
```

CRuby `[false, false]`. M84 `[false, false]`. c1 `[true, false]`. gcc and
clang, stress unset and 2.

On master two faults cancel: a method named `is_a?` of the program's own is
never called through a boxed receiver, and the class-id test missed a raised
exception. The piece cures the second and the first shows. By the rules that
is not a reached case: the other fault is cured first as its own piece, or
the name arm is not emitted where the program defines the predicate asked
(`is_a?`, `kind_of?`, `instance_of?`; `===` on the class for `when`).
In family 1 it is 8 of the 18 `override_isa` programs, 24 rows (gcc; the
smallest above with clang too): `is_a?`, `instance_of?`, `is_a?` of a
subclass, and the narrowed use, for an exception raised from the class and
for one made then raised. It is the only rule (a) family of commit 1. A contrived program; I report it because rule (a) has no
exception for contrived ones, and leave the weight to the coordinator.

### C1-2 (cost, not stated). Every test of a boxed raised exception against an exception class of the program's own walks names

callgrind, instructions (Ir), gcc, M84 against c1. The loop runs 200,000
times over an Array of 10 values, 3 of them raised and rescued exceptions
(one `MyErr`, one of another class of the program's, one `KeyError`):

| the test in the loop | M84 | c1 |
|---|---|---|
| `x.is_a?(MyErr)`, MyErr an exception class | 30,488,534 | 4,392,676,349 |
| `case x when MyErr` | 35,088,540 | 4,396,276,342 |
| `x.is_a?(MyErr)`, no raised exception among the values | 30,677,279 | 45,477,289 |
| `x.is_a?(Plain)`, Plain no exception | 30,688,547 | 30,688,547 (C byte-identical) |
| `x.is_a?(KeyError)` (master's arm for a builtin exception class, for scale) | 8,074,292,684 | 8,074,292,698 |

That is about 7,270 instructions for each test of a boxed raised exception
(600,000 such tests), spent in `sp_exc_is_a` and the `strcmp` walk of
`sp_exc_parent_of_name`; and 7.4 instructions more for each test of any
other boxed value. Two of the three exceptions in the Array are of other
classes: master answered false for them, rightly, for a few instructions,
and c1 answers false for them after the walk. It is the cost master already
pays for a builtin exception class (last row), so it is the house price, but
body 1 says nothing of it and "a test for a class that is no exception emits
the same C" is the only cost sentence. One sentence with the two numbers
would do.

### C1-3 (text). Body 1, title 1 and commit message 1, sentence by sentence

Read: `texts/title-1.txt`, `texts/body-1.md`, `texts/commit-message-1.txt`.

1. **"... answered false to `is_a?`, `kind_of?` and `instance_of?` for that
   class, and never matched a `when` arm naming it."** True for the class
   written as a bare name. `x.is_a?(A::Err)` written as a path was already
   right on M84 (probe d2); the path `when A::Err` was wrong and is right
   now. "for that class written by its name" would be exact.
2. The reproducer: M84 `[false]`, c1 `[true]`, CRuby `[true]`. `spinel diff`:
   M84 `output-diff -[true] +[false]`, c1 `same`. True.
3. **"`emit_poly_isa_test` and the `when` class test compare the boxed
   value's class id ..."** to **"... as the arm for a builtin exception class
   does."** True by reading (`emit_poly_exc_name_arm`, called from
   `emit_poly_isa_test` and `emit_poly_class_when`).
4. **"The class-id arm is as it was: an exception never raised ... answers
   as before, and a test for a class that is no exception emits the same
   C."** True: the 50 programs of family 1 that ask a class that is
   no exception compile to byte-identical C on M84 and c1, and callgrind
   counts the same instructions (C1-2); a never-raised `MyErr.new` in the
   Array answers as before.
5. **"Left alone: `x.instance_of?(k)` with the class in a variable or
   written as a path ... is still false ..."** True (probe d2: false on M84
   and on c1).
6. Not said: the cost (C1-2); that a `def self.===` on the exception class
   is not consulted by `when` (wrong on M84 and on c1, probe d4); that a
   module the exception class includes still answers false
   (`x.is_a?(Tagged)` and `when Tagged` for a boxed raised exception: false
   on M84 and on c1, CRuby true; side find S16); C1-1.
7. The gate block is the template's placeholder; "Depends on: #" is the
   template's line (write "nothing"). No "#" with digits, no model name, no
   link. The commit message ends with the one trailer.

### C1-4. What holds

- Family 1 (gen1.rb; M84 against c1; gcc; stress unset/1/2): 233 programs,
  699 rows. C changed for 143, byte-identical for 90 (the 50 non-exception
  programs among them). Wrong on M84 and right on c1: 119 programs, 356
  rows. Right on both with new C: 7 programs. Right on M84 and wrong on c1:
  8 programs, 24 rows, all C1-1. Wrong on both with new C: 9 programs (7
  `override_eqq`, a `def self.===` on the class that `when` does not
  consult; one user `is_a?` on a never-raised exception; and
  `ask_module__raise_class__array_push__when`, where `when Tagged`, a module
  the class includes, still misses while the two class arms beside it are
  cured). One of the 119 (`plain__raise_class__array_push__if_then_deep`)
  is right at stress unset and 1 and wrong at stress 2: `x.class.name`
  inside the branch master never entered prints freed bytes (side find S2).
  Loud or refused to silently wrong: 0. New crashes: 0. The other 358
  programs of the family were not run (section 8).
- Of the 14 groups only sampled (3 programs each, 42: `is_a?`, `when` and
  `instance_of?` of an exception raised from the class and pushed on an
  Array): 34 have new C, 33 of them wrong on M84 and right on c1 and the
  34th the `ask_module` one above; 8 have byte-identical C (the test names
  a builtin parent, a module or a path, which the piece leaves alone), of
  which five were run by hand on M84: right for four, wrong for
  `x.is_a?(Tagged)` on M84 and on c1.
- Namespaces, by hand: two exception classes with the same leaf name in two
  modules, a class of the program's named `KeyError` under a module beside
  the builtin, and a top-level `Error` beside `App::Error`, asked by
  `is_a?` and by `when`: c1 answers as CRuby in all (probes k1 to k4); M84
  was wrong or right by missing everything.
- The narrowed use after the test (`x.code`, `x.hint` on a raised exception
  with instance variables and methods) works on c1.
- The added test `test/rescued_own_exception_boxed_class.rb`: M84 is off on
  5 of 7 lines; c1 and the tip are off on 0: gcc and clang, plain and
  `--share-strings`, stress unset/1/2. Its `.expected` is what CRuby 3.3.6
  prints.
- Function sizes by hand: new `emit_poly_exc_name_arm` 8 lines,
  `emit_poly_isa_test` 85 to 87, `emit_poly_class_when` 80 to 83.
- `ruby tools/gate.rb check` on the commit staged over M84: exit 0 (no Ruby
  4.0 here, so `.expected` is not compared with CRuby by the tool).

## 5. Counts

### 5.1 Commit 2

Classes against CRuby 3.3.6: right; silently wrong; loud (a raise, a crash,
a timeout, or other stdout before a raise CRuby also makes); refused or not
built. A program is counted under its worst row.

Stated-cost group (gen2.rb: sc_, refl_): 243 programs, 1458 rows (gcc and clang; stress unset, 1, 2); base c1 (M84 + commit 1), piece tip
| change | programs | rows |
|---|---|---|
| right -> silently wrong (rule a) | 92 | 552 |
| right -> refused or not built (rule a) | 0 | 0 |
| right -> loud (rule a) | 0 | 0 |
| loud or refused -> silently wrong (rule b; twin test) | 1 | 6 |
| wrong, loud or refused -> right | 12 | 72 |
| right -> right, C changed | 9 | 54 |
| not right -> not right, C changed | 125 | 750 |
| unchanged (C byte-identical, or the same refusal) | 4 | 24 |

Specials (gen3.rb): 34 programs, 204 rows (gcc and clang; stress unset, 1, 2); base c1 (M84 + commit 1), piece tip
| change | programs | rows |
|---|---|---|
| right -> silently wrong (rule a) | 13 | 72 |
| right -> refused or not built (rule a) | 0 | 0 |
| right -> loud (rule a) | 1 | 4 |
| loud or refused -> silently wrong (rule b; twin test) | 4 | 28 |
| wrong, loud or refused -> right | 6 | 36 |
| right -> right, C changed | 2 | 10 |
| not right -> not right, C changed | 3 | 24 |
| unchanged (C byte-identical, or the same refusal) | 5 | 30 |

The rest of family 2 (gen2.rb; the 18 refl_ programs of the group above are in it again): 786 programs, 2358 rows (gcc; stress unset, 1, 2); base c1 (M84 + commit 1), piece tip
| change | programs | rows |
|---|---|---|
| right -> silently wrong (rule a) | 11 | 31 |
| right -> refused or not built (rule a) | 4 | 12 |
| right -> loud (rule a) | 1 | 1 |
| loud or refused -> silently wrong (rule b; twin test) | 11 | 31 |
| wrong, loud or refused -> right | 217 | 653 |
| right -> right, C changed | 194 | 580 |
| not right -> not right, C changed | 29 | 93 |
| unchanged (C byte-identical, or the same refusal) | 319 | 957 |

The builder's 13 (base M84 itself): 13 programs, 78 rows (gcc and clang; stress unset, 1, 2); base M84, piece tip
| change | programs | rows |
|---|---|---|
| right -> silently wrong (rule a) | 12 | 70 |
| right -> refused or not built (rule a) | 0 | 0 |
| right -> loud (rule a) | 1 | 6 |
| loud or refused -> silently wrong (rule b; twin test) | 0 | 0 |
| wrong, loud or refused -> right | 0 | 0 |
| right -> right, C changed | 0 | 0 |
| not right -> not right, C changed | 0 | 2 |
| unchanged (C byte-identical, or the same refusal) | 0 | 0 |

Right on the base and not right on the tip, distinct programs, by finding:

| finding | programs | of which |
|---|---|---|
| C2-1 later method or class | 111 | 90 stated-cost group, 8 specials, the builder's 13 |
| C2-2 reflection before the assignment | 7 | 2 stated-cost group, 2 specials, 3 rest of family 2 |
| C2-3 first class | 6 | 4 specials, 2 rest of family 2 |
| C2-4 identity and `respond_to?` | 4 | rest of family 2 (and two hand probes) |
| C2-5 names | 4 in family 2 (Errno, Marshal, Monitor, Warning at top level); in the name scan 5 names refused in both places and 2 names not built | |
| discounted: a race in my own program (`e_top_std__r_thread_join`, 1 row) | 1 | section 6 |

Wrong, loud or refused on the base and right on the tip: 12 + 6 + 217
programs in the three families of mine (the piece's gain). The builder's
count of the gain over its own family (2,361 programs of 5,449) was not
remeasured.

### 5.2 Commit 1

Family 1 (gen1.rb): 233 programs, 699 rows (gcc; stress unset, 1, 2); base M84, piece c1
| change | programs | rows |
|---|---|---|
| right -> silently wrong (rule a) | 8 | 24 |
| right -> refused or not built (rule a) | 0 | 0 |
| right -> loud (rule a) | 0 | 0 |
| loud or refused -> silently wrong (rule b; twin test) | 0 | 0 |
| wrong, loud or refused -> right | 119 | 356 |
| right -> right, C changed | 7 | 21 |
| not right -> not right, C changed | 9 | 28 |
| unchanged (C byte-identical, or the same refusal) | 90 | 270 |

The 8 are finding C1-1. Programs asking a class that is no exception: 50 of
50 byte-identical C.


## 6. The twin test (rule b), commit 2

The builder's claim, in the superseded fork body, is over the builder's
family of 5,449 programs, which I regenerated and did not rerun in full: 105
programs go from a raise or a refusal to a silent wrong answer with the
keyword twin's C, 37 go from refused to a raise or (stress 2) a crash with
the twin's C, 0 with C of the piece's own. Measured in my families:

**Half 2 (the piece's C for the program is the base's C for the twin).**
Over the 703 distinct programs of my three families whose C the tip changed
and for which a keyword twin exists (twinstats.rb): byte-equal for 687; the
other 16 differ only in node numbers inside generated names (`__bpN`,
`__sg_N`, and for one `lv___destr_N_0`, which the builder's mask does not
name; 0 lines differ after masking). No program has C of the piece's own.
(18 more changed programs have no twin in my generator: the spellings of
C2-7 item 7, which I had expected to be left; they are right on the tip.)

**Rule (b) candidates (loud or refused on the base, silently wrong on the
tip).** 17 distinct programs of mine: 1 in the stated-cost group
(`refl_const_missing`), 6 in the specials, 11 in the rest of family
2 (the three parent-name programs of C2-6, `refl_const_missing` again,
`e_top_std__q_class_cmp`, `__q_equal_other`, `__r_new_queries`, the two
`p_inherited` programs and the two builtin parents of the last row of
C2-6), and 3 of the builder's five (section 3, C2-7 item 4). The twin test passes for every one:
half 2 byte-equal for all of them. Half 1 was run on its own (twinrun.rb:
the twin built by the base with gcc and clang and run at the three stress
levels, its six rows compared with the tip's six rows for the program) for
25 programs of mine, every rule (b) candidate of the specials and of the
rest of family 2 found before the last sample (the four the sample added
were not) and the smallest rule (a) programs among them, and for the
builder's 13 on M84: equal on 6 of 6 rows for all 38 (a 26th of mine, the racy
program discounted below, differs from run to run). For the other
programs the harness builds one binary where the C is byte-equal, so half
1 follows from half 2 there. The 20 flagged programs of the rest of family
2 were run with clang too (out/f2g-clang.jsonl): the same classes as with
gcc.

**The builder's family of 58** (M84 against the tip, gcc, three stress
levels): 34 rule (b) candidates (31 loud and 3 refused on M84, silently
wrong on the tip). Against the twin compiled by M84 the tip's C is
byte-equal for 33. The 34th, `kept_exceptions`, ends with
`kept.all? { |e| e.is_a?(MyErr) }`, where commit 1 changes the twin's C, so
the twin of the stack is c1's: against it the tip's C differs in node
numbers only (`__bp29` / `__bp27`), and half 1 by hand is equal at the three
stress levels. Passed: 34 of 34.

**Refused on the base, a raise or a crash on the tip** (not a rule (b) row;
the builder's "37"): `e_top_std__r_sub_kw_body` and the builder's
`sub_keyword_body` are refused at compile time on the base and M84
("unsupported call ... `extra`"), and on the tip raise NoMethodError at
stress unset and 1 and abort (signal 6) at stress 2, as the keyword twin
does on the base, from the same C. A refusal that becomes an abort under
stress is worth a plain sentence in the body; the two rules do not forbid
it.

**New crashes of the piece's own:** none.

One row I discount: `e_top_std__r_thread_join` shows right on the base and
an abort on the tip at one stress level in the harness. By hand, five runs a
tree and compiler: the base and the tip each print, from run to run, either
`got in thread MyErr` or the thread's own report ("terminated with
exception"). My program has a race (the thread can raise before
`report_on_exception = false` runs). Not a finding.

## 7. The tools

Trees c1 and tip are on M84; tip26 is on M26. gcc 13.3.0, clang 18.1.3,
x86_64 Linux.

| tool | on | result |
|---|---|---|
| the two added tests; gcc and clang, plain and `--share-strings`, stress unset/1/2 | M84, c1, tip | test 1 fails on M84 and passes on c1 and on the tip; test 2 fails on M84 and on c1 (exit 1) and passes on the tip (out/tests.txt, 24 lines of 3 runs) |
| the same | M26, tip26 | both fail on M26, both pass on tip26 (out/tests26.txt; section 9) |
| the two `.expected` files against CRuby 3.3.6 | | equal |
| `make cident REF=26d456ec...` | tip26 against M26 | 6344 identical, 8 differ (4 the piece's, 4 the description line of my merge commit), 0 refusal changes (section 9) |
| `make cident` for each commit on M84 (c1 against M84; the tip against c1) | | **NOT COMPLETED.** Started twice: cut by the container restart, then stopped by me while it was still emitting the reference, at about 140 files a minute on the shared machine (1.5 hours a run). In its place: the two changed corpus files of the M26 run attributed by hand (`spinel -S --no-line-map` on M84, c1 and the tip: one existing file and one added test a commit). "No other corpus file changes" therefore rests on the M26 run alone |
| `tools/refusals.sh` | c1, tip | pass (530 records) on both (out/checks-c1.txt, out/checks-tip.txt) |
| `make reject-test` | c1, tip | pass on both |
| `make share-strings-test` | c1, tip | pass on both |
| `ruby tools/gate.rb check` | each commit staged over its base, in a scratch worktree | exit 0 for both; it says it has no Ruby 4.0 here |
| function sizes | by hand (fsize.rb) | no function over 1,000 lines grows (C2-9, C1-4) |
| `git diff --check` | both commits | exit 0 |
| `bin/spinel diff` on the two bodies' reproducers | M84, c1, tip | commit 1's: M84 `output-diff`, c1 `same`. Commit 2's: M84 and c1 `exception-diff`, the tip `same` |
| callgrind (commit 1), `spinel -c` CPU time (commit 2) | M84, c1, tip | C1-2, C2-8 |
| `make gate`, `make test`, the scale test | | **NOT RUN** on any tree (section 8) |

## 8. What was NOT run

Said plainly, so that nothing below is taken for measured:

1. **`make gate`, `make test`, the scale test: not run on any tree.** The
   whole corpus built and run is hours on this shared machine. What stands
   in their place: the two added tests and the two existing corpus tests
   whose C changes, run by hand (section 7), and the one cident on M26.
2. **`make cident` for each commit on M84: not completed** (section 7). The
   only finished cident is the tip of the stack against M26.
3. **Family 2 (commit 2): 1,011 of 1,458 programs run, 447 not.** Whole: the
   stated-cost group (`sc_`, `refl_`; 243) and the groups `pos_`, `pre_`,
   `nm_`, `scu_`, `bp_`, `e_top_std`, `e_chain2`, `p_user`, `p_bare` (680).
   Sampled, 88 programs of 21 groups: `b_` 50 of 144 (every `r_parent`),
   and 1 to 3 programs each of `e_after_code`, `e_first_struct`,
   `e_in_class`, `e_in_module`, `e_nested`, `e_par_init`, `e_par_ivar`,
   `e_par_meth`, `e_siblings`, `e_top_arg`, `e_user_par`, `p_abstract`,
   `p_arr_sub`, `p_cmp`, `p_in_mod`, `p_inherited`, `p_kw_struct`,
   `p_object`, `p_req_arg`, `p_two`. Not run at all: `e_top_exc` (14),
   `p_basic` (2). The sample found no new rule (a) program and four more
   rule (b) candidates, all passing (C2-6). Programs whose C is
   byte-identical on c1 and on the tip (319 of the 786 of the rest of the
   family) were not built or run: nothing of theirs can change.
4. **Family 1 (commit 1): 233 of 591 programs run, 358 not.** Whole: `nonexc`,
   `override_isa`, `override_eqq`, `two_ns`, `in_class` (122). `plain` 69 of
   187. Three programs each of `state`, `state_nosuper`, `method`,
   `blockform`, `five_levels`, `exception_parent`, `builtin_parent`,
   `module_included`, `ask_module`, `reopened_std`, `first_struct`,
   `ask_builtin_parent`, `two_ns_rev`, `ns_builtin_leaf`. Programs whose C
   is byte-identical on M84 and c1 were not built or run by the harness
   (90 of the 233; five of them run by hand).
5. **clang** only for the stated-cost group, the specials, the builder's 13,
   the 20 flagged programs of the rest of family 2, the added tests and the
   hand probes. Everything else is gcc only: the rest of family 2, family
   1, the builder's 58, the name scan.
6. **`--share-strings`** only for the two added tests and
   `make share-strings-test`. No family was run with it.
7. **The name scan** was run at stress unset only (Warning, Addrinfo and
   SumState at stress 2 as well), gcc; the two that do not build with clang
   too.
8. **The builder's family of 5,449**: regenerated (the count agrees), not
   rerun. Run from it: the 13, the five shapes of body 2 (7 programs) and
   the 58 of `cost_later_def_called_first`. The builder's totals (2,361
   cured, 105 and 37 reached with the twin's C, 0 with C of its own) were
   not remeasured.
9. **The corpus**: my scan for blockless `Class.new` in the corpus
   (corpus.rb) was not run. The cident on M26 answers the same question for
   the C: one existing corpus file changes with commit 2, and it passes.
10. **Half 1 of the twin test on its own** for 38 programs and one more by
    hand (`kept_exceptions`). For the rest it follows from half 2: where
    the C is byte-equal the harness builds one binary for both.
11. **Commit 1 alone on M26: not built.** Nothing was built on
    5390d3002886 (two `git merge-tree` lines only, section 9).
12. **CRuby 4.0 is not on this machine.** Every "CRuby prints" is CRuby
    3.3.6 with `--enable-frozen-string-literal`. I know of no difference
    between the two for these programs; that is not measured.
13. No run under a sanitizer or valgrind's memcheck; no run on another
    system than this x86_64 Linux; no run-time cost measured for commit 2
    (its C is the keyword twin's, so by half 2 it has none of its own:
    inferred, not measured).
14. Findings were minimised by hand to the programs shown and not further;
    the side finds were not minimised or chased.

## 9. On the new master M26 (26d456ec1035)

Merged with `git merge-tree --write-tree`, both clean:

| | merged tree | built |
|---|---|---|
| commit 1 (798cc501e4fa) into M26 | 3a0cd939f03e5976027d65c7b1a11f1941cd6302 | no |
| the tip (9ac6f96abcbc) into M26 | 57ed9c6bb8e10669dd87ad8351782f3d5fa28f15 | yes: `p219/tip-on-26d456ec-219`, local merge commit ba1ae8a3533a, `make` exit 0 ("tip26") |

**The piece's own tests on M26** (out/tests26.txt; M26 itself is the
coordinator's build at /home/claude/r8/master-26d456ec-tree; gcc and clang,
plain and `--share-strings`, stress unset/1/2: 4 builds, 12 runs a test and
tree):

| test | M26 | tip26 |
|---|---|---|
| test/rescued_own_exception_boxed_class.rb | fails: 5 of 7 lines off, all 12 runs | passes: 0 off, all 12 runs |
| test/class_new_no_block_named.rb | fails: exit 1, 13 lines off, all 12 runs | passes: 0 off, all 12 runs |

Commit 1 alone on M26 was not built, so "the second test fails on M26 +
commit 1" is measured on M84 only (it does fail on c1).

**One cident on the tip of the stack**, `CIDENT_JOBS=1 make cident
REF=26d456ec103513fd8d7d9367dbbc9060854f3116` in tip26
(out/cident-tip26.txt):

```
cident: 6344 identical, 8 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against 26d456ec1)
```

The 8, read one by one in the tool's diffs:

- 4 are the piece's: the two added tests (the reference compiles this
  tree's corpus, so they are compared; their C differs as it must),
  `test/each_with_object_seed_widens.rb` (commit 1: its `x.is_a?(AppError)`
  of a boxed value gets the name arm) and `test/class_new_block_named.rb`
  (commit 2: its line 4 is `Err = Class.new(StandardError)`). By hand on
  M84 (`spinel -S --no-line-map` on M84, c1 and the tip): commit 1 changes
  the C of the first of these two and of its own test and of nothing else
  among the four, commit 2 of the second and of its own test. Both existing
  tests still pass on the tip and on tip26: gcc and clang, stress unset/1/2,
  0 lines off (out/tests-existing.txt). That is what the builder claimed on
  its older master: two files a commit.
- 4 differ in one line only, the `sp_str_ruby_description` string, which
  names the compiler's own commit: "unreleased revision 26d456ec" against
  "unreleased revision ba1ae8a3" (my local merge commit):
  `test/frozen_chilled_builtin_strings.rb`,
  `test/object_scoped_ruby_constants.rb`,
  `test/ruby_description_shape.rb`,
  `test/symbol_id2name_ruby_desc_minmax.rb`. Not the piece's. The tool
  normalises that line only in its dated form (side find S15).

So on M26 the stack changes the generated C of 4 corpus programs of 6,352,
2 of them its own tests, and no refusal. The run was made twice: the first
was cut by the container restart after its reference cache was complete;
the second reused the cache.

**The newest master, 5390d3002886** (ref `upstream/master-5390`): nothing
built on it. One line a commit:

```
git merge-tree --write-tree upstream/master-5390 798cc501e4fa  ->  rc 0, tree 13535b72563d3a3d0dadd5308eada561cd990023 (clean)
git merge-tree --write-tree upstream/master-5390 9ac6f96abcbc  ->  rc 0, tree 832249b893711db3c729f89a51f5754d2d0f9f6c (clean)
```

(Between M26 and that master `src/analyze_desugar.c` and
`src/codegen_call.c` changed upstream; the text merges clean, and whether
the result builds and passes was not run.)

## 10. Side finds on master, for the miner

Seen on M84, or on c1 for a keyword twin where commit 1 does not touch the
program (no `is_a?` or `when` on a boxed value). Not minimised further, not
chased.

Run on M84 itself, keyword spelling, gcc:

- S1. `class MyErr < StandardError; end` / `begin; raise MyErr, "x"; rescue MyErr => e; p e.equal?(e); end`
  prints `false` (CRuby `true`). `e.exception.equal?(e)` the same. Silent.
- S2. `puts e.class.name` for a rescued exception of a keyword class, and
  `k = e.class; p k.new("z").class` for a rescued builtin exception, print
  freed bytes (`\xDB...`) at `SPINEL_GC_STRESS=2`; the second aborts in one
  shape. A class value held in a local is not rooted.
- S3. `e.class.new("z")` of a rescued builtin exception builds the
  program's first class (`class MyErr < StandardError; end` first, then
  `Integer("zz")` rescued as ArgumentError: `p e.class.new("z").class`
  prints `MyErr`). Silent. (The ground of the fork's class-id piece.)
- S4. `e.respond_to?(:message)` is `false` for a rescued exception of a
  keyword class. Silent.
- S5. `e.class <= StandardError` and `e.class < Exception` print `nil` for
  a keyword exception class (CRuby `true`); `e.class.superclass` prints
  `Object`. Silent.
- S6. `def self.inherited(k)` on a parent is never called for a keyword
  subclass. Silent.
- S7. A method `is_a?` (or `kind_of?`, `instance_of?`) the program defines
  is not called through a boxed receiver; `def self.===` on an exception
  class is not consulted by `when`. Silent.
- S8. The superclass name of a keyword class nested in `class Svc < Par`
  resolves to the top-level class of that name, not to `Par::BaseErr`
  inherited through `Par`; the same through an included module; and a class
  of that name declared later in the nearer body wins over the top-level
  one declared before. Silent.
- S9. `p StandardError.subclasses.size > 3` does not build: the generated C
  passes an int to `sp_PolyArray_length`.

- S16. A module included by an exception class of the program's own:
  `x.is_a?(Tagged)` and `when Tagged` answer false for a boxed raised
  exception of that class (CRuby true). Silent. (On M84 and on c1.)

- S17. `class MyErr < SignalException; end` / `raise MyErr, "x"` (and the
  same with `UncaughtThrowError`): CRuby raises ArgumentError from the
  parent's own `new`; master builds the exception and a `rescue
  SignalException` arm takes it. Silent. (The keyword twin on c1; M84 not
  rerun.)

Seen in passing in my families, on the base c1, not rerun on M84 alone:

- S10. `e.class == o.class` for two exceptions of one keyword class prints
  `true` at stress unset and 1 and `false` at stress 2.
- S11. `at_exit { p $!.class }` prints `NilClass` for an uncaught raise.
- S12. `require_relative` inside a method body is hoisted (the file's
  definitions exist before the method is called).
- S13. `Object.const_defined?("Name")` raises NoMethodError at run time.

Found by the name scan, run on M84, keyword spelling, gcc:

- S14. `module Lib; class Addrinfo < StandardError; end; end` (and the same
  with `SumState`) compiles to C that does not build: `conflicting types
  for 'sp_Addrinfo'; have 'sp_Exception'`. The "collides with the builtin"
  refusal does not know these two runtime type names.
- S15. `tools/cident.sh` normalises the RUBY_DESCRIPTION line only in its
  dated form; a compiler built from a commit that describes itself as
  "unreleased revision <sha>" makes four corpus programs differ from any
  reference of another commit (seen on M26).

## 11. Where things are

Everything is under /home/claude/r8/p219/ (nothing was written under
/mnt/project-files):

- generators: `gen1.rb` (commit 1), `gen2.rb` (commit 2), `gen3.rb`
  (specials), `names/run.rb`, `names/build.rb`; the builder's generator as
  regenerated: `bk-gen-class-new.rb`, `bkfam/`, its 13 in `bk13/`, its
  five shapes in `bk5/`, its cost family of 58 in `bk58/`;
- harness and tallies: `h219.rb`, `t219.rb`, `show.rb`, `flagged.rb`,
  `twinrun.rb`, `maskcheck.rb`, `cross.rb`, `mc1.rb`, `declist.rb`,
  `listcheck.rb`, `crtwin.rb`, `fsize.rb`, `sums.rb`, `counts.rb`,
  `twinstats.rb`, `groupcount.rb`, `bk58twin.rb`, `corpus.rb` (not run);
- results: `out/*.jsonl` (one line per program: CRuby, the C hash per tree,
  every run), `out/tally-*.txt`, `out/tests.txt`, `out/tests26.txt`,
  `out/cident-*.txt`, `out/checks-*.txt`, `names/names.tsv`,
  `names/build.tsv`;
- hand probes: `probe/` (`t.sh FILE [trees]`); cost: `cost/`, `bench/`;
- the texts read: `texts/`.

