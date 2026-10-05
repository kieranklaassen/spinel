<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Before:

```ruby
tries = 0
x = (tries += 1; raise "no") rescue :gave_up
p x, tries          # :gave_up 0 at -O1 and above and with clang; CRuby prints 1

again = lambda do
  n = 0
  begin
    n += 1
    raise "again" if n < 3
  rescue
    retry
  end
  n
end
p again.call        # never returned at -O1 and above; CRuby prints 3
```

After: both print what CRuby prints, at -O0 to -O3 and with clang.

A local written between a setjmp and the longjmp has to be volatile, and two places did not ask. Two causes, one commit each.

**1. A rescue modifier keeps a local written before the raise.** The modifier runs its expression under a setjmp of its own, and the analysis that picks the volatile locals (`scope_has_begin`, `begin_volatile_names`) looked for a `begin` and never for the modifier. It now counts the modifier's expression; the fallback runs after the longjmp and stays plain. A block spliced into a yielding method under the modifier keeps its writes the same way.

**2. A lambda's local written inside a begin keeps the write after the rescue.** A lambda, a proc, a Fiber body and a Thread body are C functions of their own and declared every local and parameter plain. They now ask `proc_local_needs_volatile`, which looks only under the body's own block, in one walk a body, so a body with no rescue of its own gets the C it had and compiles in the time it took: a lambda of 4,000 locals, each written in a block, 31.11 s against master's 31.34 s.

An Integer, a Float, a Symbol and a true or false were lost; a String or an Array was kept, because a rooted local has its address taken.

Commit 1 makes a spliced yielding method's String local volatile when a modifier's expression writes it, and such a slot has to be rooted as a String: that is the pull request this one depends on. test/gc_root_volatile_string_slot_modifier.rb is that case, in `GC_STRESS_TESTS`.

<!-- AT OPENING: measure the three lines below on the master of that day and replace the numbers. They were measured on master 92510d6c1. -->
- Generated C (`make cident`): 5,947 programs identical, 72 differ (71 tests, one package test), no refusal changes. In a program that was there before, every changed line is an added `volatile`, but for the split of one test's top level. No benchmark's C changes and optcarrot's C is identical.
- scale-test: 1.71 / 4.73 / 6.08 / 4.22, the same four as master.
- 1,059 generated programs of a write before a raise (the construct, the local's type, where it is read) at -O0 to -O3 and with clang: none right on master is wrong here; the 30 not right here are not right on master either (14 lose the write under a `catch`, 16 do not build).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
