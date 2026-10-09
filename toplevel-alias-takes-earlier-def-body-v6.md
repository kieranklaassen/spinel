<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def greet = "hello"
def shout = "HELLO"
p greet
alias greet shout
p greet
```

```
spinel diff: output-diff
  program: alias_over_def.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
 "hello"
-"HELLO"
+"hello"
```

A top-level `alias` is kept on the Toplevel pseudo-class, and `comp_method_index` consults it only when no method owns the name. Over a name a `def` holds, the alias is never read: every call reaches the `def`.

`rename_redefined_toplevel_defs` gives an earlier top-level `def` a private name where a later `def` of the name follows, and renames the calls that run between the two. `rename_aliased_toplevel_defs`, a pass of its own that runs after it, does the same where an alias follows. The `def` and the calls above the alias take the private name; no method owns the name any more, and the calls below resolve through the alias. The old body stays reachable where the program kept it (`alias saved greet` above the alias).

It costs nothing at run time: the calls are bound when the program is compiled. At compile time a program with no top-level alias pays one look over the statements of its top level, and one whose aliases give no name a `def` holds a lookup for each alias and each `def` there. Where an alias does give a `def`'s name the program is read once for the names it writes and the top level is walked once for all its aliases; each `def` then asks the one alias that gives its name, and a rename visits the statements that call the name. So the cost grows with the program and not with its square. Counted in instructions of `spinel -S` (callgrind), master then here, on programs of K one-line defs `f0`..., K more `g0`... and three calls:

```
      K          master            here    change
no alias
    500     325,911,669     325,905,944   -0.002%  same C
  1,000     890,564,201     890,557,535   -0.001%  same C
  2,000   2,635,453,706   2,635,450,955   -0.000%  same C
K aliases `alias hI gI` of fresh names
    500     466,765,197     467,138,330   +0.080%  same C
  1,000   1,295,776,719   1,297,134,781   +0.105%  same C
  2,000   3,724,120,525   3,720,465,502   -0.098%  same C
the same, one of them over a def (`alias f0 g0`)
    500     467,737,430     470,628,806   +0.618%  same C
  1,000   1,298,035,840   1,304,536,850   +0.501%  same C
  2,000   3,724,058,637   3,732,856,720   +0.236%  same C
K aliases `alias fI gI`, nothing calls an fI below
    500     451,867,326     454,778,962   +0.644%  same C
  1,000   1,230,018,382   1,234,836,475   +0.392%  same C
  2,000   3,551,625,277   3,563,410,814   +0.332%  same C
the same with `p fI` and `p :fI` below for each
    500   1,029,986,605   1,034,150,688   +0.404%  same C
  1,000   2,615,704,276   2,622,512,041   +0.260%  same C
  2,000   7,218,315,746   7,236,439,377   +0.251%  same C
the same with `p fI` below for each (cured)
    500     818,208,555     919,596,058  +12.391%  other C
  1,000   2,078,747,522   2,478,688,957  +19.240%  other C
  2,000   5,753,527,058   7,526,408,873  +30.814%  other C
the cured program written by hand: defs `fxI`, then `alias fI gI`, `p fI`
    500     914,474,652     914,638,998   +0.018%  same C
  1,000   2,474,204,861   2,474,091,081   -0.005%  same C
  2,000   7,605,025,951   7,605,849,857   +0.011%  same C
