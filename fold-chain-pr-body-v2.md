<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
s = String.new
x = ["a"].inject([]) { |m, v| m << v << s }
s << "x"
p x      # CRuby: ["a", "x"]. Here: ["a", ""]
```

`m << s` and `m << v; m << s` in the same fold are right. The chain is not, nor are `(m << v) << s`, `m.push(v).push(s)` and `m << v << v << s`, nor any of them over Integers.

`infer_block_params` types a fold's memo from the seed. An empty `[]` has no type, and the memo then took the receiver's element type: a String over Strings, an Integer over Integers. The call's own type rule and the emitter both have an Array for the memo, and the emitter retypes the memo's reads while it emits the block, so the block itself ran right. But the analysis read `m << v` as a String append (or a shift), and the rule that shares a String pushed onto an Array never saw `s` pushed.

The memo is now typed the Array it is when the block answers it at every step: the block's value is the memo, a push onto it (a chain of them too) or a conditional whose arms are, and the block neither assigns the memo nor leaves a step early. Any other block is typed as before, since its value replaces the memo and need not be an Array. `src/analyze_pass.c`, 45 lines added.

**Why not every empty seed.** The first form of this typed the memo an Array for every `[]` seed. `[1, "a", nil].inject([]) { |m, v| m.first || v }` then went from NoMethodError, as CRuby, to printing 1: for one round the memo was an Array and `m.first` was rewritten to an index read, then the block's value widened the memo and the rewrite stayed. So the condition is one the syntax decides and no round changes.

**Measured against master c1d108ab, each program compared with CRuby 3.3.6.** Two sets of generated programs, each a different one. The first pushes a String onto the memo by one link or another of a chain (14 blocks, 5 receivers, `inject([])`, `inject(Array.new)`, `inject(["z"])` and `each_with_object([])`, the String new, unfrozen or a frozen literal, changed before, after or through the result, at top level and in a method). The second uses an empty-seeded memo 49 ways over 10 receivers.

| | master c1d108ab | this branch |
|---|---|---|
| chains: 8,694 programs | | generated C identical to master's |
| chains: 2,898 programs | 1,402 as CRuby, 884 raise as CRuby does, 612 wrong and silent | 1,794 as CRuby, 884 raise as CRuby does, 220 wrong and silent |
| uses: 1,896 programs | | generated C identical to master's |
| uses: 1,044 programs | 1,014 as CRuby, 30 wrong and silent | 1,044 as CRuby |

No program that answered as CRuby on master answers differently, and none that raised answers silently. The 884 append to a frozen literal: FrozenError before and after. The 220 still wrong change the String only through the result (`x.last << "y"; p s`, and `x.first << "y"` is the same); they are wrong on master in the same way and this does not touch them. The 30 are `m.is_a?(Array) ? m << v : m`, which master answered as if the memo were no Array.

One shape goes from a wrong line to a crash, and is in neither count: a block that changes its element in place and then pushes it, `a = [+"a", +"b"]; x = a.inject([]) { |m, v| v << "!"; m << v }; p x, a`, printed `a` unchanged on master with nothing said, and now dies of a segmentation fault under gcc and does not compile under clang, as the same block over a typed seed (`a.inject([1, +"q"]) { ... }`) does on master: the push boxes the block's String handle as an object, which this change reaches and does not make.

Not in this change: the same chain in `each_with_object([])` and onto a local (`m = []; m << v << s`) also copies `s`, for another reason (the Array's element kind is taken from the chain's first link). A String that comes from a constant, a global, a Hash value, a method's result, a parameter or a reader is copied by the same push onto a local Array and in a fold over a typed seed on master, and is copied here.

**Generated C.** `tools/cident.sh` against master 23e9734d: `6096 identical, 9 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The nine are the new test and eight tests that fold from an empty seed; in each of the eight only the memo's unused outer declaration and its root entry change (`sp_RbVal lv_acc = sp_box_nil();` becomes `sp_PolyArray * lv_acc = NULL;`), the loop having always declared its own. optcarrot's C does not change.

**Test.** `test/fold_empty_seed_push_chain.rb` (16 lines printed; 10 differ on master). It prints the same under `SPINEL_GC_STRESS=1` and `2`.

The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; the test prints the same, byte for byte, under Ruby 4.0.7 with that flag.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag, equal under Ruby 4.0.7; the test prints Arrays of Strings and Integers, a String and an Integer)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the test)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
