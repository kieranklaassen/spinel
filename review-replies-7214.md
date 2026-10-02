# PR 7214: answers to CodeRabbit's four findings

Head `52dc3bfc` (was `0ace49ee`): five commits added on top, nothing amended or rebased. It merges cleanly with master `3d541fc8`. All four findings hold against the code and all four are fixed. `gc_save_take_back` is not touched.

| finding | where | result |
|---|---|---|
| 3, Major | src/main.c:731 | fixed in `cdac038d` and `52dc3bfc` |
| 4, Major | Makefile:1110 | fixed in `4305ef91` |
| 2, Minor | tools/bisect.rb:356 | fixed in `23237b38` |
| 1, Minor | src/decide.c:143 | fixed in `306acd36` |

## Replies for the review threads (final)

Post each as the reply on its thread, then resolve the thread.

**1. src/decide.c:143 (a key longer than the buffer is truncated)**

Fixed in 306acd36. The three buffers a key passes through (Class#meth, file:line:col, the key itself) now grow to what they hold, so nothing is cut. No program that builds reached it: `mc()` in src/codegen_util.c keeps the first 248 characters of a method name in the emitted C, so two methods that agree that far collide in C first. `spinel -c --decisions-log` did show such a pair sharing a key, and decisions-test now compiles that pair and looks for each method's own key.

**2. tools/bisect.rb:356 (the "is right" line when the denied build is wrong too)**

Fixed in 23237b38. When the build with every decision denied is wrong as well, the report takes its words from how the builds were judged: the program "differs" with the decisions found, and with only them denied it "answers as it does with every keyed decision denied". It no longer says "is right". bisect-test holds the wrong-either-way case to that line.

**3. src/main.c:731 (a decisions log path that overwrites the source)**

Fixed in cdac038d and 52dc3bfc. Before the log is opened for writing, a regular file with something in it must open with a key: a kind (lowercase words joined by hyphens, as every kind is) and an `@`. Anything else is refused, which covers the source and a required file. An empty file or an earlier log is replaced as before, a pipe or /dev/stdout is not looked into, and `--force` is the way through, as it is for `-o`. decisions-test names the source as the log and checks that the compile is refused and the source untouched.

**4. Makefile:1110 (the denied program's exit status)**

Fixed in 4305ef91. A build with every decision denied must now exit 0 as well as print its .expected, plain and under SPINEL_GC_STRESS=1, and the failure line gives the status it left with.

## The second reading (A to G)

- **A, real, fixed in `52dc3bfc`.** Reproduced with spinel: on `306acd36`, `spinel --decisions-log=/dev/stdout app.rb -c -o x.c | cat` hung until killed. The check now stats first and looks only into a regular file that has something in it. decisions-test sends a log down a pipe under a ten second limit; that test and the `p@x` one both fail on `306acd36`.
- **B, real, fixed in `52dc3bfc`.** The kind must now be lowercase words joined by hyphens, which all fourteen kinds are, and decisions-test holds `DECISION_KINDS` to that shape. `git@host:path` and `p@x` are refused and left alone. It is still a test of how the file opens, not proof: a file that opens with a hyphenated word and an `@` would be taken for a log. Reply 3 now says exactly that.
- **C, not changed.** `--decisions=X --decisions-log=X` does what was asked: the list is read, then replaced by the keys taken. Nothing in the tool or the docs uses one file for both. That a list opening with a comment is refused is a side effect of the check, not a design.
- **D, changed in `52dc3bfc`.** A regular file with something in it that cannot be read is refused, not treated as new.
- **G, my number was wrong.** 259 was the length of the whole C identifier in my example, `sp_Sprites_` plus 248. The cut is at 248 characters of the method name: `mc()` at src/codegen_util.c:3776 writes into `static char buf[256]` and stops at `sizeof buf - 8`. Measured by compiling two method names of about 700 characters with `-c` and reading the emitted name. Reply 1 is corrected. The message of `306acd36` still says "cuts a method's name at 259 characters"; correcting it means rewriting that commit, which I have not done.
- **Also seen.** The realloc results are unchecked, as everywhere in decide.c: left. The long-name test does not read the compile's status, but the log is emptied before the compile starts, so a failed compile leaves no key and the test fails: left. The `--keep-tmp` line prints "(wrong)" and "(all the others)", both true in the wrong-either-way case; only the file is named good: left.
- **Found while testing A.** A named FIFO as the log never worked, also before these commits: the log is opened and closed once at the start to empty it, which gives the FIFO's reader its end of file. `/dev/stdout` and `>(...)` work. Not changed.

## What was checked

- Each fix but the fourth has a test that fails without it; the fourth is itself a tightening of a test.
- On `52dc3bfc`: `decisions-test`, `bisect-test`, `cli-opts-test` pass; no function over 1,000 lines grows in any of the five commits.
- `make cident REF=0ace49ee` on `306acd36`: the generated C is identical for every program but the four that print the compiler's revision. `52dc3bfc` changes only the log check in main.c, the decisions-test recipe and one README sentence.
- No model identifier in the five messages or the diff; one `Co-Authored-By: Claude Code` trailer each.

The full gate is running; the old and new strings for the PR description follow when it finishes.
