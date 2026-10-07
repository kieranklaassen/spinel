<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
s = String.new
x = ["a"].inject([]) { |m, v| m << v << s }
s << "x"
p x      # CRuby: ["a", "x"]. master dafa0d04: ["a", ""], with and without --share-strings
```

`m << s` and `m << v; m << s` in the same fold are right. The chain is not, nor are `(m << v) << s`, `m.push(v).push(s)`, `m << v << v << s`, nor the chain over Integers.

`infer_block_params` types a fold's memo from the seed. An empty `[]` has no type, and the memo took the receiver's element type, so the analysis read `m << v` as a String append (or a shift) and the rule that shares a String pushed onto an Array never saw `s` pushed. The emitter had an Array for the memo all along.

The memo is now typed an Array when the block answers it at every step: its value is the memo, a push onto it (a chain of them too) or a conditional whose arms are, and the block neither assigns the memo nor leaves a step early. Typing it so for every `[]` seed was rejected: `[1, "a", nil].inject([]) { |m, v| m.first || v }` then printed 1 where CRuby raises NoMethodError.

One shape gets worse without `--share-strings`. `a = [+"a", +"b"]; x = a.inject([]) { |m, v| v << "!"; m << v }; p x, a` printed `a` unchanged on master, with nothing said, and now dies of a segmentation fault, as the same block over a typed seed (`a.inject([1, +"q"]) { ... }`) does on master. With the flag it is right before and after.

The test is `test/fold_empty_seed_push_chain.rb`: 16 lines printed, 10 differ on master, the same 10 with `--share-strings`. `tools/cident.sh` against master dafa0d04 answers `6273 identical, 9 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`: the test and eight tests that fold from an empty seed, where the memo's outer declaration and the root entries change and the loop is the same. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag, equal under Ruby 4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the test)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
