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

The second commit keeps the backtrace such an exception had. In a `--debug` build the raise after the ensure body took a new snapshot at the begin, where the old arm had set `sp_bt_keep`. The snapshots are now counted (`sp_bt_gen`), and the raise after the ensure body keeps the frames when the count is the one read as no clause matched. `test/backtrace/pass_through_ensure.rb` runs under `make backtrace-test`.

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

Not here: an ensure body that raises and rescues an exception of its own has taken the one backtrace buffer for it, so the exception passing then shows the begin's frames and up, not the ones below. An ensure with no rescue clause beside it still cuts the frames in a debug build, as on master. An ensure is still skipped when a rescue clause or the else clause of its begin raises.

Left alone: a begin that lacks either clause emits the C it did.

Cost: entering a begin with both clauses pays one instruction more (150,346,991 against 149,346,991 for 1,000,000 entries, callgrind, -O2). A raise costs what it did in a plain build (327,054,091 against 327,054,064 for 200,000); in a debug build, where each takes a backtrace of some 240,000 instructions, it gains 35 (48,074,141,998 against 48,067,141,985).

Measured above the ensure fix on master 8684d54ce: both tests are right at -O0 to -O3, with clang and under both stress modes. Of 6,343 corpus programs the C of 20 changes besides the new test, each in a begin that has both clauses, and they print what they printed; 6,322 are identical. optcarrot's C is the ensure fix's; the scale-test ratios are master's (1.71, 4.74, 6.06, 4.18).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged by these two commits)
- [ ] Depends on: "An ensure keeps the exception it holds while its body runs"
