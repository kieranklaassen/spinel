<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

#7415 made `ruby tools/gate.rb check` read sources as bytes, so under a C or POSIX locale the pre-commit hook no longer raises on a staged UTF-8 source. Three lines of `tools/gate.rb` are left before it answers there as it does under UTF-8.

**The CRuby that judges a test inherits the C locale.** There `p "café"` prints the accent as an escape, `STDIN.read.size` counts bytes and `Encoding.default_external` is US-ASCII, so a new test with a right `.expected` is refused:

```
$ LC_ALL=C git commit      # test/zz.rb holds  p "café"  and test/zz.rb.expected holds  "café"
gate: test/zz.rb: .expected differs from `ruby --enable-frozen-string-literal test/zz.rb`
```

`Gate.cruby` now passes `--external-encoding=UTF-8`. Counted on 1ed8b0fb with CRuby 3.3.6: of the 4,850 tests whose `.expected` it agrees with under UTF-8, 49 get another answer under `LC_ALL=C`, and none with the option. Under a UTF-8 locale the option changes nothing.

**A test's `.args` with a non-ASCII argument raises** in `split` (gate.rb:197). It is read with `File.binread`. An `.args` holding a byte that is not valid UTF-8 raises there on master under UTF-8 as well, and now passes: the one case where the answer under UTF-8 changes.

**git's own answer raises when it holds a byte over 127** (gate.rb:31 in `strip`, or gate.rb:174 in `split` with Ruby 3.1): a checkout under a non-ASCII path when the hook runs from a subdirectory, or a staged file name git prints unquoted (`core.quotePath=false`). `Gate.run` reads in binary mode.

Measured on ebb73f70: the hook on 57 staged cases (pass and refuse, each of the hook's reasons, ASCII and not), under `C.UTF-8`, `C`, `POSIX`, no locale, and `en_US.UTF-8` where that is not installed. On master under UTF-8, 38 pass and 19 are refused.

- Under UTF-8 all 57 answer as on master, line for line (none of them is the `.args` case above).
- Under each of the other four locales master raises on 3 and refuses 6 right tests. Now none raises, and all 57 give the answer they give under UTF-8.
- Nothing that passes on master is refused, and nothing master refuses under UTF-8 passes, in any locale.
- The other steps (`start`, `stamp`, the trailer, `verify`, `check` with non-ASCII file names) in a checkout under a non-ASCII path: master raises in five of twelve under C, now none does, and under UTF-8 every line is as on master.

`make gate-tool-test` gains two lines: under `LC_ALL=C` and a US-ASCII default external, a new test with a non-ASCII name, argument and `p` output passes with its right `.expected` and is refused with a wrong one. It raises on master, and fails with any one of the three lines taken back.

The hook cases ran with Ruby 3.3.6 and the gate-tool test with 3.1.6, 3.2.6 and 3.3.6, on x86_64 Linux, with `tools/gate-ruby` told to accept them.

Left alone: a test that prints the locale itself (`Encoding.find("locale")`, `Encoding.locale_charmap`, the encoding of `__FILE__`, `$0` or an `ENV` value) still answers by the locale under C, and no test in the corpus does; the refusal message still names the command without `--external-encoding=UTF-8`; `ruby tools/gate.rb linux` reads its log as text (gate.rb:218) and still raises under C on a log with a byte over 127.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no test is added under `test/`)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (no compiler source changes)
- [ ] Depends on: #
