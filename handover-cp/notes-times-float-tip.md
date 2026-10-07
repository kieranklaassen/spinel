# Notes: a boxed String or Array times a Float, on master 42557a3c0e7c (a correction)

The commit is cut a third time on 42557a3c0e7c (e9fd059e9e9010645eaec359938a9ea9ae1f5f53), with one sentence of its message and of its description taken out. The tree is the one of a1ab4dcad78b (05c6f7044805): no line of source or test changes.

## What was wrong in the text

The message and the description of 1f94cd612d0d (on 8dc5522541bb) and of a1ab4dcad78b (on 42557a3c0e7c) say, under "Not covered": "A fold whose count is a typed Float, `[s, 2.5].inject(:*)`, still raises". That was measured on 759d120fd207, where master typed the fold's value a Float. From 8dc5522541bb on master no longer does, and with the piece the fold answers what Ruby answers. The sentence is false on both tips the piece was handed over on; I carried the family's rows from 759d120fd207 across a clean merge and did not run them again. Found by running the family again on 42557a3c0e7c.

## The family on 42557a3c0e7c (3,132 programs, gcc, SPINEL_GC_STRESS unset, 1, 2)

With the piece: 2,030 right, 1,070 wrong, 32 not building; no program prints differently at the three levels. Against the run of the hand-over (759d120fd207, 2,000 right): 3,102 programs print the same bytes; 30 differ, all of them wrong then and right now:

- 10, `[r, 2].inject(:*)` with a typed Integer count: master printed "0 Integer". The bare tip is right there too (master's own cure).
- 20, the fold with a typed Float count (`[r, 2.5].inject(:*)`, written as a literal and as a computed Float): the bare tip raises TypeError ("no implicit conversion of Float into String"); with the piece it prints the repeat. The same on 8dc5522541bb (bare and with the piece).

Right on the bare tip and not with the piece: 0 of those 30. The bare tip's run of the whole family is in progress as this is written; the piece emits master's C for all 3,100 programs that compile, on both tips.

## The texts

times-float-count-pr-body-v3.md and times-float-count-commit-message-v3.txt: v2 less that one sentence. The description's "It holds for every way to the operator: `*=` on a local, an attribute or an element, `send`, `inject(:*)`" now holds for the typed Float count too; test/poly_times_float_count.rb already pins a fold with a boxed count.
