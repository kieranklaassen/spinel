# PR 7214: description edit for head 6ed6183c, third writing

This file replaces description-pairs-6ed6183c.md and description-pairs-6ed6183c-v2.md; only pair 6 and its note differ.

Seven exact replacements against the description as it stands on GitHub (the text after the nine pairs applied at 00:38 UTC on 2026-10-03). Each Old must occur exactly once in the live description. If any Old does not occur exactly once, stop and apply nothing. Nothing else in the description changes. Old and New are the text between the fence lines, without the fence lines; pair 4 is five lines replaced by six, and its `Tests:` line has runs of spaces that must be kept.

Where each fact comes from:

- Pairs 4, 5 and 7: the `make gate` run on macOS (arm64), CRuby 4.0.7, on 6ed6183c merged with master d5d42559, 10:31 to 10:48 UTC on 2026-10-03, as relayed. The six gate lines are in that log's order and spacing.
- Pair 1: `make cident REF=0919a4b0` on 6ed6183c in a Linux container, 10:50 UTC. The fourteen differing programs are the same fourteen the sentence already lists (five new, five that call Array#fetch with a block, four revision printers) and the one refusal change is still `test/tools_bisect_search.rb`.
- Pair 2: the five fix tests built with master d5d42559's compiler in that container at 11:05 UTC. Two do not build, three print a wrong answer.
- Pair 3: measured from 0919a4b0 to 6ed6183c. The twelve functions over 1,000 lines keep their lengths; no hunk lies in `emit_call_body` (623 lines before and after). `emit_array_call` is no longer changed at all: master's split moved the Array#fetch arms to `emit_poly_array_call` (355 to 346) and `emit_kind_array_call` (799 to 787), both under 1,000 lines.
- Pair 5, last sentence: `make scale-test` on master d5d42559 alone in the Linux container printed the same four ratios as the branch there and as the macOS run.
- Pair 6: the fourteen commits add nine files named `.expected`. Three runs on macOS under CRuby 4.0.7 on the tree of 6ed6183c merged with d5d42559, as relayed: the five fix tests' files in the gate run above; `ruby --enable-frozen-string-literal test/tools_bisect_search.rb | cmp - test/tools_bisect_search.rb.expected` silent with exit 0 at 11:05 UTC; the same compare for `test/fixtures/decisions/sites.rb` and `test/fixtures/decisions/nn_infer.rb` silent with exit 0 at 11:10 UTC. All eight equal CRuby 3.3.6's output with that flag in the Linux container. The ninth, `test/fixtures/bisect/fake.expected`, holds `right`, which `make bisect-test` passes as `--expected` to runs of its stand-in compiler; CRuby prints an empty line for `fake.rb`.

## 1

Old:

```
`make cident REF=ba6317b6` reports 5675 identical and 14 differing
```

New:

```
`make cident REF=0919a4b0` (the master commit this branch is rebased on; run on Linux) reports 5699 identical and 14 differing
```

## 2

Old:

```
each still fails on master at ba6317b6:
```

New:

```
each still fails on master at d5d42559:
```

## 3

Old:

```
No function over 1,000 lines grows in any of the fourteen commits: `emit_array_call` shrinks by 21 lines and `emit_call_body` is not touched.
```

New:

```
No function over 1,000 lines grows in any of the fourteen commits, and `emit_call_body` is not touched.
```

## 4

Old:

```
Tests: 5601 pass, 2 fail, 0 error
scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
scale-test: work at 4x the program is 4.82x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.29x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.24x (linear 4.00, limit 4.50)
```

New:

```
scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
scale-test: work at 4x the program is 4.82x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.29x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.24x (linear 4.00, limit 4.50)
Tests:     5627 pass,        0 fail,        0 error
gate: ALL GREEN
```

## 5

Old:

```
Rebased on master at ba6317b6. There is no `gate:` line because of the two failures, `pkg.tmpdir.tmpdir_expand_usable` and `socket_ipv6_and_class_methods`. Both fail the same way on plain master in the container this ran in, which runs as root and has no UDP sockets. Every other leg passed: benchmarks 64 pass, optcarrot checksum 59662, ruby/spec with every expected-PASS example still passing, and the property tests. The scale-test ratios are master's own.
```

New:

```
Run on macOS (arm64) with CRuby 4.0.7 on this branch's fourteen commits (6ed6183c) merged with master d5d42559. macOS has no `timeout`, which `tools/rubyspec/run.sh` calls, so `build/spinel-timeout` was put on PATH under that name for the run. Among the legs: benchmarks 64 pass, optcarrot checksum 59662 with its generated C byte-identical to master's, and ruby/spec with every expected-PASS example still passing. The scale-test ratios are master's own.
```

## 6

Old:

```
- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (generated with CRuby 3.3.6 under that flag, the newest in that container; the output is integers, strings, symbols, arrays and nil)
```

New:

```
- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written from CRuby 3.3.6 with that flag; CRuby 4.0.7 with that flag prints all eight exactly, the five fix tests', `test/tools_bisect_search.rb.expected` and the two fixture programs of `make decisions-test` under `test/fixtures/decisions/`, run on macOS; `test/fixtures/bisect/fake.expected` is the answer staged for `make bisect-test`'s stand-in compiler, not Ruby's output)
```

## 7

Old:

```
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
```

New:

```
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical to master's at d5d42559)
```
