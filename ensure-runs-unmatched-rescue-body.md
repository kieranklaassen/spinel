<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

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

Left alone: a begin that lacks either clause emits the C it did, and the path with no exception gains nothing. An ensure is still skipped when a rescue clause or the else clause of its begin raises.

Measured on master 06064727f: 20 corpus programs' C changes, in the arm for no match of a begin that has both clauses, and they print what they printed (6,313 identical, 21 differ with the new test); scale-test keeps master's four ratios.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
