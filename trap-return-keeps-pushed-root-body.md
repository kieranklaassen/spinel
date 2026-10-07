<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `Signal.trap` block runs inside the signal handler, on the stack of the code it interrupts.
Where the signal arrives between the two stores of a root push, the block's return takes that
root away and leaves a dead C frame in the root table; the next collection reads it.

```ruby
Signal.trap("USR1") { }
s = "ab\n" * 20
i = 0
n = 0
while i < 60000
  n += s.lines("\n", chomp: true).size
  i += 1
end
p n
```

CRuby prints 1200000. Built on master 9274c732 (gcc 13.3.0) and sent SIGUSR1 from a shell loop
(`while kill -USR1 $pid; do :; done`) with `SPINEL_GC_STRESS=2`, the program fails 4 runs of 4,
after 56,246 to 316,512 signals: three abort in the root phase ("collector reached a
non-heap/corrupt object") and one faults on the mark path. With this change 3 runs of 3 print
1200000, each through 325,423 to 365,459 signals.

A root push is `sp_gc_roots[sp_gc_nroots++] = p`: two stores, in the order the C compiler
picks. gcc stores the count first at 1,117 sites of the runtime library and the entry first at
21, the first push of `sp_str_lines_sep_chomp` among them; `sp_gc_root_push_slow` stores the
entry first as written. `sp_trap_call` rooted its proc at the index it found, which is that
uncounted entry, and popped it on return. The interrupted push then counted an entry that named
a local of `sp_trap_call`.

`sp_trap_call` now keeps the entry at the count it finds, in either segment of the root table,
and puts it back when the block returns. A block that leaves by a raise or a throw abandons the
interrupted push with the rest of that frame, so nothing is put back there. Nothing outside
`sp_trap_call` changes.

**The test cannot fail on master.** No program can place its own signal between two
instructions, and a flood from outside is not a test a suite can keep. So
`test/trap_return_keeps_roots.rb` sends itself the signal while a method's roots are live and
while a block runs under a library call, and pins the answers of that path; it is in
`GC_STRESS_TESTS`. The program above with the shell loop is the witness.

**Cost.** A program that sets no trap runs the same instructions (a loop of 20,000 `lines`
calls: 203,308,375 before and after). Each run of a trap block costs 16 instructions more
(20,000 signals a program sends itself: 13,984,264 to 14,304,264).

**Not in this change.** The other order. Where the count is stored first, a collection run by
the trap block reads the entry beneath the count before the interrupted code has written it.
That needs the collector to tell a root being pushed from one in place, at every push; no
failing program is known, and it is not attempted here. clang's order was not measured.

On master 9274c732: no program's C changes (`make cident`: 6,415 identical, 4 differ, the four
tests that print the compiler's revision). `make gc-stress-test` passes, and the eight trap and
signal tests of the suite give the same answers before and after at GC stress unset, 1 and 2.

The test's `.rb.expected` is the output of CRuby 3.3.6 with `--enable-frozen-string-literal`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
