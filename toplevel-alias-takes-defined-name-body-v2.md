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

`rename_redefined_toplevel_defs` already gives an earlier top-level `def` a private name where a later `def` of the name follows, and renames the calls that run between the two. The alias is now such a later definition. The `def` and the calls above the alias take the private name; no method owns the name any more, and the calls below resolve through the alias. The old body stays reachable where the program kept it (`alias saved greet` above the alias).

The alias counts only where the rename is known to be right; every other program is compiled as it was:

- the alias is a statement of the program body, its target a method or an alias of the program above it;
- the `def`'s body does not ask `__method__`, which would answer the private name;
- the program defines the name nowhere else: no other `def` of it (on any receiver, in any class) and no other alias to it;
- no `respond_to?` asks about the name, or about a name that is not written out: it answers from the defs and does not see an alias;
- nothing above the alias reaches the name past the rename: a method, class or module body that calls it, a call on a receiver (`self.greet`), the name as a Symbol or a String, or a call that looks a method up by a name (`send`, `method`, `instance_method`). Above the `def` itself, any mention of the name counts;
- nothing below the alias takes the name as a method object (`method(:greet)`) or as the old name of another alias (`alias third greet`). Neither is built over an alias on master: `def shout = 1; alias greet shout; alias third greet; p third` does not build.

It costs nothing at run time: the calls are bound when the program is compiled. At compile time the alias is looked for only where no later `def` of the name is found, and only between the program's first and last top-level alias. A program with none compiles as it did, within 0.2%: 300, 1,500 and 3,000 top-level defs with as many calls take 462,280,627, 2,650,901,590 and 6,131,300,040 instructions of `spinel -S` on master and 462,400,993, 2,652,982,592 and 6,141,876,278 here (callgrind, the same C). A program the change cures pays one walk of the program for each alias over a defined name: 1,500 defs and 40 such aliases take 2,700,159,760 on master and 2,952,267,665 here.

Not in this change (each prints what it printed, unless said):

- An alias under a condition, in a loop or in a method, and a name defined again later or aliased twice.
- A method or a class above the alias that calls the name: `def use = greet` above `alias greet shout`, called after it, still reaches the first body. The whole program is left as it was, the calls below the alias too.
- A block above the alias that runs after it (`at_exit { p greet }`, a lambda called below the alias) reaches the first body, as on master. Where the target takes other arguments, a call below the alias that raised ArgumentError on master is right here, and the program goes on to print that block's wrong line: `l = -> { greet }` above `alias greet shout`, then `p greet(1); p l.call`. Without `p greet(1)` master prints the same wrong line.
- `def a = 1; def b = 2; alias c b; p a; alias a c; p a` printed 1 and 1; here it does not link (`sp_b` is undefined), as `def b = 2; alias c b; alias a c; p a` does not on master: an alias of an alias of a method nothing calls by name.
- A reopened Object's alias over a top-level name (`class Object; alias greet shout; end`), and `alias_method`.
- `respond_to?(:greet, true)` for a name only an alias defines prints false on master (`def shout = 2; alias greet shout`); that is why a program that asks it is left as it was.

Measured on master d76e6c8a:

- `make cident` reports 6,504 identical, 1 differ (`test/toplevel_alias_takes_defined_name.rb`, the new test of the cured calls), no refusal changes; `make infer-test` passes.
- Both tests pass plain and under `SPINEL_GC_STRESS=1` and `2`, built with gcc and with clang, with and without `--share-strings`.
- 207 generated programs (five kinds of method: plain, with an argument, of another arity, with a block, answering a String; by 41 placements of the calls, the alias and other definitions), in the three modes on both trees. Master is right in 21, and they get the C they had. Of the 186 master prints a wrong line in: 99 are right here; 72 get the C they had; 15 get other C and still print a wrong line, none a line master printed right (`at_exit { p greet }` and a lambda above the alias, and `alias del zap; alias zap del`, left to its second alias).
- 120 more programs written to break the rename (calls on `self`, names built at run time, `respond_to?`, `method`, `__method__`, `define_method`, a module included later, `undef`, a nested `def`, a second and a third alias, keyword and splat arguments, a default that calls the name), in the three modes: 76 get the C they had. Of the 44 others, 30 that print a wrong line or raise on master are right here, 4 that are right stay right, 6 print a wrong line or raise on both, and 4 are the two programs above that end otherwise (the link error; the lambda beside another arity), each in two forms. No program right on master is wrong, and only the link error loses a line master printed right.

Tests: `test/toplevel_alias_takes_defined_name.rb`, the cured calls; master prints 16 of its 26 lines wrong or not at all, raising ArgumentError at the call of an alias to a method of another arity. `test/toplevel_alias_name_reached_by_name.rb`, seven programs the change must leave alone; it passes on master and here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
