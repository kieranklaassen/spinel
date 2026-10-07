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

An ensure holds the exception in its region's locals while its body runs and raises it again after, and that raise decided the cause anew, from what was being handled there: nothing, or the wrong exception where the ensure sits inside another handler. The cause now waits with the exception, in a local each of the three kinds of region declares (a begin, `Mutex#synchronize`, the loop of `select!` and its kin). It is a root while the ensure body runs, it is handed to an outer ensure with the rest, and `sp_exc_pass_cause` gives it to the raise. A `cause:` given to the raise, `cause: nil` too, is kept the same way.

Two commits. The first moves the store of a landed exception into the region's locals, written out three times, into `emit_ensure_exc_store` and changes no C (all 6,365 corpus programs identical). The second adds the cause to it.

Depends on "A rescue that does not match hands the exception on with its cause", whose `sp_exc_pass_cause` it calls, and on "An exception leaving an inner ensure reaches the rescue around it", above which it is built, and through that one the pull requests it names.

Cost: one store on the way into a begin that has an ensure (150,347,704 against 149,347,704 instructions for 1,000,000 entries, callgrind, -O2), and 16 instructions where an exception passes one (57,146,673 against 56,826,673 for 20,000).

Not here: `$!` read inside an ensure body.

Measured above those on master c121a0cbd: the test is right at -O0 to -O3, with clang and under both stress modes (master: 18 lines wrong at every level), the tests of the pull requests beneath stay right at every level, and `make backtrace-test` passes. Of 6,366 corpus programs the C of 241 changes besides the new test, each by the local, its root and the argument of the raise; 240 of the 242 print what they printed and two fail here as on master (tmpdir_expand_usable, poly_io_native_class_def). Of 69 generated programs in which an exception with a cause is handed on (six ways to raise it, ten ways to pass, nine further shapes), master is wrong for 48 and right for 21; beneath this 37 of the 48 are right, and here all 69 are. The hand-on between two ensures held the cause for one allocation with nothing else holding it; a scan of 131 allocation counts under `SPINEL_GC_STRESS=2` is clean. The scale-test ratios are master's (1.71, 4.73, 6.05, 4.18).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (2,377,838,680 instructions against 2,377,978,615 beneath, callgrind; checksum 59662 on both)
- [ ] Depends on: "A rescue that does not match hands the exception on with its cause", "An exception leaving an inner ensure reaches the rescue around it"
