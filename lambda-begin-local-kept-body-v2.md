<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
tries = lambda do
  n = 0
  begin
    n += 1
    raise "again" if n < 3
  rescue
    retry
  end
  n
end
p tries.call
```

does not return at -O1 and above and with clang: `n` reads 0 after every retry. -O0 prints 3.

After: `3`. `l = lambda { n = 3; begin; n = 5; Integer("z"); rescue; end; n }` answered 3 where CRuby answers 5, and a write an ensure reads was lost the same way. So was a String parameter the body assigns: `->(n) { loop { n = "b"; raise StopIteration }; n }` answered the argument.

A method's local is volatile when it is written under a setjmp. A lambda, a proc, a Fiber body and a Thread body are C functions of their own, and the three places that declare their locals (`emit_fiber_new`, and twice in `emit_proc_literal_here`) passed 0 for `declare_local`'s volatile argument whatever the body held. They now ask `proc_local_needs_volatile`, which walks the body's own block once for the names written under what `begin_volatile_names` counts (`is_setjmp_construct`, `is_rescuing_yield_call`). A body with no setjmp of its own is declared as before.

The new test does not return on master above -O0, so a run of it there needs a timeout.

Cost: a loop written inside the body's begin pays two instructions a turn where nothing raises (66,658,147 to 72,658,173 for 3,000,000 turns, callgrind, -O2).

Measured on master 8684d54ce: 62 corpus programs gain a `volatile` on such locals and nothing else (6,279 identical, 63 differ with the new test) and print what they printed; no benchmark's C changes, nor optcarrot's; scale-test keeps master's four ratios. A lambda of 4,000 locals, each written in a block, compiled in 53.7 s against master's 53.6 s (on dafa0d047).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
