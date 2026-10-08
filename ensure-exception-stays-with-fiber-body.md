<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
f = Fiber.new do
  begin
    raise "in the fiber"
  ensure
    Fiber.yield 1
  end
end
f.resume
begin
  raise "main"
rescue => e
  p e.cause
end
```

prints `#<RuntimeError: in the fiber>`. After, as CRuby: `nil`. The other way round, a fiber resumed from an ensure body of main raised with main's exception as its cause, and an ensure body lost its own exception to any raise made while its fiber was away.

Cost (callgrind, gcc -O2): a fiber switch saves and loads one pointer more, 3 instructions a switch (200,000 resumes of a fiber that yields: 181,268,051 to 182,468,071, 0.7%), and a new fiber pays 21 (20,000 fibers made and resumed twice: 102,827,786 to 103,252,904, 0.4%). An external enumerator is the instructions it was (52,135,789).

`sp_inflight_cause`, the exception an ensure body runs for, is one variable for all fibers. The per-fiber context (`sp_exc_ctx_t`) carries the exceptions being handled and the pending cause across a switch, and did not carry this one. It is now saved and loaded with them (`sp_exc_ctx_save`, `sp_exc_ctx_load`), and marked while its fiber is suspended (`sp_exc_ctx_mark`).

No C changes: the compiler's sources are untouched, the change is in the runtime.

The test suspends a fiber in an ensure body and raises outside it; resumes that fiber and lets the body raise, after 2,000 allocations; resumes a fiber that raises from an ensure body of main, and lets main's body raise after it; suspends two fibers in an ensure body each and resumes them in turn; and resumes a fiber that is in no ensure body under one, 100 times.

Measured on master 9922a2c74. The test is right at -O0 to -O3, with clang and under both stress modes; master has 7 of its 9 lines wrong in each of those builds. `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit on master 9922a2c74: the build of the runtime and the compiler, the test in the seven builds, `ruby tools/gate.rb check` with the change staged, the three cost programs under callgrind, optcarrot's C against master's and `make int-min-test`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none
