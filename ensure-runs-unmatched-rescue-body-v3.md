<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def go
  raise TypeError, "t"
rescue ArgumentError
  puts "not reached"
ensure
  puts "ensure"
end

begin
  go
rescue TypeError
  puts "caught"
end
```

prints `caught`. CRuby prints `ensure` first.

After: both lines.

A begin with rescue clauses and an ensure has one frame. On landing the clauses run with that frame popped, and the arm for no match raised again at once: a jump to the enclosing frame, past the ensure, so a lock stayed held and a file stayed open. `exit` inside a begin with a bare rescue skipped the ensure the same way. That arm now stores the exception as a begin with no rescue does and falls into the ensure, which raises it again after its body.

The second commit keeps the backtrace such an exception had. In a `--debug` build the raise after the ensure body took a new snapshot at the begin, where the old arm had set `sp_bt_keep`. A debug build now saves the frames as no clause matches (`sp_bt_save`) and puts them back for the raise after the ensure body (`sp_bt_restore`), so they also survive an ensure body that raises and rescues an exception of its own or resumes a Fiber, either of which takes the one buffer. The lines are emitted under `--debug` only: against the first commit a plain build's C is the same for all 6,352 corpus programs. `test/backtrace/pass_through_ensure.rb` runs five such ensure bodies under `make backtrace-test`.

Depends on "An ensure keeps the exception it holds while its body runs". This sends an exception to an ensure body that master skipped, and without that fix the body runs with the exception unrooted:

```ruby
def churn
  a = []
  4000.times { |i| a << ("filler string number " + i.to_s) }
end

def go(n)
  raise ArgumentError, "the message of error number " + n.to_s
rescue TypeError
ensure
  begin
    churn
  rescue TypeError
  end
end
```

would hand `filler string number 3334` to the caller's `rescue => e` as `e.message`, where master and the two together give `the message of error number 0`.

Not here: an ensure with no rescue clause beside it still cuts the frames in a debug build, as on master. An ensure is still skipped when a rescue clause or the else clause of its begin raises.

Left alone: a begin that lacks either clause emits the C it did.

Cost: entering a begin with both clauses costs what it did (149,347,033 against 149,347,019 instructions for 1,000,000 entries, callgrind, -O2). A raise that no clause matches now runs the ensure body and is raised again, 707 instructions more each (134,605,945 against 120,461,617 for 20,000). In a debug build, where each raise takes a backtrace of some 240,000 instructions, the first commit alone takes a second one (4,977,081,625) and the second commit saves it (4,791,801,625, against 4,776,103,885 before).

Measured above the ensure fix on master 26d456ec1: the tests are right at -O0 to -O3, with clang and under both stress modes, and `make backtrace-test` passes. Of 6,352 corpus programs the C of 20 changes besides the new test, each in a begin that has both clauses, and they print what they printed; 6,331 are identical. optcarrot's C is the ensure fix's; the scale-test ratios are master's (1.71, 4.73, 6.05, 4.18).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged by these two commits)
- [ ] Depends on: "An ensure keeps the exception it holds while its body runs"
