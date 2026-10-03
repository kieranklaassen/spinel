# PR 7238: the gate block for 59aabda7 on master 5cc6d93b (green)

The Mac ran the full gate on 59aabda7 merged with master 5cc6d93b (a clean merge) from 07:24 to 07:40 UTC on 2026-10-03: ALL GREEN. These pairs come after the four of `description-pairs-7238-1.md` and touch none of their text.

Old in 1, 2 and 3 is the live text as the Mac read it at 07:45 UTC, relayed by the coordinator; this thread cannot read the description. Old in 4 is NOT known live: it is quoted from `pr-body.md`, the text the PR was opened from. Each Old is to occur exactly once in the live text; if one does not, stop and say so, and change nothing for that pair.

## 1. The fence

Old, the content of the fence:

```
scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
scale-test: work at 4x the program is 4.82x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.31x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.25x (linear 4.00, limit 4.50)
Tests:     5594 pass,        0 fail,        0 error
gate: ALL GREEN
```

New, the content of the fence, the lines as the gate on 59aabda7 merged with 5cc6d93b printed them:

```
scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
scale-test: work at 4x the program is 4.82x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.29x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.24x (linear 4.00, limit 4.50)
Tests:     5620 pass,        0 fail,        0 error
gate: ALL GREEN
```

Lines 3, 4 and 5 change; 1, 2 and 6 are the same.

## 2. The run line

Inside the line that begins "Run on macOS (arm64)" only:

Old:

```
at 0d370b71 plus this commit.
```

New:

```
on this branch's two commits (59aabda7) merged with master 5cc6d93b.
```

The rest of that line stays as it is, so it reads: "Run on macOS (arm64) on this branch's two commits (59aabda7) merged with master 5cc6d93b. macOS has no `timeout`, which `tools/rubyspec/run.sh` calls, so `build/spinel-timeout` was put on PATH under that name for the run." If `build/spinel-timeout` was not put on PATH for this run, say so and that sentence is reworded.

## 3. The optcarrot checkbox

Old:

```
byte-identical to master's at 0d370b71)
```

New:

```
byte-identical to master's at 5cc6d93b)
```

By the Mac's run optcarrot's checksum is 59662 and its C is byte for byte master 5cc6d93b's.

## 4. The `.expected` checkbox (Old from pr-body.md, not from the live text)

Old:

```
(the file was written from ruby 3.3.6 with that flag; it prints Integers, Symbols, Strings, nil and Arrays of them, nothing whose `inspect` changed since)
```

New:

```
(both files were written from ruby 3.3.6 with that flag, and CRuby 4.0.7 with that flag prints both exactly, run on macOS; they print Integers, Symbols, Strings, nil, false and Arrays of them, one Array in each file nested, nothing whose `inspect` changed since)
```

The box in front of the line stays as it is in the live text. If the live parenthesis already speaks of CRuby 4.0.7 or differs in any other way, stop and send the live line: the pair is then rewritten against it.

## What stays

- The heading "## `make gate` (on this branch merged with current master)".
- In the paragraph "Found with the dead code probe", "(both compilers built on f0263e6c)" and "(both on 0d370b71)": those are this thread's own C comparisons of the first commit, on those bases, and were not rerun. The second commit's comparison is in the paragraph pair 2 of `description-pairs-7238-1.md` adds, and names no base (it compares the first commit with the second).
- After 2 and 3 the description names 0d370b71 once, in that paragraph, and names 5cc6d93b twice.

## pr-body-after-59aabda7.md

It is now the full resulting text as far as it is known here: `pr-body.md` with the four pairs of `description-pairs-7238-1.md`, the six New lines of 1 in the fence, the run line after the fence with one blank line between, the optcarrot box reading "(it did not change: byte-identical to master's at 5cc6d93b)", and the `.expected` parenthesis of 4. Not known here, and left as in `pr-body.md`: whether each of the four boxes is `[ ]` or `[x]` (the optcarrot one is `[ ]` by the Mac's read). A check of structure: the Mac read the optcarrot box at line 41 of the live body; in `pr-body.md` it is line 34, and the fence (five more lines) and the run line with its blank line (two more) make 41. After the four pairs it is line 45.

## What rests on what

The six lines, "ALL GREEN", optcarrot's checksum and identical C, both tests passing, and CRuby 4.0.7 printing both `.expected` files: the Mac's runs, relayed by the coordinator. Checked here by git: 5cc6d93b is the tip of upstream master ("Literal half-open Float ranges are Float ranges, with bsearch and step"), one commit past 33c96724, and 59aabda7 merges with it cleanly. No build or run on 5cc6d93b was made in this thread; this thread's own runs were on cd3ddfe2, on 59aabda7 and on 59aabda7 merged with 33c96724.
