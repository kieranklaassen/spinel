<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

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

While an ensure body runs, the exception that waits to be raised again lives in two C locals of `emit_begin`, and they are not roots. A begin that body enters takes the exception slot the message was read from, and any raise clears `sp_inflight_cause`, which held the object. The next collection frees both, and the raise after the body hands them on: another String as the message, another object's instance variables, a fault under `SPINEL_GC_STRESS=2`. The two locals are now rooted while the ensure body runs, when an exception waits, so the message and the instance variables are kept.

Not here, the same on master: `$!` read in the ensure body is nil.

Not here, the same on master: the `cause` of an exception that passes through an ensure is nil. "An exception keeps its cause through an ensure" keeps it.

An ensure body that only names nil, true or false, alone or stored in a local or an instance variable, keeps master's C; any call may rescue a raise, so wider is not provable.

Cost: the path with no exception pays for a saved root count. By callgrind (gcc -O2) that is ten instructions on each entry of a begin with an ensure in a small method (135,348,454 to 145,348,454 for 1,000,000 calls), five in a method that roots a local already (531,608,115 to 536,613,755), two for a begin in a loop (112,348,509 to 114,348,520). The C of 121 of the 6,533 corpus programs changes (96 tests, 25 package tests) and of no benchmark. optcarrot's one ensure (`run ... ensure dispose`) is entered once in a run: 2,367,012,915 instructions before, 2,366,980,830 after, checksum 59662.

Measured on master 9922a2c74, above "An exception handed from an inner ensure to the outer one stays alive". The test is right at -O0 to -O3, with clang and under both stress modes; master has 2 of its 26 lines wrong at every level, in a plain run. The 96 tests whose C changed print their `.expected`. `make backtrace-test` passes; the scale-test ratios are 4.73, 6.14 and 4.13, under their limits. `emit_begin` goes from 329 lines to 346 and the new `ensure_body_only_stores` is 14. `ruby tools/gate.rb check` with the change staged answers 0.

A generated set was run on an earlier master, 06064727f, on this change as it stood there: of 84 programs (four ways to raise, seven ensure bodies, three shapes) master printed a wrong message or instance variable for 72 in a plain run and this printed CRuby's answer for all 84, also under `SPINEL_GC_STRESS=2`.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit above the pull request beneath on master 9922a2c74: the build, the test in the seven builds, `ruby tools/gate.rb check` with the change staged, the C of all 6,533 corpus programs against the C beneath, the 96 tests whose C changed and the new one built and run, `make backtrace-test`, `make scale-test`, `make int-min-test`, optcarrot built and run plain and under callgrind, and the 34 cost programs under callgrind.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (above)
- [ ] Depends on: the pull request "An exception handed from an inner ensure to the outer one stays alive"
