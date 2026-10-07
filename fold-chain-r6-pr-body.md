<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
s = String.new
x = ["a"].inject([]) { |m, v| m << v << s }
s << "x"
p x      # CRuby: ["a", "x"]. master: ["a", ""]
```

The same with `m.push(v).push(s)`, `(m << v) << s`, `m << v << v << s` and `m.append(v) << s`, and over Integers, where the chain read as a shift.

`infer_block_params` types a fold's memo from the seed. An empty `[]` has no type, and the memo took the receiver's element type: over Strings `m << v` read as a String append, and `s` was never seen stored into an Array.

The memo is typed the Array it is where the block is one chain of two or more pushes onto it whose last operand is a local outside the block that `=` alone binds and whose other operands are the block's own (`fold_block_chain_ends_in_outer` in `src/analyze_pass.c`). The memo is then the general Array, which holds the String itself (`x[1].equal?(s)` is true), and that is why the answer is right without a sharing rule.

Every other block is typed as before, and its C is master's. With the memo an Array, a chain that pushes the outer String first (`m << s << v`, right as it is) would be refused as a chained push, and so would one that ends in a parameter its method changes in place:

```ruby
def f(a, s)
  s << "x"
  a.inject([]) { |m, v| m << v << s }
end
p f(["a", "b"], +"s")    # ["a", "sx", "b", "sx"] on master and here
```

Over a `for` variable the types would not settle, and a local `||=` binds would go in as a copy. So the last operand is a local `=` alone binds: no parameter of a method or of a block, no `for` variable, nothing `||=`, `&&=`, an operator write or a multiple assignment writes.

Only with `--share-strings`: such a fold over Strings, in a program that changes a String in place, is refused by the sentence for a String held by a block parameter no element iterator binds, and master refuses the same program with only the seed written `["q"]` by that sentence. Of 19,498 generated programs, 1,309 that answer as CRuby on master under the flag are refused that way, each beside that twin. That is the flag's own rule, reached now that the memo is an Array; no sharing rule is added. Over Integers, Symbols and Floats the fold is right under the flag too. Without the flag none of the 19,498 that is right on master is refused, wrong or not building.

Not here, each wrong before and after: a String in the middle of the chain (`m << v << s << v`); without the flag, one changed only through the result (`x.last << "y"; p s`); and a String handed to a method that folds it and changed by the caller afterwards (`def f(a, s) = a.inject([]) { |m, v| m << v << s }; t = +"s"; x = f(a, t); t << "x"; p x`).

The tests are `test/fold_empty_seed_push_chain.rb` (21 lines printed, 10 differ on master; its last three are the parameter, the `for` variable and the `||=` local, as on master) and, for the flag, `test/share/share_strings_fold_chain.rb` (6 lines, 4 differ on master with `--share-strings`). `tools/cident.sh` against master a3941433 answers `6370 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`, the one being the first test (the corpus does not read `test/share/`). `make share-strings-test` passes. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; not yet run under Ruby 4.0)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the tests)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
