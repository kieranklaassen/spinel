<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Before:

```ruby
def churn
  a = []
  4000.times { |i| a << ("filler string number " + i.to_s) }
  a.length
end

def go(n)
  raise ArgumentError, "the message of error number " + n.to_s
ensure
  begin
    churn
  rescue TypeError
  end
  churn
end

begin
  go(0)
rescue => e
  puts e.message
end
```

prints `filler string number 3334`, in a plain run at every level. CRuby prints `the message of error number 0`.

After: CRuby's line.

While an ensure body runs, the exception that waits to be raised again lives in two C locals of `emit_begin`, and they are not roots. A begin that body enters takes the exception slot the message was read from, and any raise clears `sp_inflight_cause`, which held the object. The next collection frees both, and the raise after the body hands them on: another String as the message, another object's instance variables, a fault under `SPINEL_GC_STRESS=2`. The two locals are now rooted while the ensure body runs, when an exception waits.

An ensure body that only names nil, true or false, alone or stored in a local or an instance variable, keeps master's C; any call may rescue a raise, so wider is not provable.

Cost: the path with no exception pays for a saved root count. By callgrind that is ten instructions on each entry of a begin with an ensure in a small method (135.3M to 145.3M for 1,000,000 calls), five in a method that roots a local already, two for a begin in a loop; rooting the two locals where they are declared costs 25, 9 and 32 on the same three programs. The C of 113 of the 6,333 corpus programs changes (90 tests, 23 package tests) and of no benchmark. optcarrot's one ensure (`run ... ensure dispose`) is entered once in a run: 2,375,630,004 instructions before, 2,375,671,476 after, checksum 59662.

Measured on master 06064727f: the 113 programs print what they printed (two fail on master the same way), scale-test keeps master's four ratios, and of 84 generated programs (four ways to raise, seven ensure bodies, three shapes) master prints a wrong message or instance variable for 72 in a plain run and this prints CRuby's answer for all 84, also under `SPINEL_GC_STRESS=2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (above)
- [ ] Depends on: #
