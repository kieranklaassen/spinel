<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`spinel bisect app.rb` names the compiler decisions behind a wrong answer. Each optimization that is a miscompile when its legality check is wrong now asks one registry (`src/decide.c`) before it is applied, under a key such as `nn-read@app.rb:12:5:x` or `root-elide@Lut#load:@lut`. `--decisions-log=FILE` writes the keys a compile took, and `--decisions=FILE` takes only the keys listed, so an empty file denies them all. The tool builds the program under subsets of its own log and prints a smallest set that is wrong on its own. Fourteen kinds are keyed; `tools/README.md` has the table.

With neither option given the registry is a test of one global and the compiler emits the C it did. `make cident REF=ec452b59` on this branch merged with master ec452b59 (run on Linux) reports 5814 identical and 0 differing. Its one refusal change is `test/tools_bisect_search.rb`, which requires a file the reference does not have. optcarrot's C is byte-identical.

Fourteen commits. The first five are fixes that stand without the tool, each with its test, and they are on master now, cherry-picked as 450e48db, 4f1f0a8a, 8e2e1883, e88a9aa0 and 42d192cf. What is left of this pull request is the other nine commits: the decisions registry, the `--decisions` flags and `spinel bisect`. The five were found by running the corpus with every keyed decision denied, which sends programs down the paths the legality checks almost never choose, and each failed on master until then:

1. A pattern guard is evaluated after its arm has bound (did not compile)
2. map! on a poly receiver runs its whole block in the array arm (`undefined method '*' for nil`)
3. The block of Array#fetch sees the index it was given (wrong answer)
4. fill with a block builds a poly value once, ahead of its store (did not compile)
5. A local is an array or nil only when every way of writing it says so (`h = nil; h ||= {}; h[k] = v; h[1]` was nil)

The first four are the cause #7070 fixed for Array#fetch_values: the value of a block or a guard leaves its setup in `g_pre`, ahead of where the parameter is bound. The next four commits are the registry, the keys for the nil narrowing, the keys for the rooting predicates, and the tool. The last five answer the review: a decisions log is not written over a file that is not one, `decisions-test` checks how a denied build exits and not only what it prints, the report does not call a build right for matching a wrong one, a key holds the whole of its site and name, and the log check reads only a regular file. `make decisions-test` joins `test-run` and `make bisect-test` joins `gate-props`. Against 76 seeded faults (a compiler with one legality check forced to say yes, and a corpus test it then miscompiles; measured on 0f6feeb9) the tool named the faulty decision in all 76, in 9.5 builds on average and 16 at most.

No function over 1,000 lines grows in any of the fourteen commits, and `emit_call_body` is not touched. For the Mutable Strings work: the argument rooting in `emit_args_filled_argv` asks its allocation check without the registry, so the routes that lend a global's or a class variable's slot cannot be switched off by a denied decision. No sharing rule is added.

Merged with master ec452b59, this branch's difference is those nine commits alone, in 28 files.

## `make gate` (on this branch merged with current master)

```
scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
scale-test: work at 4x the program is 4.82x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.29x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.24x (linear 4.00, limit 4.50)
Tests:     5627 pass,        0 fail,        0 error
gate: ALL GREEN
```

Run on macOS (arm64) with CRuby 4.0.7 on this branch's fourteen commits (6ed6183c) merged with master d5d42559. macOS has no `timeout`, which `tools/rubyspec/run.sh` calls, so `build/spinel-timeout` was put on PATH under that name for the run. Among the legs: benchmarks 64 pass, optcarrot checksum 59662 with its generated C byte-identical to master's, and ruby/spec with every expected-PASS example still passing. The scale-test ratios are master's own.

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written from CRuby 3.3.6 with that flag; CRuby 4.0.7 with that flag prints all eight exactly, the five fix tests', `test/tools_bisect_search.rb.expected` and the two fixture programs of `make decisions-test` under `test/fixtures/decisions/`, run on macOS; `test/fixtures/bisect/fake.expected` is the answer staged for `make bisect-test`'s stand-in compiler, not Ruby's output)
- [x] Values past 2^31 are marked `# spinel: int64` (no new test has one)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical to master's at d5d42559)
- [ ] Depends on: # (nothing)
