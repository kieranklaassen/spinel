<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def show(w)
  yield
  p w
end

class Holder
  def initialize = @s = +"a"
  def go = show(@s) { @s << "x" }
end
Holder.new.go     # "ax" in CRuby, "a" on master

u = +"u"
show(u) { u << "x"; u = +"k" if u.size > 9 }     # "ux" in CRuby, "u" on master
```

A yielding method is spliced at its call. A String parameter its body only reads or hands on takes the argument's value where something can assign the variable while the body runs, so that the assignment does not show through the parameter. By value it also misses what the call's block does to that String in place. For an instance variable any call in the block counts as a possible assignment, so the first block above, which assigns nothing, lost its append: a regression of the commit "A spliced method's appended-to parameter keeps its String when the block reassigns the argument". The second is one of "A spliced method's read-only String parameter keeps the String it was given". Without `--share-strings` only; with it the parameter takes the handle and both are right.

Where the block's text changes the String in place (a mutator on the variable, or the variable handed to a method of the program), the parameter is an alias again when every assignment that can run during the call is one the splice sees (`splice_alias_proven`):

- a local no proc assigns: only the block's own text can assign it, and each such store moves the alias off the variable first (`splice_store_open`), so the parameter keeps the String it was given;
- a local a proc assigns, where the block's text does not and neither the block nor the method's body runs code out of view, so the proc cannot be called meanwhile;
- an instance variable, where the block and the method's body run no code out of view and assign the variable only in the block's own text. In view are builtins on values whose methods run no code of the program's, `p`, `puts` and `print` of such values, and a method of self with one body that passes the same test.

Everything else keeps the value, with master's C.

Not in this change, wrong on master and the same output here:

- a store the move does not follow: a pattern's binding (`in String => u`), a `for` index, a store under a rescue or an ensure or in the block of a call that is no builtin iterator, a method whose body opens such a frame around its yield. Master's own appended-to parameter is wrong for the first two and where a raise or a throw unwinds past the store, so the alias is not taken there;
- a parameter the method hands on to a call with a block, or yields: an inner splice copies the alias and a store moves only the outer one;
- a variable appended to in a loop, which is a buffer and has no slot to lend (`show(@s) { 2.times { @s << "t" } }`);
- a block that calls a method of another object, or a method of self that assigns the instance variable: not provable either way;
- a global, a class variable or a top-level instance variable: `show($g) { $g << "x"; $g = +"b" if done }` shows "a";
- a parameter the body reads only as a receiver or in an interpolation (`p w.size`, `"#{w}"`), which is by value before this test is reached.

Tests: `test/yield_param_block_in_place.rb`: a local whose block appends and assigns in each order and on a path that does not run; the other changes in place (a bang method, `replace`, an index store, `concat`, an append through a method); a multiple assignment; the parameter handed on; the yield inside the method's own iterator and run twice; a store in a builtin iterator's block; a proc elsewhere; the same in a method; an instance variable whose block only appends, appends and assigns, calls an Array's method, calls a method of self that appends, and a method that reads the parameter through a top-level one. On master 16 of its 36 lines are wrong (7 on master 759d120f, before the two commits). It passes under `SPINEL_GC_STRESS=1` and `2`, with clang and at `-O 1`.

Generated C against master (`make cident REF=bce327d0`): `6482 identical, 1 differ, 0 refusal changes` (the new test). `tools/refusals.sh` passes (536 records); `make reject-test` and `make share-strings-test` pass. optcarrot's generated C is byte-identical. Programs of ours, on master bce327d0 with CRuby 3.3.6 as the reference: 2,366 calls of a spliced method with a String variable (a local at top level and in a method, an instance variable, a class variable, a global, a top-level instance variable; nine method bodies that read or hand on the parameter; 26 blocks that change the String in place, assign the variable, or both; one, two and seven splices deep).

| without the flag | |
|---|---|
| wrong on master, right here | 224 |
| right on both, the alias in place of the value | 84 |
| the same C, right | 1,058 |
| the same C, wrong | 836 |
| the same C, no build (48) or refused by master (116) | 164 |

With `--share-strings` all 2,366 have master's C byte for byte (1,702 right, 522 wrong, 24 that do not build, 118 refused). 32 more are one call each with a different store in its block (under a `begin`, a `case`, a loop, a multiple assignment, in an interpolation, a pattern, a `for`, an iterator's block): 23 wrong on master are right, 9 keep master's output.

None that is right on master is wrong here, none is newly refused and none stops building.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Strings and Integers)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
