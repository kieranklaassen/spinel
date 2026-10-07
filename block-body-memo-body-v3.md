<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`block_of_body` maps a statement list to its BlockNode. The map was made at the first ask, one entry for each node the table then had, and every later ask tested its node against the table's count of the moment. A refused method that returns nothing, in a class that is never built, is emitted again with a raising body (`deferred_raise_body`) made of nodes appended after that, and `emit_stmts` asked for an entry past the end of the map. A method with a value goes through `emit_stmts_tail`, which does not ask. What the read finds decides whether the raising body opens with a block's local resets.

A plain compile of a corpus test does it. On master at 06064727f6a2, with the frames outside the compiler left out and each frame written without its number sign and address:

```
$ tools/san_check.sh -v test/computed_undef_beside_string_class_eval.rb
san-check: src/codegen_stmt.c:13925: heap-buffer-overflow in block_of_body (test/computed_undef_beside_string_class_eval.rb)
==23660==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x511000012bd4 at pc 0x564ac9d1efd9 bp 0x7ffc9d3f7e40 sp 0x7ffc9d3f7e30
READ of size 4 at 0x511000012bd4 thread T0
    frame 0: block_of_body src/codegen_stmt.c:13925
    frame 1: emit_stmts src/codegen_stmt.c:13951
    frame 2: emit_method src/codegen.c:5184
    frame 3: codegen_program src/codegen.c:16379
    frame 4: main src/main.c:890

0x511000012bd4 is located 0 bytes after 212-byte region [0x511000012b00,0x511000012bd4)
allocated by thread T0 here:
    frame 1: block_of_body src/codegen_stmt.c:13915
    frame 2: emit_stmts src/codegen_stmt.c:13951
    frame 3: emit_method src/codegen.c:5184
    frame 4: codegen_program src/codegen.c:16358
    frame 5: main src/main.c:890

SUMMARY: AddressSanitizer: heap-buffer-overflow src/codegen_stmt.c:13925 in block_of_body
san-check: 1 programs, 1 with a report
```

With `SPINEL_DEFER_REFUSALS=1` any refused method that returns nothing is emitted that way: 13 of the 264 programs of test/reject/ report the same read on that master, none with this change.

The map keeps its own length now and is extended over the nodes appended since, as `cg_block_owner`'s and `comp_node_ord`'s are. The command above then reports nothing, and no generated C changes: against 06064727f6a2 `tools/cident.sh` reads 6334 identical, 0 differ. No test is added; the corpus test is the reproducer under `make san-check`.

The other maps sized by the node count are rebuilt when the count moves, keep their own length, or live inside one call that appends no node. This was the only one that outlives an append.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no new test)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
