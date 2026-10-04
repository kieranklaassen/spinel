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
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 where this was built; the test prints only integers, floats, strings, symbols, nil, booleans and arrays of them)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the test)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not compared where this was built)
- [ ] Depends on: # (nothing)
