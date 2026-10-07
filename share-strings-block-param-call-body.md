<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

With `--share-strings`, a method that stores what its own block parameter answers no longer compiles where the block is spliced in place: the generated C declares a box for a String, and the C compiler stops there.

This adds no sharing rule: a spliced block parameter's call takes the route its `yield` spelling already takes, by that route's own emission.

```ruby
class Box
  def initialize(r, &blk)
    @s = blk.call(r)
  end
  def s = @s
end

x = +"hi"
n = Box.new(3) { |r| x }
n.s << "!"
p x
```

Master (759d120fd) with `--share-strings` does not build it, with gcc or with clang. CRuby prints `"hi!"`, and so does master for `@s = yield(r)`. Before the merge of "A route that answers the String it is handed carries the shared handle" it built and printed `"hi"`.

`blk.call` and `blk.()` on a method's own block parameter, where the call's literal block is spliced into the method, are emitted as a `yield` is (`is_block_call`): the value is the block's String itself. That pull request's `strbuf_route_proc_call` took the call for a proc's answer, which comes back boxed, and declared an `sp_RbVal` for a `const char *`.

The proc route now leaves such a call alone, and `strbuf_route_yield` takes it beside the `yield` node. Two conditions in `src/codegen_stmt.c`. Without the flag nothing changes: both functions return before the new test.

3,510 programs, each against CRuby: nine holders (an instance variable written in `initialize` and in a method, an attr writer, a global, a Struct member, a local, an Array element, the method's value, an argument) by six spellings (`blk.call(r)`, `blk.(r)`, `blk.yield(r)`, `blk[r]`, `blk === r`, `yield(r)`) by nine block answers (a new String, a variable's String, a literal, an Integer, nil, a String or nil, a String or an Integer, a Symbol, `next x if r > 2; "low"`) by five call sites (top level, under another method's block, under `times`, in a method, the block handed over as `&pr`); for the two answers that hand over a variable's String, two more each that change it through one name and read it through the other. Without the flag the C of all 3,510 is master's. With it the C of 3,258 is master's, and master compiles none of the other 252: `blk.call(r)` and `blk.(r)` into an instance variable, an attr writer, a global, a Struct member or a local. Each of the 252 now prints what its `yield(r)` spelling prints on master, in a plain run and under `SPINEL_GC_STRESS=2`: 156 print CRuby's answer (60 did before that merge, 96 printed the copy's) and 96 do not.

Not in this change, each the same for `yield(r)` on master: those 96, where the block leaves by `next x if r > 2`, hand the holder a copy; so does a literal block when another call of the same method hands over a proc (`Box.new(3, &pr)`), since the method is then called and not spliced.

Every test of the corpus compiled with `--share-strings` (6,287, with `test/share/` and the reject list): 6,234 generate master's C, four of them but for the revision in `RUBY_DESCRIPTION`, and 53 are refused by both in the same words. `make cident` against master, without the flag: 6429 identical, 0 differ. `make share-strings-test`, `gc-stress-test` and `gc-minor-test` pass.

Test: `test/share/share_strings_block_param_call.rb`, which `make share-strings-test` runs; 9 lines, and master does not build it.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
