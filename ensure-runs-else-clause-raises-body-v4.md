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

The else clause was emitted after the begin's frame was popped, so what it raised went to the enclosing frame, past the ensure. The frame is now popped after the else clause, and a flag set before it sends the landing by the rescue clauses, which are not for what the else raised, straight to the ensure. A `next` that an ensure inside the else clause hands on to this one finds one frame more than it did: the hand-on pops the frames down to the region's base there too (`emit_ensure_next_chain`).

Left alone: a begin with no else, or with an else and no ensure, emits the C it did.

Cost (callgrind, gcc -O2): the flag, two instructions on the way in, in a begin that has an else and an ensure (148,349,116 to 150,349,116 for 1,000,000 entries). The other 33 cost programs are within 20,000 instructions of what they were.

The test raises from an else clause beside an ensure: an error the begin's own clause names still goes on; as a value, and an else that raises nothing; return, next and break from the else clause run the ensure once; a begin of its own inside the else; a throw from the else; many times over, so the frames balance; a next under an ensure of its own inside the else clause, alone and in the body of a begin with a rescue, seventy turns each and then a rescue after; and `exit` from the else clause.

Measured on master 9922a2c74, above the pull requests named. The test is right at -O0 to -O3, with clang and under both stress modes; master has 14 of its 29 lines wrong and ends with status 1 at every level. `make backtrace-test` passes. Of the 6,542 corpus programs the C of 6 changes besides the new test, all of them tests, each in a begin that has an else and an ensure; the 6 print their `.expected`, and 6,535 are identical. The scale-test ratios are 4.73, 6.14 and 4.13, under their limits. `emit_begin` goes from 358 lines to 378. `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit above the pull request beneath on master 9922a2c74: the build, the test in the seven builds, `ruby tools/gate.rb check` with the change staged, the C of all 6,542 corpus programs against the C beneath, the 6 tests whose C changed and the new one built and run, `make backtrace-test`, `make scale-test`, `make int-min-test`, optcarrot's C by hash, and the 34 cost programs under callgrind.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: the pull request "An ensure runs when a rescue clause of its begin raises"
