<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A `next` that has something to leave on its way out of a block gave a wrong answer without a message. Five commits on top of #7238, one cause each.

```ruby
c = ARGV.length == 0
p proc { begin; next 5 if c; 7; ensure; puts "e"; end }.call   # e, 5: answered nil, printed nothing
p proc { begin; next 5 if c; 7; rescue; 0; end }.call          # 5: answered nil
p [1, 2].map { |x| c && (next 4); 5 }                          # [4, 4]: was [5, 5]
p proc { x = (c ? (next 5) : 7); x + 1 }.call                  # 5: was 6
```

**A next in a proc runs the ensure it leaves and pops the rescue frames.** A `next` that leaves a proc or lambda is a `return` from its C function, and it returned from inside the region: the `ensure` did not run and the value never reached the proc's slot. `Mutex#synchronize` is such a region, so `stop = lambda { lock.synchronize { next if done; ... } }` returned with the Mutex held and the second call raised "deadlock; recursive locking". With a `rescue` and no `ensure` the handler frame stayed on the stack of 64 and the 65th call raised SystemStackError. The `next` now defers through the innermost open ensure as a lambda's `return` does (`emit_return_deferred`, the arm `emit_return` had, which both call), and outside one it pops the frames it leaves.

**A next inside a begin that is a value leaves the proc with its value.** A proc answers through `_sp_proc_poly_ret`, and its exits found that slot in `g_result_var`. A begin whose value is used puts its own temp there, so the `next` stored into the temp: `proc { begin; next 5 if c; 7; rescue; 0; end }.call` was nil, a lambda's `return` in that place did not build, and a `return` from a `synchronize` or `select!` block there was nil. `proc_ret_slot` names the proc's slot from what the proc emitter records, and the exits read it.

**An iterator that ends a begin inside a proc is the begin's value.** The same mistake in one more place, found while testing the commit above: `proc { |a| y = begin; a.each { |v| v }; rescue; 0; end; [y, 1] }.call([1, 2])` answered nil, because the tail store of the iterator's receiver took the begin's temp for the proc's slot and returned. It leaked the rescue frame as well.

**A next inside an expression leaves the block.** The expression emitter takes `next v` as v. That is right where the block's value is written, at the end of the block or of an arm of the `if` it ends in (#3026). Anywhere else, `c && (next 4)`, `x = (c ? (next 5) : 7)`, `[v, (next -1 if v == 3), v]`, `"v#{v == 2 ? (next "skip") : v}"`, the block went on with the value. `next_is_block_value` marks from the source the `next`s that are the block's value; any other is written as the statement it is, inside a statement expression. The arm moves out of `emit_expr_node` into `emit_next_expr`, which leaves that function 8 lines shorter.

**A Fiber block with an ensure builds in a method a proc returns from.** `def m; pr = proc { return 1 }; Fiber.new { begin; 3; ensure; puts "e"; end }.resume; end` stopped at the C compiler with "label '_pr_done' used but not defined": `emit_fiber_new` parked `g_fn_pr_label` but not the method's own funnel, and the block's ensure tail jumped to it. It parks both now. Thread.new and Enumerator.new the same.

No function over 1,000 lines grows: `emit_expr_node` is 8 lines shorter, and the edits in `emit_call_body` and `emit_stmt_tail_inner` change a condition in place.

The emitted C of the 5,474 programs in `test/*.rb`, the 64 in `benchmark/` and the 142 package tests is the same before and after, commit by commit, with one exception: `test/io_close_wakes_parked_reader.rb`, whose `stop` lambda is the Mutex case above and now unlocks (the test passes before and after). Optcarrot's C (12,255 lines) is identical for every commit, both compilers built on cd3ddfe2.

Each commit has a test that fails on the commit before it: `test/proc_next_runs_ensure.rb`, `test/proc_next_in_value_begin.rb`, `test/proc_iterator_ends_value_begin.rb`, `test/next_inside_expression.rb` (map, each, select, inject, while, until, for, proc, lambda, Fiber, Thread and Enumerator blocks) and `test/fiber_ensure_in_proc_return_method.rb`. All five print their `.expected` plain and under `SPINEL_GC_STRESS=1`.

Still not right, each left for a change of its own: `return` and `break` in the middle of an expression are refused as before ("unsupported expression"); `a and next v` as a block's last expression does not build, before or after; in a proc, a `next` in the block of `synchronize` leaves the proc and not that block.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the files were written from ruby 3.3.6 with that flag; they print Integers, Symbols, Strings, true, false, nil and Arrays of them, no Hash, nothing whose `inspect` changed since)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change; OPTCARROT_LINE)
- [x] Depends on: #7238 (its commit cd3ddfe2 is underneath with the same SHA; the first two commits here edit the helper it adds)
