# PR 7214: answers to CodeRabbit's four findings

Head `306acd36` (was `0ace49ee`): four commits added on top, nothing amended or rebased. It merges cleanly with master `58f467d5`. All four findings were checked against the code and hold; all four are fixed. `gc_save_take_back` is not touched.

| finding | where | result |
|---|---|---|
| 3, Major | src/main.c:731 | fixed in `cdac038d` |
| 4, Major | Makefile:1110 | fixed in `4305ef91` |
| 2, Minor | tools/bisect.rb:356 | fixed in `23237b38` |
| 1, Minor | src/decide.c:143 | fixed in `306acd36` |

## Replies for the review threads

Post each as the reply on its thread, then resolve the thread. The footer the Mac session adds to its comments goes after each.

**1. src/decide.c:143 (a key longer than the buffer is truncated)**

Fixed in 306acd36. The three buffers a key passes through (Class#meth, file:line:col, the key itself) now grow to what they hold, so nothing is cut. No program that builds reached it, because the emitted C cuts a method name at 259 characters and two such methods then collide there, but `spinel -c --decisions-log` did show them sharing a key. decisions-test compiles that pair and looks for each method's own key.

**2. tools/bisect.rb:356 (the "is right" line when the denied build is wrong too)**

Fixed in 23237b38. When the build with every decision denied is wrong as well, the report takes its words from how the builds were judged: the program "differs" with the decisions found, and with only them denied it "answers as it does with every keyed decision denied". It no longer says "is right". bisect-test holds the wrong-either-way case to that line.

**3. src/main.c:731 (a decisions log path that overwrites the source)**

Fixed in cdac038d. A log is refused when the file it names exists and does not open with a key (`kind@...`). That covers the source, a required file and anything else that is not an earlier log; an empty file or an earlier log is replaced as before, and `--force` is the way through, as it is for `-o`. decisions-test names the source as the log and checks that the compile is refused and the source is untouched.

**4. Makefile:1110 (the denied program's exit status)**

Fixed in 4305ef91. A build with every decision denied must now exit 0 as well as print its .expected, plain and under SPINEL_GC_STRESS=1, and the failure line gives the status it left with.

## What was checked before the push

- Three of the four come with a test that fails without the fix (the log over the source, the report line, the shared key); the fourth is itself a tightening of a test.
- The five fix tests, `decisions-test`, `bisect-test` and `cli-opts-test` pass; no function over 1,000 lines grows in any of the four commits (`main` is 918 lines, one line longer).
- `make cident REF=0ace49ee`: the generated C is identical to the previous head's for every program but the four that print the compiler's own revision.
- No model identifier in the four messages or the diff; one `Co-Authored-By: Claude Code` trailer each.

The full gate on the new head merged with master `58f467d5` is running. The old and new strings for the PR description follow when it finishes.