```

With no alias the look is 22 instructions a line by function (`redef_note_inside_names`, 22,195 on 1,001 lines); the whole counts come out a few thousand instructions below master's, which is the layout of the binary and not the look. Aliases of fresh names cost a lookup each, within 0.11% either way. In the next three shapes master compiles the same C and the program pays the read of its names and the one walk, 0.24% to 0.64%: with every alias over a `def`, about 4,800 to 5,900 instructions an alias, a share that falls as the program grows (0.64%, 0.39% and 0.33% at 500, 1,000 and 2,000). Where the change cures, the calls below go through the alias, and that is what costs: master pays the same for the program that says so in names of its own (the last shape), and against that one the cured program takes +5,121,406, +4,484,096 and -78,617,078 instructions (+0.56%, +0.18%, -1.03%).

The alias counts only where the rename is known to be right; every other program is compiled as it was. What the program says of the two names is read from the program as written, ahead of every desugar (`redef_note_inside_names`, `analyze_program`'s first step), because the desugars drop and rewrite the code the question is about: under `if RUBY_ENGINE == "ruby"` the arm CRuby runs is gone by the time the pass looks.

- Each of the two names is written only as a call with no receiver, in its `def` at the top level and in a top-level alias. There is no `def` of either anywhere else (in a class, under a condition, in a loop, a block, a `begin` or another `def`, on a receiver), no Symbol, String, variable or parameter of the name, and no target that calls it through no call (`for self.count in list` and `self.count += 1` reach `count=`). A `def` under an `if` may or may not have run when the alias does, and a Symbol is how a name reaches `define_method`, `attr_reader`, `undef`, `send` or `respond_to?`.
- Neither name is a method name of Object or of a core class, by the two tables master generates from CRuby with `tools/gen_method_names.rb` (`src/object_method_names.inc`, `src/core_method_names.inc`). With no receiver, `raise`, `exit` or `spawn` reaches the builtin once no method owns the name, whatever the program defines, and in a method the program adds to Array `count` is Array's.
- The program writes `__redef` in no name and no String, so the private name is one nothing in it can spell.
- Nothing in the program is named `include`, `prepend` or `extend`, or one of their hooks, as a call, a Symbol, a String or a `def`. A module mixed in can put a body of either name ahead of the top level's, and it need not be the program's text (`prepend Kernel`).
- No `respond_to?` asks about a name that is not written out: it answers from the defs and does not see an alias.
- The program names, makes and loads no method by something its text does not spell, anywhere: `send` or `method` handed a value, a block-pass of a value, `define_method` or an `attr` word with a name that is no literal, `eval` of text, `binding`, a file the compiler did not read. That is master's own answer (`g_written_by_value`, the walk behind `an_prog_never_gives`); it is read here and no line is added to it.
- The build is not a debug build (`--debug`, `-g`): its backtrace names a frame after the C function, and would show the private name where it showed the `def`'s. A later `def` of the name does show it there on master: `def f = raise("boom"); f; def f = 1` names the frame `f__redef1`; `--emit-rbs` and `--profile`'s symbol map name it too, and for a program this change cures they name `greet__redef1`.

Then by position, among the statements of the top level:

- the target is a `def` above the alias, and no alias above gives the target's name;
- no other `def` or alias gives the alias's name, and no alias below takes it as its old name (`alias third greet`);
- the `def`'s body asks neither `__method__` nor `__callee__`, by a call or by a Symbol handed on (`send(:__method__)`), which would answer the private name;
- nothing above the alias reaches the name past the rename: a method, class or module body that calls it, a call on a receiver (`self.greet`), or a call in a lambda, a `BEGIN` or `END` block or any block that is not known to have run when its call returns. Known are the blocks of `times` on an Integer literal and of `each`, `each_with_index` and `map` on an Array literal, in a program that defines no method of that name. Above the `def` itself a bare call counts too;
- a statement below the alias calls the name. An alias nothing calls afterwards takes nothing, and the program keeps the C it had.

Not in this change (each prints what it printed, unless said):

- An alias under a condition, in a loop or in a method, and a name defined again later or aliased twice.
- A program that writes either name anywhere else, whatever it does with it: a class with a method of that name, a `def` of it under a condition, `send(:greet)` below the alias, a hash key `greet:`, the String `"greet"`, a variable `greet`.
- A top-level method that has a builtin's name, aliased over or as the target: `def count`, `def first`, `def puts`.
- A program with an `include`, a `prepend` or an `extend` anywhere, whatever the module, and one with a site that names a method by a value anywhere, or that may load a file the compiler did not read.
- A debug build: `--debug` compiles every program as it did, so a program this change cures prints master's line there.
- A method or a class above the alias that calls the name: `def use = greet` above `alias greet shout`, called after it, still reaches the first body. The whole program is left as it was, the calls below the alias too.
- A block above the alias that can run after it: `at_exit { p greet }`, `END { p greet }`, `l = -> { greet }`, `Thread.new { greet }`. The whole program is left as it was, and so is one whose block does run in place but is not on the list above (`[1, 2].select { greet }`, `loop { p greet; break }`, `each` on a variable). A `BEGIN` block that calls the name leaves it as it was wherever it stands.
- An alias whose target is itself an alias: `def a = 1; def b = 2; alias c b; p a; alias a c; p a` still prints 1 and 1. A swap through a spare name (`alias spare left; alias left right; alias right spare`) takes its second alias and not its third: `p left; p right` prints `:r` and `:r` where master prints `:l` and `:r` and CRuby `:r` and `:l`.
- A reopened Object's alias over a top-level name (`class Object; alias greet shout; end`), and `alias_method`.
- `respond_to?(:greet, true)` for a name only an alias defines prints false on master (`def shout = 2; alias greet shout`); a program that asks it writes the name as a Symbol and is left as it was.

Measured on master 090969e7759b:

- `make cident` reports 6,766 identical, 1 differ (`test/toplevel_alias_takes_defined_name.rb`, the new test of the cured calls), no refusal changes; `make infer-test`, `make share-strings-test`, `make share-verify-test` and `make int-min-test` pass. Under `--debug` 169 programs of the sets below, the cured ones among them, get master's C. No program of the sets is refused on one tree and not on the other, or refused in other words.
- The three tests pass in 14 lanes with gcc and 14 with clang: plain, `SPINEL_GC_STRESS=1`, stress 2 with the verifier off and on, the minor collection off and on and the generational check, each built with and without `--share-strings`.
- Every program below is run on both trees and compared with CRuby line by line.
- 207 generated programs (five kinds of method: plain, with an argument, of another arity, with a block, answering a String; by 41 placements of the calls, the alias and other definitions), in three modes. Master is right in 21, and they get the C they had. Of the 186 master prints a wrong line in: 82 are right here; 98 get the C they had; 6 get other C and still print a wrong line, none a line master printed right (the swap through a spare name in the five kinds, and a pair of aliases of which one names `b`, String's method).
- 120 more programs written to break the rename (calls on `self`, names built at run time, `respond_to?`, `method`, `__method__`, `define_method`, a module included later, `undef`, a nested `def`, a second and a third alias, keyword and splat arguments, a default that calls the name, a lambda beside a target of another arity), in three modes: 95 get the C they had. Of the 25 others, 22 that print a wrong line or raise on master are right here, 1 that is right stays right, and 2 print a wrong line or raise on both (one of them prints CRuby 4.0's `{a: 1}`, which the 3.3.6 used here counts wrong). No program right on master is wrong, no line master printed right is lost, and no raise on master is a wrong line here.
- 446 more in 23 sets, each written against one of the conditions above (the name in an arm the desugar drops, in a `class`, in a String, a module mixed in, a method named by a value, a debug build, a builtin's name, a `for` target, a private name the program spells, a block above the alias): none that is right on master is wrong here, and by line none of the 54 that print otherwise loses a line.
- Every name of the two tables that can be a `def`'s name (762), aliased over with bodies that answer the same, in three shapes of call: 2,286 programs, each master's C. And 1,824 other names the compiler's source spells, 1,908 programs: 1,833 are right here, 64 get master's C, and 11 print or fail the same on both trees (`private`, `public` and `using`, which are main's own in CRuby; five names of the compiler's own, like `__enum_chain`, that fail in the C compiler on both).
- The conditions read the program as parsed and do not ask where a name is written, so a program a finer rule would cure is left as it was: 7 of the 207 (`send(:name)` below the alias in the five kinds, a method named `b` in two) and 7 of the 120 (a Symbol or a value naming the method below the alias in six, a variable of the name in one): 82 for 89 and 22 for 29.

Tests: `test/toplevel_alias_takes_defined_name.rb`, the cured calls; master prints 10 of its first 17 lines wrong and raises ArgumentError at the 18th. `test/toplevel_alias_name_reached_by_name.rb` and `test/toplevel_alias_name_in_block_pass.rb`, programs the change must leave alone (16 lines); they pass on master and here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not changed: `make optcarrot` prints checksum 59662 on master and here, and the two C files differ only in the checkout's own path, which the packed program spells; it has no top-level alias)
- [ ] Depends on: # (none)
