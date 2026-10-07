<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`make san-check` reports one program on master: compiling a corpus test, the compiler reads four bytes past one of its own maps. Only the sanitizer build sees it; a plain build finishes and writes the same C (below). On master at 8dc5522541bb:

```
$ tools/san_check.sh test/computed_undef_beside_string_class_eval.rb
san-check: src/codegen_stmt.c:14548: heap-buffer-overflow in block_of_body (test/computed_undef_beside_string_class_eval.rb)
san-check: 1 programs, 1 with a report
```

With this change the same command prints `san-check: 1 programs, 0 with a report`, and `make san-check` over the corpus prints `san-check: 6447 programs, 0 with a report`.

`block_of_body` maps a statement list to its BlockNode. The map was made at the first ask, one entry for each node the table then had, and every later ask tested its node against the table's count of the moment. A refused method that returns nothing, in a class that is never built, is emitted again with a raising body (`deferred_raise_body`) made of nodes appended after that, and `emit_stmts` asked for an entry past the end of the map. A method with a value goes through `emit_stmts_tail`, which does not ask. What the read finds decides whether the raising body opens with a block's local resets.

The report under `-v`, with the frames outside the compiler left out and each frame written without its number sign and address:

```
==28373==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x511000012d14 at pc 0x5620adab47cf bp 0x7ffdf30a64d0 sp 0x7ffdf30a64c0
READ of size 4 at 0x511000012d14 thread T0
    frame 0: block_of_body src/codegen_stmt.c:14548
    frame 1: emit_stmts src/codegen_stmt.c:14574
    frame 2: emit_method src/codegen.c:5240
    frame 3: codegen_program src/codegen.c:16509
    frame 4: main src/main.c:890

0x511000012d14 is located 0 bytes after 212-byte region [0x511000012c40,0x511000012d14)
allocated by thread T0 here:
    frame 1: block_of_body src/codegen_stmt.c:14538
    frame 2: emit_stmts src/codegen_stmt.c:14574
    frame 3: emit_method src/codegen.c:5240
    frame 4: codegen_program src/codegen.c:16488
    frame 5: main src/main.c:890

SUMMARY: AddressSanitizer: heap-buffer-overflow src/codegen_stmt.c:14548 in block_of_body
```

With `SPINEL_DEFER_REFUSALS=1` any refused method that returns nothing is emitted that way: 13 of the 267 programs of test/reject/ report the same read on that master, none with this change.

The map keeps its own length now and is extended over the nodes appended since, as `cg_block_owner`'s and `comp_node_ord`'s are. No generated C changes: against 8dc5522541bb `tools/cident.sh` reads 6447 identical, 0 differ. No test is added; the corpus test is the reproducer under `make san-check`.

The other maps sized by the node count are rebuilt when the count moves, keep their own length, or live inside one call that appends no node. This was the only one that outlives an append.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no new test)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
