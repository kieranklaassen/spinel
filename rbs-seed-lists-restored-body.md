<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

On master `make rbs-seed-test` runs no check and prints `rbs-seed-test: pass`.

```
$ rm -rf build/rbs-seed-results; make rbs-seed-test     # master c2dadf4975ab
rbs-seed-test: pass
$ ls build/rbs-seed-results
ls: cannot access 'build/rbs-seed-results': No such file or directory
```

The fault came in with #7524's Makefile edit. It put one line where the two lists stood:

```make
RBS_SEED_CHECKS :=  \
RBS_SEED_RESULTS := $(patsubst %,build/rbs-seed-results/%.res,$(RBS_SEED_CHECKS)) \
                    $(patsubst %,build/rbs-seed-results/%.run,$(RBS_SEED_RUN_CHECKS))
rbs-seed-test: $(RBS_SEED_RESULTS)
```

The backslash joins the next two lines to the first, so they are the value of `RBS_SEED_CHECKS`. `RBS_SEED_RESULTS` is never defined and `RBS_SEED_RUN_CHECKS` is defined nowhere. `rbs-seed-test` has no prerequisites, its recipe loops over no result file, and it prints pass. The gate has printed pass for zero checks since that merge (da984e293).

Both lists are back as they stood before #7524, name for name in the same order: 54 names in `RBS_SEED_CHECKS` and 26 in `RBS_SEED_RUN_CHECKS`.

One name is new: `array_transpose_nil`, at the end of `RBS_SEED_RUN_CHECKS`. #7524 added `test/rbs-seed/array_transpose_nil.rb`, its `.expected` and `sig/array_transpose_nil.rbs`, and no list named them. Those three files are what the `.run` rule reads. A name in `RBS_SEED_CHECKS` needs its own arm in the `.res` rule's `case`, and #7524 added none: `make build/rbs-seed-results/array_transpose_nil.res` answers `FAIL (no check named array_transpose_nil)`.

Measured with `rm -rf build/rbs-seed-results; make rbs-seed-test` (linux-x86_64, gcc 13.3.0):

```
master c2dadf4975ab   0 result files                                rbs-seed-test: pass
this branch           81 result files (54 .res, 27 .run), each 1    rbs-seed-test: pass
```

Master 4d56c1573c24 gave the same 0. A full `make gate` on that master, run on a second host, agrees: it printed `rbs-seed-test: pass` about a minute in and built none of the 80 result files (54 `.res`, 26 `.run`) the leg built on fa08b100.

The 80 restored checks pass on master as it is. Nothing merged while the leg ran nothing broke one of them.

The leg can fail again. With one line added to `test/rbs-seed/array_transpose_nil.expected` it prints `rbs-seed-test: FAIL (array_transpose_nil output mismatch)` and `make` exits 2.

Left as it is:

- The recipe still prints pass when the lists are empty. This adds no guard against that.
- No source file and no test file changes. The Makefile only, 2 lines in and 1 out.
- Every other file under `test/rbs-seed` was already read: by a list name, by the `contradicted_returns` arm (four `.rb` with their sig files), or by `byref-capture-test` (`byref_capture_scan`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
