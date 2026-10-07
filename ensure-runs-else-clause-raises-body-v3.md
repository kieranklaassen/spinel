<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def go(s)
  Integer(s)
rescue TypeError
  puts "not reached"
else
  raise IOError, "from else"
ensure
  puts "ensure"
end

begin
  go("1")
rescue IOError
  puts "caught"
end
```

prints `caught`. CRuby prints `ensure` first.

After: both lines.

The else clause was emitted after the begin's frame was popped, so what it raised went to the enclosing frame, past the ensure. The frame is now popped after the else clause, and a flag set before it sends the landing by the rescue clauses, which are not for what the else raised, straight to the ensure.

Left alone: a begin with no else, or with an else and no ensure, emits the C it did.

Cost: the flag, two instructions on the way in, in a begin that has an else and an ensure (150,347,764 against 148,347,764 for 1,000,000 entries, callgrind, -O2).

Measured above "An ensure runs when a rescue clause of its begin raises" on master c121a0cbd: the test is right at -O0 to -O3, with clang and under both stress modes (master: 8 lines wrong, dying uncaught, at every level), the seven tests of the pull requests beneath stay right at every level, and `make backtrace-test` passes. Of 6,368 corpus programs the C of 6 changes besides the new test, each in a begin that has an else and an ensure, and they print what they printed; 6,361 are identical. The scale-test ratios are master's (1.71, 4.73, 6.05, 4.18).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged by this commit)
- [ ] Depends on: "An ensure runs when a rescue clause of its begin raises", above which it is built, and through it the pull requests that one names
