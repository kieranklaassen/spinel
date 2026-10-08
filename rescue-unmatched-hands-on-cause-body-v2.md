<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def go
  begin
    raise ArgumentError, "first"
  rescue ArgumentError
    raise TypeError, "second"
  end
end

begin
  begin
    go
  rescue IOError
    puts "io"
  end
rescue => g
  p g.cause
end
```

prints `nil`, and inside another handler it prints that handler's exception. After, as CRuby: `#<ArgumentError: first>`.

The cause is decided at every raise, from what is being handled there. A rescue none of whose clauses match hands the exception on by raising it again, and where it passes nothing is being handled, or something else is. The arm for no match, and the rescue modifier's arm for an exception that is no StandardError, now call `sp_exc_pass_cause`, which gives that raise the cause the exception was raised with. An object that carries a cause of its own keeps it.

One cause is not handed on: an exception an ensure body had in flight. A `return` or a `break` out of that body drops the exception, but `sp_inflight_cause` still names it, and the next raise takes it as its cause. Handing that on would carry the dropped exception past a rescue that hid it before, so a raise whose cause was only in flight is left as it was (`sp_pending_cause_own`, set in `sp_raise_cls`), and such a program answers what it answered (the test's `after_return`, `after_break` and `cleanup`).

Depends on "An exception raised again never takes its own effect as its cause": a cause handed on reaches rescues where the first exception is raised again, and without that fix it would close a ring there.

Left alone: a rescue with a clause that matches is the C it was, and a raise with nothing handed on takes its cause as before. Of the 6,448 corpus programs the C of 4,674 is identical. 1,774 differ, by the call in the arm for no match: 1,765 print their `.expected` as they did, one is the new test, and 8 need an argument, a file or input the comparison does not give and print the same bytes with and without the change.

Cost, in instructions (callgrind, -O2), the fix beneath then this: a raise that a clause rescues, 12 more (20,000 of them: 117,665,169 to 117,905,246), which is the mark `sp_raise_cls` sets; a raise in a rescue handed on by a rescue that does not match, 40 more a round of two raises (162,932,817 to 163,733,234); a begin that raises nothing, none (a million turns: 98,353,300 and 98,353,314).

Not here, each the same on master:

- An ensure on the way still loses the cause: "An exception keeps its cause through an ensure" stands above this.
- A raise from an ensure body with an exception in flight, handed on by a rescue that does not match, arrives with no cause (CRuby: the one in flight). It is the case above, which cannot be told from the dropped one here.
- The raise after a `return` or `break` out of an ensure body takes the dropped exception as its cause where it is rescued directly (CRuby: none).

The test hands an exception with a cause on through a typed rescue, two of them, a method, a block, a rescue modifier as a value and as a statement, with an exception being handled where it passes and with none; a cause given by `cause:`, a cause of a cause, `cause: nil`; a class under Exception; and the three shapes of the dropped exception.

Measured on master 8dc552254, above "An exception raised again never takes its own effect as its cause". The test is right at -O0 to -O3, with clang and under both stress modes; master prints 13 of its 19 lines wrong at every level. Of 341 attack programs (an exception raised 16 ways: in a rescue, with `cause:`, with `cause: nil`, with nothing handled, after a cleanup that failed and was rescued, by a bare `raise`, as the rescued object, after a `return` and after a `break` out of an ensure body, as an object saved in a rescue, after a rescue nested in the rescue, from an ensure body, after a rescue that ended, from a method called in the rescue, at the end of a chain of three, and as a ZeroDivisionError; a StandardError and a class under Exception; handed on 11 ways: not at all, by a typed rescue, through a method, by two rescues, by a rescue modifier as a value and as a statement, inside another handler, in a block, by a rescue with a list, by a rescue with an ensure, and after an earlier rescue ended) the fix beneath is right on 201 and this on 290; none is lost. Of the 51 left, 31 pass a begin with an ensure, the first item above: 11 of them now carry the cause and their ensure still does not run, which "An ensure runs when no rescue clause of its begin matches" is for. 16 raise from an ensure body with an exception in flight, the second item, and 4 raise after a `return` or `break` out of an ensure body and are rescued directly, the third. 40 of the 51 print master's bytes. `make backtrace-test` passes. The scale-test ratios are master's (1.71, 4.74, 6.13, 4.17). `emit_stmt_inner` goes from 713 lines to 714 and `emit_and_or_begin_expr` from 338 to 339; `ruby tools/gate.rb check` with the change staged answers 0. Into master 42557a3c0 the merge is clean, and that master changes one line of `emit_stmt_inner`, so this is rebuilt there before it is opened.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: "An exception raised again never takes its own effect as its cause"
