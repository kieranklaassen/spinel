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

The cause is decided at every raise, from what is being handled there. A rescue none of whose clauses match hands the exception on by raising it again, and where it passes nothing is being handled, or something else is. The arm for no match, and the rescue modifier's arm for an exception that is no StandardError, now call `sp_exc_pass_cause`, as the raise after an ensure body does: it gives that raise the cause the exception was raised with. An object that carries a cause of its own keeps it.

Depends on "An exception keeps its cause through an ensure", whose `sp_exc_pass_cause` it calls, and on "An exception raised again never takes its own effect as its cause": a cause handed on reaches rescues where the first exception is raised again, and without that fix it would close a ring there.

Left alone: a rescue with a clause that matches is the C it was, and a raise with nothing handed on takes its cause as before. Of the 6,540 corpus programs the C of 4,719 is identical. 1,820 differ, by the one call this commit emits (1,711 tests, 109 package tests): 1,708 of the tests print their `.expected`, three (argf_walks_argv, promote_float_to_int, promote_str_to_i_bigint) fail when run bare like this on master too, in the same way, and the package tests were not run here.

Cost (callgrind, gcc -O2): a raise handed on by a rescue that does not match pays 2 instructions with no cause to carry (134,858,641 to 134,896,385 for 20,000) and 10 a round where the exception has one (176,806,538 to 177,013,019 for 20,000 rounds of two raises). A raise that a clause rescues pays nothing (42,841,463 and 42,840,335 for 20,000), and no other of the 34 cost programs rose by more than 20,000 instructions.

The test hands an exception with a cause on through a typed rescue, two of them, a method, a block, a rescue modifier as a value and as a statement, with an exception being handled where it passes and with none; a cause given by `cause:`, a cause of a cause, `cause: nil`; a class under Exception; and the three shapes of an exception an ensure body dropped, which the pull request "An exception an ensure body dropped is not a later raise's cause" beneath keeps from being a cause.

Measured on master 9922a2c74, above the pull requests named. The test is right at -O0 to -O3, with clang and under both stress modes; master has 14 of its 26 lines wrong at every level. `make backtrace-test` passes. The scale-test ratios are 4.73, 6.14 and 4.13, under their limits. `emit_stmt_inner` goes from 721 lines to 722 and `emit_and_or_begin_expr` from 339 to 340. `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit above the pull request beneath on master 9922a2c74: the build, the test in the seven builds, `ruby tools/gate.rb check` with the change staged, the C of all 6,540 corpus programs against the C beneath, the 1,711 tests whose C changed and the new one built and run, `make backtrace-test`, `make scale-test`, `make int-min-test`, optcarrot's C by hash, and the 34 cost programs under callgrind.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: the pull request "An exception keeps its cause through an ensure"
