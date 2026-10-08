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

A top-level `alias` is kept on the Toplevel pseudo-class, and `comp_method_index` consults it only when no method owns the name. Over a name a `def` holds, the alias was never read: every call reached the `def`.

`rename_redefined_toplevel_defs` already gives an earlier top-level `def` a private name where a later `def` of the name follows, and renames the calls that run between the two. The alias is now such a later definition. The `def` and the calls above the alias take the private name; no method owns the name any more, and the calls below resolve through the alias. The old body stays reachable where the program kept it (`alias saved greet` above the alias).

The alias counts only where the rename is known to be right; every other program is compiled as it was:

- the alias is a statement of the program body, its target a method or an alias of the program above it;
- the program defines the name nowhere else: no other `def` of it (on any receiver, in any class) and no other alias to it;
- no `respond_to?` asks about the name, or about a name that is not written out: it answers from the defs and does not see an alias;
- nothing above the alias reaches the name past the rename: a method, class or module body that calls it, a call on a receiver (`self.greet`), the name as a Symbol or a String, or a call that looks a method up by a name (`send`, `__send__`, `public_send`, `method`, `public_method`, `instance_method`). Above the `def` itself, any mention of the name counts.

It costs nothing at run time: the calls are bound when the program is compiled. A program with no top-level alias over a defined name gets the C it had.

Not in this change (each prints what it printed):

- An alias under a condition, in a loop or in a method (`if c; alias greet shout; end`): the calls still reach the `def`.
- A method or a class above the alias that calls the name: `def use = greet` above `alias greet shout`, called after it, still reaches the first body. The whole program is then left as it was, the calls below the alias too.
- A name defined again later (`alias greet shout; p greet; def greet = "x"`), or aliased twice.
- A block above the alias that runs after it (`at_exit { p greet }`, a lambda called below the alias) reaches the first body, as it does on master; the calls below the alias are right.
- `method(:greet).call { |v| ... }` below the alias, where the methods take a block: master prints the first body's answer; here it does not build (the C compiler rejects an argument of `sp_poly_inspect`), which is what master does with the same program less the first `def`: `def shout(&b) = b.call(2); alias greet shout; p method(:greet).call { |v| v }`.
- `respond_to?(:greet, true)` for a name only an alias defines prints false on master (`def shout = 2; alias greet shout`); that is why a program that asks it is left as it was.

Measured on master 548d4196:

- `make cident` reports 6,485 identical, 1 differ (`test/toplevel_alias_takes_defined_name.rb`, the new test of the cured calls), no refusal changes; `make infer-test` passes.
- Both tests pass plain and under `SPINEL_GC_STRESS=1` and `2`, built with gcc and with clang, with and without `--share-strings`.
- 207 generated programs (five kinds of method: plain, with an argument, of another arity, with a block, answering a String; by 41 placements of the calls, the alias and other definitions), run in the three modes on both trees. Master is right in 21, and they get the C they had. Of the 186 master prints a wrong line in: 108 are right here; 67 get the C they had (the cases left as they were); 10 get other C and still print a wrong line, none a line master printed right (`at_exit { p greet }` above the alias, and a lambda called on both sides of it); 1 no longer builds (the `method(:greet).call { }` case above).
- 87 more programs written to break the rename (calls on `self`, names built at run time, `respond_to?`, `method`, `define_method`, a module included later, `undef`, a nested `def`, a second alias, keyword and splat arguments, a default that calls the name), plain: 53 print what master prints, 30 are right where master was wrong, 4 gain a right line and keep another wrong one. No line master printed right is lost.

Tests: `test/toplevel_alias_takes_defined_name.rb`, the cured calls; master prints 17 of its 27 lines wrong, raising ArgumentError at the call of an alias to a method of another arity. `test/toplevel_alias_name_reached_by_name.rb`, four programs the change must leave alone; it passes on master and here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
