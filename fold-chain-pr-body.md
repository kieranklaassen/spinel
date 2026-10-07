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

The memo is typed the Array it is where the block is one chain of two or more pushes onto it whose last operand is a variable from outside the block and whose other operands are the block's own (`fold_block_chain_ends_in_outer` in `src/analyze_pass.c`). Every other block is typed as before: with the memo an Array, a chain that pushes the outer String first (`m << s << v`, right as it is) would be refused as a chained push, so only the end of the chain is taken.

With `--share-strings` such a fold over Strings, in a program that changes a String in place, is refused by the sentence for a String held by a block parameter no element iterator binds, as the same fold over a typed seed (`inject(["q"])`) is on master. Of 15,408 generated programs, 384 that answer as CRuby on master under the flag are refused that way; master refuses the typed-seed twin of each (only `[]` written `["q"]`) with the same sentence. Over Integers, Symbols and Floats the fold is right under the flag too.

Not here: a String in the middle of the chain (`m << v << s << v`) and, without the flag, one changed only through the result (`x.last << "y"; p s`). Both are wrong before and after.

The tests are `test/fold_empty_seed_push_chain.rb` (18 lines printed, 10 differ on master) and, for the flag, `test/share/share_strings_fold_chain.rb` (6 lines, 4 differ on master with `--share-strings`). `tools/cident.sh` against master 06064727 answers `6334 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`, the one being the first test (the corpus does not read `test/share/`). `make share-strings-test` passes. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; not yet run under Ruby 4.0)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the tests)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
