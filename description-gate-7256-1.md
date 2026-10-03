# PR 7256: gate block for head 9248ea83

For the session on the Mac. STOP if any Old below does not occur exactly once
in the live description; change nothing in that case and say which.

The four spaces before each Old and New line are this file's quoting. They are
NOT part of the text to match or to write: the live fence lines start at the
first column, and so do their replacements. Inside the `Tests:` line the runs
of spaces are the gate's own and are part of the text.

Pairs 1 to 3 are against the LIVE text as the coordinator quoted it to this
thread on 2026-10-03 at 07:52 UTC (read by the Mac, not by this thread). Pair
4's Old is quoted from `pr-body.md` as handed over and is NOT known live: see
its note.

The run these lines come from is the Mac's, not this thread's: `make gate` on
9248ea83, 2026-10-03 07:45 to 07:51 UTC. 9248ea83 contains master 5cc6d93b by
the merge 9826b3a4, and master had not moved, so nothing was merged for the run.

None of these pairs touches text that a pair of `description-changes-2.md`
touches. That file's pair 5 is the prose sentence "Optcarrot's C (12,255
lines) is identical for every commit, both compilers built on cd3ddfe2.", this
thread's own commit-by-commit compare; pair 3 here is the checklist box, the
Mac's compare against master. Both stay, and they agree. Either file can be
applied first.

## Pair 1: the fence (the six lines between the ``` lines)

Old:

    scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
    scale-test: work at 4x the program is 4.82x (linear 4.00, limit 5.20)
    scale-test: work at 4x the program, compiled to C, is 6.31x (limit 6.90)
    scale-test: call-shape work at 4x the units, compiled to C, is 4.25x (linear 4.00, limit 4.50)
    Tests:     5602 pass,        0 fail,        0 error
    gate: ALL GREEN

New:

    scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
    scale-test: work at 4x the program is 4.82x (linear 4.00, limit 5.20)
    scale-test: work at 4x the program, compiled to C, is 6.29x (limit 6.90)
    scale-test: call-shape work at 4x the units, compiled to C, is 4.24x (linear 4.00, limit 4.50)
    Tests:     5626 pass,        0 fail,        0 error
    gate: ALL GREEN

## Pair 2: the run line, only the words that change

Old:

    at 58f467d5 plus this branch.

New:

    on the branch head 9248ea83, which contains master 5cc6d93b.

The line then reads: "Run on macOS (arm64) on the branch head 9248ea83, which
contains master 5cc6d93b. macOS has no `timeout`, ..." with the rest as it is.

## Pair 3: the optcarrot box

Old:

    byte-identical to master's at 58f467d5)

New:

    byte-identical to master's at 5cc6d93b)

## Pair 4: the CRuby box (Old from pr-body.md, NOT known live)

Old:

    (the files were written from ruby 3.3.6 with that flag; they print Integers, Symbols, Strings, true, false, nil and Arrays of them, no Hash, nothing whose `inspect` changed since)

New:

    (the files were written from ruby 3.3.6 with that flag; they print Integers, one Float, Symbols, Strings, false, nil and Arrays of them, four of which hold Arrays, no Hash, nothing whose `inspect` changed since; CRuby 4.0.7 run with that flag prints each of the six exactly)

The Old's list is not true of the files and was not when the PR was opened;
it stays in the Old because that is the text to match. The New's list is from
a read of every line of the six `.expected` files at 9248ea83: Integers, one
Float (`3.0`, test/proc_next_runs_ensure.rb.expected:10, from
`p pf.call(1.5)`), Symbols, Strings, `false` (three times; `true` is never
printed), `nil`, and Arrays of those, four of which hold Arrays
(test/next_inside_expression.rb.expected lines 3, 7 and 28,
test/proc_iterator_ends_value_begin.rb.expected line 2). No Hash. `3.0.inspect`
is "3.0" under ruby 3.3.6 (run here) and the Mac's CRuby 4.0.7 printed that
file exactly, which covers the Float.

If the Mac already replaced this parenthesis when it ticked the box, the Old
will not occur: then leave the box ticked and make only this change by hand,
wherever the live sentence counts the tests or lists what they print: the
list is the New's above, and there are six new tests now
(`test/fiber_block_next_expression_in_call_operand.rb` is the sixth), and the
Mac's CRuby 4.0.7 printed each `.expected` exactly. That 4.0.7 run is the
Mac's; this thread has ruby 3.3.6 only.
