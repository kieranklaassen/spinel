<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def wrap(list)
  begin
    raise ArgumentError, "low"
  rescue ArgumentError
    list.each { |x| next if x < 2 }
    p $!
    raise KeyError, "high"
  end
end

begin
  wrap([1, 2, 3])
rescue KeyError => e
  p e.cause
end
```

prints

```
nil
nil
```

After, as CRuby:

```
#<ArgumentError: low>
#<ArgumentError: low>
```

The `next` popped the ArgumentError off the handled stack, although the block is inside the rescue clause and never leaves it. The clause's own pop at its end then took `sp_rescue_sp` below zero, so the caller's `$!` was lost as well, and the new test, which runs a dozen such clauses, ends in a segmentation fault on master at -O1 and above.

An exit pops the rescue bodies it leaves, and it told them by frame depth: those at or above the depth of its target. A rescue clause runs with its frame already popped, so a loop, an ensure region, an inlined method or a break wrapper opened inside the clause stands at the clause's own depth, and an exit to it counted the clause too.

Each rescue body now records what was open at its entry (the loop depth, the ensure depth, the return funnel), and an exit to a loop, an ensure region or an inlined method's funnel counts the bodies begun inside its target. A return, next or break deferred through an ensure pops at the deferral only the bodies inside that region, and each ensure tail pops the ones between it and the next target, so the ensure body still reads the clause's `$!`. A break wrapper puts `sp_rescue_sp` back at its landing, as it already does the other depths: a thrown break passes frames that restore their own mark, so no count at the break could be right. Only a wrapper whose body handles an exception takes that snapshot.

A rescue modifier's fallback is registered as a rescue body too, and it has to be in this commit. It never was, so `x rescue next` left its exception handled; inside a rescue clause that leak and the wrong pop cancelled out, and four of the generated programs below that are right on master go wrong when only the count is repaired.

The first commit is a refactor the fix stands on: `emit_unwind` takes the two counts as arguments. It changes no generated C (6,369 corpus programs identical).

Left alone: every exit that does leave the function, and every program with no exit under a rescue body. The C of 6,363 corpus programs is identical.

Cost: none on a path that was right. A break wrapper whose body handles an exception reads `sp_rescue_sp` once on the way in and writes it once at its landing. optcarrot's C is unchanged.

Not here: a `throw` out of a rescue clause to a `catch` around it, and a proc's `return` to its method out of one, leave the clause's exception handled, here as on master. A break deferred through two nested ensures still pops the clauses between them at the loop's exit, after the outer ensure body.

Measured on master a39414338: the test is right at -O0 to -O3, with clang, with `--debug` and under both stress modes (master: 44 of its 50 lines wrong at -O0, a segmentation fault above). Of 58 generated programs with an exit inside a rescue clause (while, until, for, `each`, `times`, `upto`, `map`, `find`, a yielding method's return, each also through an ensure or a rescue inside the loop), master is wrong for 45 and all 58 are right here. Of 208 more (52 bodies, each in a clause, in a clause inside a clause, in a method-level rescue and in an ensure body), master is wrong for 108; here 204 are right, none that master had right is lost, and the 4 left are master's own: the `throw` out of a clause named above. The C of six existing tests changes (exc_frame_break_next_pops, exception_cause, fiber_thread_enumerator_block_next, loop_break_runs_ensure, socket_nonblock, valued_break_ensure) and each still prints what it should. `make backtrace-test` passes; the scale-test ratios are master's (1.71, 4.73, 6.05, 4.18).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
