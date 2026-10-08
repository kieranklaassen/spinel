<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def by_return
  begin
    raise "dropped"
  ensure
    return 1
  end
end
by_return
begin
  raise "later"
rescue => e
  p e.cause
end
```

prints `#<RuntimeError: dropped>`. After, as CRuby: `nil`. A `break`, a `next`, a `throw` and a proc's return in the ensure body left the same exception behind.

Cost (callgrind, gcc -O2): an ensure body that ends pays nothing (2,000,000 calls of a method with an ensure: 280,348,730 instructions before and after). A `catch` pays 4 instructions for the value it keeps (300,000 catches with a throw: 77,147,598 to 78,347,596, 1.6%). A block's `return` and `break` out of `each` are the instructions they were (30,060,766).

An ensure body that runs for an exception sets `sp_inflight_cause` to it, so that a raise in the body takes it as its cause, and gave the outer value back in a line after the body. A `return`, a `break` or a `next` jumps past that line; a `throw`, a proc's return and a break out of a block's caller leave by `longjmp`. The exception the body dropped stayed there, and the next raise made while nothing was being handled took it as its cause.

The body now gives the outer value back by a cleanup on its scope (`sp_inflight_restore`), which runs however the body is left inside its function. The three landings of a `longjmp` that is no raise read the value when they are entered and restore it when they land: a `catch`, the call a block's `break` leaves, and the method a proc returns from.

Of the corpus's 6,530 programs the C of 253 changes: 219 tests, of which 218 print their `.expected` as before and the one that has none prints CRuby's output, and 34 package tests, which the gate runs.

Not here, each the same on master:

- A raise that is rescued inside an ensure body clears the exception that body runs for, so a second raise in the same body has no cause:

  ```ruby
  begin
    begin
      raise "first"
    ensure
      begin
        raise "inner"
      rescue
      end
      raise "second"
    end
  rescue => e
    p e.cause
  end
  ```

  prints `nil`; CRuby prints `#<RuntimeError: first>`.
- An ensure body that is suspended in a Fiber: the pull request "An ensure body's exception stays with its fiber".

The test leaves an ensure body by a `return`, a `break`, a `next` in a block and in a `while`, a `throw`, a `return` from a block, a proc's return and a `break` out of a yield, and raises after each; two deep, the inner ensure drops its exception by a `break` and by a `throw` and the outer body's raise takes the outer one; an ensure body that is not left; one that ends; and 200 calls.

Measured on master 9922a2c74. The test is right at -O0 to -O3, with clang and under both stress modes; master has 11 of its 14 lines wrong in each of those builds. `make backtrace-test` passes. The scale-test ratios are 4.73, 6.14 and 4.13, under their limits. `emit_begin` goes from 323 lines to 329, `emit_call_kernel_flow_arms` from 628 to 633, `emit_brk_wrapped_call` from 176 to 180 and `emit_method` from 243 to 246. `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit on master 9922a2c74: the build, the test in the seven builds, `ruby tools/gate.rb check` with the change staged, the C of all 6,530 corpus programs against master's, the 219 tests whose C changed and the new one built and run, optcarrot built and run plain and under callgrind, `make backtrace-test`, `make scale-test` and `make int-min-test`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its one ensure body: 2,367,077,689 instructions on master, 2,367,079,305 here; checksum 59662)
- [ ] Depends on: none
