# PR 7256: description changes for head 9248ea83

Supersedes ../description-changes-rebase-1.md (its head 7e49c724 is gone).
Head 9248ea83 on `claude/next-through-ensure-ade0dn`: cd3ddfe2 and 59aabda7
(PR 7238's two commits, same SHAs), 9826b3a4 (one merge of master 5cc6d93b),
aa7567e7, a054774d, 5bf9f9d6, 2e693ca0, 65a86d7e (the five), 90e84693 (cache
key), 9248ea83 (test for the expression shape). Eight pairs.

Pairs are against `pr-body.md` as handed over (sha256 fad43f3c...), which the
live text equals except in the gate fence, the run line and the optcarrot box;
those three are the Mac's and get their own file after its gate on this head.
Each Old occurs once in pr-body.md. The four spaces before each Old and New
line are this file's quoting, not part of the text to match or to write.

## Pair 1

Old:

    Five commits on top of #7238, one cause each.

New:

    Five commits on top of #7238, one cause each, and two added after review.

## Pair 2

Old:

    which leaves that function 8 lines shorter.

New:

    which leaves that function 9 lines shorter.

## Pair 3

Old:

    `emit_expr_node` is 8 lines shorter, and the edits in `emit_call_body` and `emit_stmt_tail_inner` change a condition in place.

New:

    `emit_expr_node` is 9 lines shorter, and the edits in `emit_call_synchronize_arms` and `emit_stmt_tail_inner` change a condition in place.

## Pair 4

Old:

    The emitted C of the 5,474 programs in `test/*.rb`, the 64 in `benchmark/` and the 142 package tests

New:

    The emitted C of the 5,498 programs in `test/*.rb`, the 64 in `benchmark/` and the 144 package tests

## Pair 5

Old:

    Optcarrot's C (12,255 lines) is identical for every commit, both compilers built on cd3ddfe2.

New:

    Optcarrot's C (12,256 lines) is identical for master 5cc6d93b, the merge and every commit after it.

## Pair 6

Old:

    All five print their `.expected` plain and under `SPINEL_GC_STRESS=1`.

New:

    All five print their `.expected` plain and under `SPINEL_GC_STRESS=1`.

    Added after review: `next_is_block_value` keys its marks by the node table as well as its count and version (no program's C changes), and `test/fiber_block_next_expression_in_call_operand.rb` has a `next` that is the whole of its parentheses, in the receiver or an argument of a call with a block, `Fiber.new { r = ((next 7 if c); [1, 2]).map { |v| v + 1 }; r }.resume`, which answers 7 with #7238's second commit underneath and the fourth commit here.

## Pair 7

Old:

    its commit cd3ddfe2 is underneath with the same SHA; the first two commits here edit the helper it adds

New:

    its two commits, cd3ddfe2 and 59aabda7, are underneath with the same SHAs, then one merge of master; the first two commits here edit the helper it adds

## Pair 8

Old:

    Each commit has a test that fails on the commit before it:

New:

    Each of the five has a test that fails on the commit before it:

## Why each

1, 6. Two commits answer CodeRabbit's two findings; the fix for the first is
   #7238's 59aabda7, this branch adds the test only its stack can pass.
2, 3. The hunk in `emit_expr_node` is 16 lines in, 7 out: 9, not 8 (3124 to
   3115 on this base). `emit_call_body` is no longer touched: master moved the
   synchronize arm to `emit_call_synchronize_arms`.
4. Recounted on the merge (9826b3a4): 5,498 + 64 + 144 = 5,706 programs
   without this branch's six tests. Commit by commit only each commit's own new
   test differs; the whole stack differs from the merge in
   `test/io_close_wakes_parked_reader.rb` and the six new tests.
5. Measured with compilers for 5cc6d93b, 9826b3a4 and each commit after it,
   all in one bin/.
7. The stacking sentence, exact again by SHA, with two commits of #7238.
8. 90e84693 has no test of its own and 9248ea83's test passes on the commit
   before it (59aabda7 underneath and 2e693ca0 are what make it pass). The
   five still do: run again on 2026-10-03 with a compiler per commit, each of
   the five tests fails on the commit before its own (wrong output or no
   build) and passes on its own.
