<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `Signal.trap` block runs inside the signal handler, on the stack of the code it interrupts. Where the signal arrives while a proc is being called, the block's return leaves that call with arguments, a block, keywords or an answer that are not its own.

```ruby
Signal.trap("USR1") { }
pr = proc { |x, &b| b ? b.call(x) : :none }
kw = proc { |a, k: 0| [a, k] }
vals = ["s", 7, :y, 2.5]
i = 0
bad = [0, 0, 0]
while i < 6000000
  v = vals[i & 3]
  bad[0] += 1 if pr.call(v) { |y| y } != v
  bad[1] += 1 if kw.call(v, k: i) != [v, i]
  bad[2] += 1 if kw.call(v) != [v, 0]
  i += 1
end
p bad
```

CRuby prints `[0, 0, 0]`. Built on master 8dc55225 and sent SIGUSR1 from a shell loop (`while kill -USR1 $pid; do :; done`), the program exits 0 and printed, in eight runs, from `[947, 900, 640]` (clang) to `[9853, 9684, 9920]` (gcc). With this change it printed `[0, 0, 0]` in ten runs of ten, gcc and clang, four of them at `SPINEL_GC_STRESS` 1 and 2 (186,550 to 9,259,565 signals a run).

**Cost.** A program whose trap block runs pays 278 instructions more for each run of the block, with gcc and with clang (callgrind, a program that sends itself 20,000 signals, the whole run: gcc 13,984,291 on master and 19,544,277 here; clang 13,085,063 and 18,645,996), and 1,064 bytes more of the stack while the block runs: a copy of the calling convention's 64 argument slots. A program that sets no trap: 20,000 `lines` calls, counted inside `main`, are 202,964,939 instructions on master and 202,954,103 here with gcc, 200,859,464 and 200,859,636 with clang. The globals marker walks one more list at each collection, an empty one there; the gcc figure moves with the layout of the unit. No program's C changes: the change is in `lib/spinel_rt.h` alone (`make cident`: 6,443 identical, 0 refusal changes; the 4 that differ print the compiler's own description), so optcarrot's is the same.

A proc is called through a side channel. The caller leaves the boxed arguments in `_sp_proc_poly_args`, the block in `_sp_proc_blk` and what the last argument is in `_sp_proc_kwpos`; the proc's prologue reads them, and its answer comes back in `_sp_proc_poly_ret`. `sp_trap_call` calls the trap block the same way: it writes the signal's number to the first argument slot, `sp_proc_call` clears the block, and the trap block's own calls write all four. Arriving after one side of a call has written and before the other has read, that left the interrupted proc with the signal's number for its argument, no block, or a keyword Hash taken for a positional one, or its caller with the trap block's answer.

`sp_trap_call` now sets the channel aside before it writes to it and puts it back when the block returns. The values set aside are marked for the collector as the channel's own are, through a list the kernel unit owns: an answer on its way back has nothing else pointing at it, and a slot can still hold a value its reader is done with, so they go through the marker that skips a slot already freed. A block that leaves by a raise or a throw abandons the interrupted call, so nothing is put back there. Nothing outside `sp_trap_call` and the globals marker changes, the header only gains lines, and the handler writes the root table as it did: its one root, pushed and popped.

**The test fails on master.** `test/trap_return_keeps_proc_call.rb` is each side of a call caught at that point: a C fragment (`ffi_source`) writes its part of the channel, sends itself the signal and answers what it reads back, while the trap block calls procs of its own with arguments, a block and keywords, and collects. Master prints `0`, `0`, `0`, `0`, `"lost"`, `"lost"` where the test expects `4142`, `43`, `7`, `1`, `"kept"`, `"held"`, with gcc and clang, at GC stress unset, 1 and 2. It is marked `# spinel: not-cruby`: CRuby has no `ffi_source`. It is in `GC_STRESS_TESTS`: the two Strings have nothing else pointing at them, and leaving the list out of the marker fails it there.

**One signal at a time, and two.** A tracer steps the 301st call of a method that makes three such calls and, in a fresh run for each instruction that call executes, the runtime's and libc's included, delivers one SIGUSR1 there and lets the program run on. With a trap block that calls a proc of its own with two arguments and a block: 3,289 points; right before and after 2,830; made right 459 (176 died of a NoMethodError, `undefined method '+' for nil`, the block having been handed nil; 12 of a segmentation fault; 271 printed a wrong answer and exited 0); wrong the same way 0; changed otherwise 0. With a trap block that calls `GC.start`, and a proc that answers a new String: 720 points; right before and after 671; made right 47; wrong the same way 2; changed otherwise 0. Two signals in one call, the second a chosen number of instructions after the first block has returned: of 594 pairs of points of the first program, 492 right before and after and 102 made right; of 572 of the second, 534 and 38; none wrong the same way, none changed otherwise.

**Not in this change.** Faults of master that stay as they are, each with a signal between two instructions of something else:

- A block that allocates. It can run a collection, or enter the allocator, between any two instructions of code that holds a value the collector cannot see yet, or of the collector itself. The two points of the second sweep that stay wrong are of this kind.
- A root being pushed. Where the C compiler stores the entry before the count, the handler's own root is written over the entry and that root is lost; where it stores the count first, a block that collects reads an entry not written yet.
- A rescue or an ensure being landed, a throw, a break or a return on its way out through an ensure, a catch being entered or left: the block's run writes over the handler frame, the unwind state or the catch slot the interrupted code is half way through.

`make gc-stress-test` passes, and the eight trap and signal tests of the suite give the same answers before and after at GC stress unset, 1 and 2.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
