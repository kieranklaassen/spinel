<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Under a C or POSIX locale the pre-commit hook raises, and so refuses the commit:

```
$ LC_ALL=C git commit          # src/analyze.c staged, one space changed
tools/gate.rb:117:in 'String#=~': invalid byte sequence in US-ASCII (ArgumentError)
```

With `LANG` unset, `LC_ALL=C`, or a UTF-8 locale the machine does not have, Ruby tags what it reads from a child process as US-ASCII, and a regexp match on a line with a byte over 127 raises. Two places in `ruby tools/gate.rb check`:

- `Gate.functions` (line 117) matches each line outside a function. `src/analyze.c` and `src/analyze_pass.c` have a comment there with an arrow in it, so a commit that stages either is refused.
- `Gate.check` (line 184) looks for a fixed `/tmp` path in a new test. 349 of the 5,780 tests carry non-ASCII text; a new one like them is refused.

Two commits; the hook then answers under a C locale as it does under UTF-8.

**1. The check reads git's and CRuby's output as bytes** (9fe0c141). `Gate.run` and `Gate.cruby` read in binary mode. It takes both: the `.expected` comparison is between `git show` and CRuby's output, and with only git's side in bytes a test that prints `café` is refused under UTF-8 too. Every pattern in the tool is ASCII, so for valid UTF-8 no answer changes under UTF-8. A C file or a test that is not valid UTF-8 raised on master under UTF-8 as well, and now gets the rule's verdict.

**2. The check's CRuby judges a test under UTF-8 whatever the locale** (965925a0). The CRuby the hook starts inherits the C locale, and there `p "café"` prints the accent as an escape, `STDIN.read.size` counts bytes and `Encoding.default_external` is US-ASCII, so a new test with a right `.expected` is refused as differing from CRuby. Of the tests whose `.expected` CRuby 3.3.6 agrees with under UTF-8, 49 get another answer from it under `LC_ALL=C`. `Gate.cruby` now passes `--external-encoding=UTF-8`: none of the 49 differs then, and under a UTF-8 locale it changes nothing. A test's `.args` is read as bytes too; a non-ASCII argument raised under C.

Measured on 1ed8b0fb: the hook on 57 staged cases, under `C.UTF-8`, `C`, `POSIX`, no locale, and `en_US.UTF-8` where that is not installed. On master under UTF-8, 36 pass, 17 are refused (each of the hook's reasons), and 4 raise because the staged file is not valid UTF-8.

- Under UTF-8, 53 answer as on master, line for line; the 4 that raised get the rule's verdict (2 pass, 2 are refused by name).
- Under each of the other four locales master raises on 30. Now none raises, and all 57 give the answer they give under UTF-8.
- Nothing that passes on master is refused, and nothing master refuses for a reason passes, in any locale.

`make gate-tool-test` gains six lines: a C file and a new test with non-ASCII text, with UTF-8 and with US-ASCII as the default external encoding. For the US-ASCII ones its CRuby runs under `LC_ALL=C`, on a test that prints through `p` and takes a non-ASCII argument. It raises on master and fails with any one of the four changed lines taken back.

The cases ran with Ruby 3.1.6, 3.2.6 and 3.3.6 on x86_64 Linux, with `tools/gate-ruby` told to accept them. On a second machine, with Ruby 4.0.7 on macOS arm64: `make gate-tool-test` passes on each commit with no locale set, with `LANG=en_US.UTF-8` and with `LC_ALL=C`. Under `LC_ALL=C` the hook after the first commit passes a staged `src/analyze.c` and a new test that prints `café`, where master raises at lines 117 and 184, and refuses that test when its `.expected` is wrong; a new test holding `p "café"` with the right `.expected` is refused after the first commit and passes after the second.

Left alone: a test that prints the locale itself (`Encoding.find("locale")`, `Encoding.locale_charmap`, the encoding of `__FILE__`, `$0` or an `ENV` value) still answers by the locale under C, and no test in the corpus does; the refusal message still names the command without `--external-encoding=UTF-8`; `ruby tools/gate.rb linux` reads its log as text and would raise the same way on a log with a non-ASCII byte (not run: it needs docker).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no test is added under `test/`; `make gate-tool-test` ran with Ruby 4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (no compiler source changes)
- [ ] Depends on: #
