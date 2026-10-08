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

def mid
  go
ensure
  $n = 1
end

begin
  mid
rescue => g
  p g.cause
end
```

prints `nil`. CRuby prints `#<ArgumentError: first>`.

After: CRuby's line.

An ensure holds the exception in its region's locals while its body runs and raises it again after, and that raise decided the cause anew, from what was being handled there: nothing, or the wrong exception where the ensure sits inside another handler. The cause now waits with the exception, in a local each of the three kinds of region declares (a begin, `Mutex#synchronize`, the loop of `select!` and its kin). It is a root while the ensure body runs, it is handed to an outer ensure with the rest, and `sp_exc_pass_cause` gives it to the raise. A `cause:` given to the raise, `cause: nil` too, is kept the same way, and an object that carries a cause of its own keeps it.

Two commits. The first moves the store of a landed exception into the region's locals and the raise after the ensure body, each written out three times, into `emit_ensure_exc_store` and `emit_ensure_exc_raise`, and changes no C (the 6,537 corpus programs compared are identical). The second adds the cause to them.

Depends on "An exception an ensure body dropped is not a later raise's cause" and "An ensure body's exception stays with its fiber". A raise in an ensure body takes the exception that body runs for as its cause, and this change keeps a cause where the raise after an outer ensure used to decide it anew. Without those two, the exception a `return` out of an ensure body dropped, or the one an ensure body of another fiber runs for, would be kept as a cause the same way, in programs that print `nil` on master only because an ensure on the way lost it. And on "An exception raised again never takes its own effect as its cause", above which it is built, and through that one the pull requests it names.

Cost (callgrind, gcc -O2): one store on the way into a begin that has an ensure (149,349,060 to 150,349,060 instructions for 1,000,000 entries), 10 instructions where an exception passes one (68,400,575 to 68,600,561 for 20,000) and 22 where it passes two nested ones (85,280,084 to 85,720,084 for 20,000).

Not here, each the same on master:

- `$!` read inside an ensure body is nil.
- A rescue that does not match still loses the cause: "A rescue that does not match hands the exception on with its cause".

The test hands an exception with a cause through a method's ensure, a begin's ensure and two of them, an ensure body that rescues a raise of its own and allocates, two ensures with the inner body rescuing a raise of its own, beside a rescue that does not match, inside another handler (the cause is not that handler's exception) and through `Mutex#synchronize`; passes one with no cause; and raises in an ensure body, which takes the exception that body runs for and keeps it through the ensures it passes.

Measured on master 9922a2c74, above the pull requests named. The test is right at -O0 to -O3, with clang and under both stress modes; master has 20 of its 24 lines wrong at every level. `make backtrace-test` passes at both commits. With the second commit the C of 250 corpus programs changes besides the new test (222 tests, 28 package tests), each by the local, its root and the argument of the raise; the 222 tests print their `.expected`, and the package tests were not run here. The scale-test ratios are 4.73, 6.14 and 4.13, under their limits. `emit_begin` goes from 358 lines to 359 and `emit_rescue` from 347 to 348; the two new helpers are 5 and 4 lines. `ruby tools/gate.rb check` with each commit staged answers 0.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, two commits above the pull request beneath on master 9922a2c74: the build of each commit, the test in the seven builds, `ruby tools/gate.rb check` with each commit staged, the C of the corpus programs after each commit against the C beneath it, the 222 tests whose C changed and the new one built and run, `make backtrace-test`, `make scale-test` and `make int-min-test` at each commit, optcarrot built and run plain and under callgrind, and the 34 cost programs under callgrind.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (2,367,046,965 instructions against 2,366,980,472 beneath, callgrind; checksum 59662 on both)
- [ ] Depends on: the pull request "An exception raised again never takes its own effect as its cause"
