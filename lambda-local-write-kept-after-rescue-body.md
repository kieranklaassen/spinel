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

never returns at -O1 and above and with clang: `n` reads 0 after every retry. `l = lambda { n = 3; begin; n = 5; Integer("z"); rescue; end; n }` answers 3 where CRuby answers 5, and a write an ensure reads is lost the same way. -O0 is right, and so is the same body as a method or as a block spliced into its caller.

After: the first prints `3` and the second answers 5, at every level.

Cost: a local of such a body that is written inside a begin is declared volatile, as the same local of a method is, so its reads and writes go through memory. A body with no rescue of its own gets the C it had. One walk of the body's block gathers every name written under a setjmp, and the answer is kept for the body's next local, so compiling a body with no rescue costs what it cost (a lambda of 4,000 locals, each written in a block: 53.7 s against 53.6 s, measured on the master the change was first cut on).

A lambda, a proc, a Fiber body and a Thread body are C functions of their own, and the three places that declare their locals (`emit_fiber_new`, and twice in `emit_proc_literal_here`) passed 0 for `declare_local`'s volatile argument whatever the body held. They now ask `proc_local_needs_volatile`, which looks under the body's own block for a write of that local inside what `begin_volatile_names` counts for a method (`is_setjmp_construct`, `is_rescuing_yield_call`): a begin, a rescue modifier, a `loop` that ends on StopIteration, a break that crosses a frame or a block spliced under a method's rescue. A setjmp around the `lambda` call is in the enclosing function, so a body with none of its own is declared as before.

The body's own parameter is the same local when the body assigns it. A block's required parameter was already copied into a local of the body; a stabby lambda's (`->(k) { ... }`), a parameter after a splat and a `**rest` are declared by the argument prologue, which now spells their type through `emit_local_ctype`, the volatile spelling split out of `emit_inlined_local_decl`.

An Integer, a Float, a Symbol and a true or false were lost, and a String parameter the body assigns; a rooted local of the body, a String or an Array, was kept.

Of the corpus's 6,530 programs the C of 64 changes, 63 tests and one package test; the 63 tests print their `.expected` as before.

The test writes a local inside a begin in a lambda, a proc, a Fiber body and a Thread body and reads it after the rescue, after a `retry` and in an ensure; the body's own parameter, a stabby lambda's and one after a splat; under a rescue modifier; in a block spliced into the body and in a parameter's default; in a body made under the method's begin; and in a block spliced under a method's rescue inside a lambda.

Measured on master 9922a2c74. The test is right at -O0 to -O3, with clang and under both stress modes; master is right at -O0 and does not end at -O1 to -O3 and with clang (stopped after 20 seconds, 18 of its 19 lines not printed). `make backtrace-test` passes. The scale-test ratios are 4.73, 6.14 and 4.13, under their limits. `emit_inlined_local_decl` goes from 25 lines to 14; the three new functions are 21, 15 and 12 lines. `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit on master 9922a2c74: the build, the test in the seven builds, `ruby tools/gate.rb check` with the change staged, the C of all 6,530 corpus programs and of optcarrot against master's, the 63 tests whose C changed and the new one built and run, `make backtrace-test`, `make scale-test` and `make int-min-test`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none
