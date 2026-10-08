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

Cost (callgrind, gcc -O2). A program that holds no ensure clause with a body keeps its C byte for byte. In one that holds such a clause, an ensure body that ends pays nothing (2,000,000 calls of a method with an ensure: 280,350,059 instructions before and after), and a block's `return` and `break` out of an inlined `each` are the instructions they were. Each landing of a `longjmp` that is no raise pays for the value it keeps, at most:

- a `catch`, 2 instructions when its block ends and 4 when it is thrown to (200,000 catches with a throw: 51,550,007 to 52,350,010, 1.6%);
- the method a proc returns from, 4 a call (107,184,229 to 107,984,229 for 200,000);
- a block's `break` that leaves by `longjmp`, out of a `begin` in the block or with a value out of `each_with_index`, 4 (51,750,021 to 52,550,021 for 200,000).

The fact is the program's (`g_uses_ensure`, set where `g_uses_regex` is), so a program pays these where a file it requires holds an ensure in a method it never calls. Two tests do, `test/file_foreach_arg_exprs.rb` and `test/file_foreach_streams.rb`, by `require "tmpdir"`: five landings between them.

An ensure body that runs for an exception sets `sp_inflight_cause` to it, so that a raise in the body takes it as its cause, and gave the outer value back in a line after the body. A `return`, a `break` or a `next` jumps past that line; a `throw`, a proc's return and a break out of a block's caller leave by `longjmp`. The exception the body dropped stayed there, and the next raise made while nothing was being handled took it as its cause.

The body now gives the outer value back by a cleanup on its scope (`sp_inflight_restore`), which runs however the body is left inside its function. The three landings of a `longjmp` that is no raise read the value when they are entered and restore it when they land: a `catch`, the call a block's `break` leaves, and the method a proc returns from. They are emitted only in a program that holds an ensure clause with a body; in any other nothing is ever in flight.

Of the corpus's 6,608 programs the C of 133 changes: 102 tests, which print their `.expected` as before, and 31 package tests, which the gate runs.

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
- A `throw`, a proc's return or a block's `break` that leaves an ensure body and passes a second ensure body on its way: a raise made in that second body still takes the dropped exception as its cause.

  ```ruby
  catch(:x) do
    begin
      begin
        raise "dropped"
      ensure
        throw :x
      end
    ensure
      begin
        raise "second"
      rescue => e
        p e.cause
      end
    end
  end
  ```

  prints `#<RuntimeError: dropped>`; CRuby prints `nil`.

The test leaves an ensure body by a `return`, a `break`, a `next` in a block and in a `while`, a `throw`, a `return` from a block, a proc's return and a `break` out of a yield, and raises after each; two deep, the inner ensure drops its exception by a `break` and by a `throw` and the outer body's raise takes the outer one; an ensure body that is not left; one that ends; and 200 calls.

Measured on master 84f5b5020. The test is right at -O0 to -O3, with clang and under both stress modes; master has 11 of its 14 lines wrong in each of those builds. `make backtrace-test` and `make share-strings-test` pass. The scale-test ratios are 4.73, 6.14 and 4.13, under their limits. `emit_begin` goes from 323 lines to 329, `emit_call_kernel_flow_arms` from 628 to 633, `emit_brk_wrapped_call` from 176 to 180, `emit_method` from 244 to 248 and `scan_prologue_features` from 217 to 223. `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit on master 84f5b5020: the build, the test in the seven builds, `ruby tools/gate.rb check` with the change staged, the C of all 6,608 corpus programs against master's, the 102 tests whose C changed and the new one built and run, optcarrot built and run plain and under callgrind, `make backtrace-test`, `make scale-test`, `make share-strings-test` and `make int-min-test`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its one ensure body: 2,368,028,864 instructions on master and here; checksum 59662)
- [ ] Depends on: none
