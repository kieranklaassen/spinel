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

It costs nothing at run time: the calls are bound when the program is compiled. At compile time a program with no top-level alias pays one look over the statements of its top level, and one whose aliases give no name a `def` holds a lookup for each `def` there. Where an alias does give a `def`'s name the program is read for the names it writes and the top level is walked once for all its aliases; a rename then walks the statements between the `def` and the alias, as the rename for a later `def` does. A program with no top-level alias compiles within 0.04% of master: 1,000, 2,000 and 3,000 lines of top-level defs and calls take 792,745,413, 1,681,231,563 and 2,663,340,551 instructions of `spinel -S` on master and 793,017,915, 1,681,802,351 and 2,664,140,032 here (callgrind, the same C). By function the look is 22 instructions a line (`redef_note_inside_names`, 22,195 at 1,000 lines). The rest is layout, measured: libc's `strncmp` is called the same 409,473 times and costs 274,970 more in this binary, and this change built with its two calls never made counts 124,907 over master on that program. With aliases, at 1,500 defs in about 3,000 lines: 40 aliases that give fresh names take 2,715,057,908 on master and 2,716,343,318 here; one alias over a `def` that nothing calls afterwards 2,668,824,749 and 2,673,641,096, the program being read a second time, and 40 of them 2,682,172,633 and 2,687,884,844, all three the same C; 40 aliases the change cures 2,712,997,371 and 2,779,639,942 (2.5%).

