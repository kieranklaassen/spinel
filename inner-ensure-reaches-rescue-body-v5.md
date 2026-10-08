<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
begin
  begin
    raise TypeError, "t"
  ensure
    puts "inner ensure"
  end
rescue TypeError
  puts "rescued"
ensure
  puts "outer ensure"
end
```

prints both ensures and dies with the TypeError uncaught. CRuby prints `inner ensure`, `rescued`, `outer ensure`.

After: CRuby's three lines.

After its ensure body a region hands the exception it holds straight to the enclosing ensure, unless a begin's frame lies between the two. The rescue clauses of the enclosing begin itself share that ensure's frame: no frame lies between, and they were passed. A `synchronize` block and the loop of `select!` directly under such a begin passed them the same way.

Two commits:

1. "One helper emits the test a rescue clause makes of the class" moves the expression `emit_rescue` wrote in line into `emit_rescue_cls_cond`, which takes the class in any C string, and changes no C.
2. "An exception leaving an inner ensure reaches the rescue around it". `EnsureCtx` gains `body_rescue`: the region's first rescue clause, while its body is what is being emitted. Where it is set, the hand-on first asks those clauses' own tests of the class that waits (`emit_ensure_exc_rescue_guard`). Where a clause takes it, the exception is raised again and the enclosing begin's frame brings it to that clause. Where none does, it is handed to the ensure as on master. Clauses that name something other than constants (a splat, a call) cannot be asked ahead: there the exception is raised again, and the arm for no match runs the ensure.

Depends on the pull request "An ensure runs when no rescue clause of its begin matches": its arm for no match is what runs the outer ensure where the clauses cannot be asked ahead, and the helper the two block regions ask, with the `live` flag beside this one, is that pull request's.

Cost (callgrind, gcc -O2, the pull request beneath then this). With nothing raised the two nested begins cost no more: by gcc's layout, two instructions an entry less than beneath (238,349,761 to 236,349,761 for 1,000,000 entries), and the 34 cost programs of the pull request beneath are within 34,000 instructions of what they were. An exception that no clause of the outer begin takes was right on master and now pays those clauses' tests once before it is handed on: 4,156 instructions a round for one class name (83,669,741 to 166,790,869 for 20,000), 4,012 where the inner region is a `synchronize` block (94,803,481 to 175,044,616), and 16,958 for four names in two clauses (85,409,762 to 424,573,146). That is the walk `sp_exc_cls_matches` makes up the hierarchy by name for a class that misses, the same a rescue clause that misses pays on master.

Left alone: everywhere else the C is what it was. Of the 6,613 corpus programs the first commit changes the C of none, and the second of one besides the new test (`test/toplevel_proc_return_ensure.rb`), which prints its `.expected`.

Not here, each the same on master:

- In a rescue or else clause of the enclosing begin the region has no frame, and the hand-on there is as it was. An inner ensure written straight in such a clause still pops a frame that is not its own, so its exception dies uncaught under a caller's `rescue`; with a begin or a rescue modifier between, the exception still goes past that rescue to the outer ensure. Giving those clauses a frame is a change of its own.
- A rescue modifier between the inner ensure and the body: its frame is not counted on master, so under a begin with an ensure alone the inner region does not see it.
- Where the outer rescue clause now runs and itself raises, the outer ensure is skipped, as after any raise in a rescue clause on master: such a program printed the outer ensure's line on its way to dying uncaught, and now ends without that line.

Measured on master 84f5b5020, above the pull request "An ensure runs when no rescue clause of its begin matches". The test is right at -O0 to -O3, with clang and under both stress modes; master has 74 of its 76 lines wrong at every level. `make backtrace-test`, `make share-strings-test` and `make int-min-test` pass. The scale-test ratios are 4.73, 6.14 and 4.13, under their limits. The first commit takes `emit_rescue` from 347 lines to 198 and makes `emit_rescue_cls_cond` of 154; the second takes `emit_begin` from 363 lines to 375 and `emit_ensure_exc_block_out` from 5 to 13, and its `emit_ensure_exc_rescue_guard` is 16 lines and `rescue_clauses_only_name` 12. `ruby tools/gate.rb check` answers 0 with each commit staged.

Of 400 attack programs (the inner region a begin with an ensure, two nested, one with a rescue that does not match beside its ensure, a `synchronize` block, a `select!` block; between it and the outer begin nothing, an `if`, a begin with an ensure, with a rescue that matches, with one that does not, two begins, a rescue modifier as a value and as a statement; in the outer begin's body, rescue clause, else clause and ensure body, the outer begin written out or a method body; its own rescue matching, not matching or absent) master is right on 151, the head beneath on 233 and this on 271; none is lost against either. Of the 129 left, 20 build on neither and 109 are wrong, each printing the bytes of the head beneath: 66 stand in a rescue or else clause and 43 have a rescue modifier between, the first two items above.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, two commits above the pull request beneath on master 84f5b5020: the build of each commit, the test in the seven builds, `ruby tools/gate.rb check` with each commit staged, the C of all corpus programs after each commit against the C beneath it, the tests whose C changed and the new one built and run, `make backtrace-test`, `make scale-test` and `make int-min-test` at each commit, `make share-strings-test` on the head, optcarrot's C by hash, the 34 cost programs beneath and here, six nested ones under callgrind on master, beneath and here, a Fiber killed inside two such begins, and the attack set on the three.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: the pull request "An ensure runs when no rescue clause of its begin matches"
