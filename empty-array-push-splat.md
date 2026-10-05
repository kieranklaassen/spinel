<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A splat pushed onto an empty array literal went in as one element, with nothing said:

```ruby
a = [1, 2]
b = [].push(*a)
b << 3
p b                         # [[1, 2], 3]; CRuby [1, 2, 3]
p [].append(*a)             # [[1, 2]]; CRuby [1, 2]
p [].unshift(*a)            # [[1, 2]]
p [].prepend(*a)            # [[1, 2]]
p [1, 2].unshift(nil, *a)   # [nil, [1, 2], 1, 2]; CRuby [nil, 1, 2, 1, 2]
```

Two arms of `emit_call_body` build these calls as a fresh poly array with each argument as one element, and they come ahead of `emit_array_splat_mutator`, which spreads a splat for every other receiver. Both now leave to it a call with a splat among its arguments (`call_has_splat_arg`) and no block, so `[].push(*a)` is built the way `[0].push(*a)` and `b = []; b.push(*a)` already were. Six lines of `src/codegen_call.c` change and none is added: `emit_call_body` keeps its length.

A call without a splat takes the same arm as before. So does a call with a block beside the splat, which `emit_array_splat_mutator` declines on every receiver: `[].push(*a) { }` still answers `[[1, 2]]`, the way `c = [0, "s"]; c.push(*a) { }` answers `[0, "s", [1, 2]]`. That is not changed here.

One test, `test/empty_array_literal_splat_push.rb`. On master 6ddcb81fa 23 of its 33 lines are wrong and 8 are not reached; with this commit all 33 are right, under `SPINEL_GC_STRESS=1` and `=2` too. Of the 5,934 programs in `test/`, `benchmark/` and `packages/*/test/`, the generated C of 5,933 is the same as on master 6ddcb81fa; the one that differs is the new test.

## `make gate` (on this branch merged with current master)

```
scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
scale-test: work at 4x the program is 4.74x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.10x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.22x (linear 4.00, limit 4.50)
Tests:     5848 pass,        0 fail,        0 error
gate: ALL GREEN
```

Run on macOS (arm64) with CRuby 4.0.7, on master 6ddcb81fa merged with this branch's commit (590a6db4a).

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (CRuby 4.0.7 with that flag prints exactly the test's `.expected`)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical to master's at 6ddcb81fa)
- [ ] Depends on: # (nothing)