The alias counts only where the rename is known to be right; every other program is compiled as it was. What the program says of the two names is read from the program as written, ahead of every desugar (`redef_note_inside_names`, `analyze_program`'s first step), because the desugars drop and rewrite the code the question is about: under `if RUBY_ENGINE == "ruby"` the arm CRuby runs is gone by the time the pass looks.

- Each of the two names is defined only by statements of the top level: no `def` of either anywhere else (in a class, under a condition, in a loop, a block, a `begin` or another `def`, on a receiver), and neither is written as a Symbol or a String outside a top-level alias. A `def` under an `if` may or may not have run when the alias does, and a Symbol is how a name reaches `define_method`, `attr_reader`, `undef`, `send` or `respond_to?`.
- Nothing in the program is named `include`, `prepend` or `extend`, or one of their hooks, as a call, a Symbol, a String or a `def`. A module mixed in can put a body of either name ahead of the top level's, and it need not be the program's text (`prepend Kernel`).
- No `respond_to?` asks about a name that is not written out: it answers from the defs and does not see an alias.
- The program names, makes and loads no method by something its text does not spell, anywhere: `send` or `method` handed a value, a block-pass of a value, `define_method` or an `attr` word with a name that is no literal, `eval` of text, `binding`, a file the compiler did not read. That is master's own answer (`g_written_by_value`, the walk behind `an_prog_never_gives`); it is read here and no line is added to it.
- The build is not a debug build (`--debug`, `-g`): its backtrace names a frame after the C function, and would show the private name where it showed the `def`'s. A later `def` of the name does show it there on master: `def f = raise("boom"); f; def f = 1` names the frame `f__redef1`.

Then by position, among the statements of the top level:

- the target is a `def` above the alias, and no alias above gives the target's name;
- no other `def` or alias gives the alias's name, and no alias below takes it as its old name (`alias third greet`);
- the `def`'s body asks neither `__method__` nor `__callee__`, by a call or by a Symbol handed on (`send(:__method__)`), which would answer the private name;
- nothing above the alias reaches the name past the rename: a method, class or module body that calls it, or a call on a receiver (`self.greet`). Above the `def` itself a bare call counts too;
- a statement below the alias calls the name. An alias nothing calls afterwards takes nothing, and the program keeps the C it had.

Not in this change (each prints what it printed, unless said):

- An alias under a condition, in a loop or in a method, and a name defined again later or aliased twice.
- A program that writes either name anywhere else, whatever it does with it: a class with a method of that name, a `def` of it under a condition, `send(:greet)` below the alias, a hash key `greet:`, the String `"greet"`.
- A program with an `include`, a `prepend` or an `extend` anywhere, whatever the module, and one with a site that names a method by a value anywhere, or that may load a file the compiler did not read.
- A debug build: `--debug` compiles every program as it did, so a program this change cures prints master's line there.
- A method or a class above the alias that calls the name: `def use = greet` above `alias greet shout`, called after it, still reaches the first body. The whole program is left as it was, the calls below the alias too.
- A block above the alias that runs after it (`at_exit { p greet }`, `END { p greet }`, a lambda called below the alias) reaches the first body, as on master. Where the target takes other arguments, a call below the alias that raised ArgumentError on master is right here, and the program goes on to print that block's wrong line: `l = -> { greet }` above `alias greet shout`, then `p greet(1); p l.call`. Without `p greet(1)` master prints the same wrong line. A `BEGIN` block below the alias that calls the name raises NameError in CRuby; master prints the first body's line for it and this change the second's.
- An alias whose target is itself an alias: `def a = 1; def b = 2; alias c b; p a; alias a c; p a` still prints 1 and 1. A swap through a spare name (`alias spare left; alias left right; alias right spare`) takes its second alias and not its third: `p left; p right` prints `:r` and `:r` where master prints `:l` and `:r` and CRuby `:r` and `:l`.
- A reopened Object's alias over a top-level name (`class Object; alias greet shout; end`), and `alias_method`.
- `respond_to?(:greet, true)` for a name only an alias defines prints false on master (`def shout = 2; alias greet shout`); a program that asks it writes the name as a Symbol and is left as it was.

Measured on master b791081037be:

- `make cident` reports 6,731 identical, 1 differ (`test/toplevel_alias_takes_defined_name.rb`, the new test of the cured calls), no refusal changes; `make infer-test`, `make share-strings-test`, `make share-verify-test` and `make int-min-test` pass. Under `--debug` 125 programs of the sets below, the cured ones among them, get master's C.
- The three tests pass in 14 lanes with gcc and 14 with clang: plain, `SPINEL_GC_STRESS=1`, stress 2 with the verifier off and on, the minor collection off and on and the generational check, each built with and without `--share-strings`.
- Every program below is run on both trees and compared with CRuby line by line.
- 207 generated programs (five kinds of method: plain, with an argument, of another arity, with a block, answering a String; by 41 placements of the calls, the alias and other definitions), in three modes. Master is right in 21, and they get the C they had. Of the 186 master prints a wrong line in: 84 are right here; 92 get the C they had; 10 get other C and still print a wrong line, none a line master printed right (`at_exit { p greet }` above the alias, and the swap through a spare name).
- 120 more programs written to break the rename (calls on `self`, names built at run time, `respond_to?`, `method`, `__method__`, `define_method`, a module included later, `undef`, a nested `def`, a second and a third alias, keyword and splat arguments, a default that calls the name), in three modes: 90 get the C they had. Of the 30 others, 23 that print a wrong line or raise on master are right here, 1 that is right stays right, 4 print a wrong line or raise on both (one of them prints CRuby 4.0's `{a: 1}`, which the 3.3.6 used here counts wrong), and 2 are the lambda beside another arity above, in two forms. No program right on master is wrong, and no line master printed right is lost.
- 402 more in 22 sets, each written against one of the conditions above (the name in an arm the desugar drops, in a `class`, in a String, a module mixed in, a method named by a value, a debug build): none that is right on master is wrong here, and by line only the lambda beside another arity ends otherwise.
- The rule reads the program as parsed and does not ask where a name is written, so a program that names either method by a Symbol or a value below the alias is left as it was: 5 of the 207 and 6 of the 120 that a rule looking only above the alias would also cure (84 for 89; 23 for 29, or 24 for 30 with the `{a: 1}` program).

Tests: `test/toplevel_alias_takes_defined_name.rb`, the cured calls; master prints 14 of its 23 lines wrong. `test/toplevel_alias_name_reached_by_name.rb` and `test/toplevel_alias_name_in_block_pass.rb`, programs the change must leave alone (16 lines); they pass on master and here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (none)
