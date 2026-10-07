<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def go
  raise ArgumentError, "y"
rescue ArgumentError
  puts "logged"
  raise
ensure
  puts "ensure"
end

begin
  go
rescue ArgumentError
  puts "caught"
end
```

prints `logged` and `caught`. CRuby prints `ensure` between them.

After: CRuby's three lines.

The begin's one frame is popped when it lands, so the rescue clauses ran with no frame of this begin, and what they raised went to the enclosing one, past the ensure. A new `raise`, a call that raises, an `exit` and a `throw` in the clause skipped the ensure the same way. A clause's body now runs under a frame of its own when the begin has an ensure. It is pushed on the landing path, so a begin that raises nothing enters one frame as before. Its landing stores the exception for the ensure, as the arm for no match does; a `retry` pops the frame before it jumps, and `return`, `break` and `next` count it already.

Left alone: a begin with no ensure emits the C it did.

Cost: a raise that a clause rescues pays that clause's frame, 83 instructions (35,986,316 against 34,326,316 for 20,000, callgrind, -O2). A begin with rescue clauses and an ensure that raises nothing emits the same C on its way and enters the one frame, but the function now holds a second setjmp and gcc spends three instructions more on it (148,347,764 against 145,347,764 for 1,000,000 entries).

Measured above "An exception keeps its cause through an ensure" on master c121a0cbd: the test is right at -O0 to -O3, with clang and under both stress modes (master: 12 lines wrong at every level), the six tests of the pull requests beneath stay right at every level, and `make backtrace-test` passes. Of 6,367 corpus programs the C of 23 changes besides the new test, each in a begin that has rescue clauses and an ensure, and they print what they printed; 6,343 are identical. The scale-test ratios are master's (1.71, 4.73, 6.05, 4.18).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged by this commit)
- [ ] Depends on: "An exception keeps its cause through an ensure", whose helper stores the exception for the ensure, and through it the pull requests that one names
