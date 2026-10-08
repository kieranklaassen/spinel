<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `Signal.trap` block runs inside the signal handler, on the stack of the code it interrupts. Where the signal arrived while a proc was being called, the block's return left that call with arguments, a block, keywords or an answer that were not its own, and the program went on with the wrong value.

**Cost.** A run of a trap block is 288 instructions more with gcc and 287 with clang (callgrind, a program that sends itself 20,000 signals, the whole run: gcc 13,984,304 on master and 19,744,304 here; clang 13,085,062 and 18,825,995), and holds 1,064 bytes more of the stack while it runs: a copy of the calling convention's 64 argument slots. A fiber switch is two stores more: 200,000 resumes of a fiber that yields are 180,469,559 instructions on master and 181,269,579 here with gcc, 186,428,099 and 187,228,119 with clang. A program with neither: 20,000 `lines` calls, counted inside `main`, are 202,964,939 and 202,954,103 with gcc, 200,859,464 and 200,859,636 with clang (the globals marker walks one more list at each collection, an empty one there; the gcc figure moves with the layout of the unit). No program's C changes, the change being in `lib/` (`make cident`: 6,494 identical, 0 refusal changes; the 4 that differ print the compiler's own revision), so optcarrot's is the same.

```ruby
note = proc { |a, b| a }
Signal.trap("USR1") { note.call(:got, :it) }
def sig
  Process.kill("USR1", Process.pid)
  10
end
pr = proc { |a, b = sig, c| [a, b, c] }
p pr.call(1, 3)
```

CRuby prints `[1, 10, 3]`. Master 3d629868 prints `[1, 10, nil]` and exits 0, with gcc and with clang: the proc has read `a`, the default of `b` sends the signal, and `c` is read after the block's own call has written the same slots. A signal from outside finds the same window in any proc call, between two instructions.

`sp_trap_call` now copies the proc channel aside before the block runs and back when it returns, and the copy is marked for the collector as the channel is. A block whose run switched fibers, or that leaves by a raise or a throw, puts nothing back, as on master: the channel is the worker's, not a fiber's, and after a switch it may hold another fiber's call in flight.

**The test fails on master.** `test/trap_return_keeps_proc_call.rb` is plain Ruby and prints 18 lines; master gets 7 of them wrong (each argument read after the signal is `nil`), with gcc and clang, at GC stress unset, 1 and 2. Its last rows are blocks that switch fibers, right on master and kept right: one resumes a fiber that yields out of its own call, one leaves its fiber and is resumed out of another call, two cross, one leaves for good. The suite's eight trap and signal tests give the same answers before and after, and `make gc-stress-test` passes.

**Not shown by the test.** No Ruby program I found has a block, a keyword flag or an answer in the channel when the signal arrives. A C fragment (`ffi_source`) that writes one side of a call, sends the signal and reads back does: master loses each of them and this change keeps them, a String across the block's `GC.start` too, and on a second thread while the main thread collects (800 of 800 kept; master 0). It names runtime internals, as no `ffi_source` test of the suite does, so it is not in the pull request; I can add it.

**Not in this change.** Faults of master that stay as they are:

- A block that switches fibers before it returns (`Fiber.yield`, a resume, `Thread.pass`, a thread's time slice running out): the call it interrupted is as on master.
- A block that allocates, between two instructions of code that holds a value the collector cannot see yet; and a signal while a root is being pushed, a rescue or an ensure landed, a throw or a break on its way out, a catch entered or left.
- With threads, the kernel can hand the signal to a thread other than the one it interrupts; the block runs there.
- The block slot of the channel is not marked, here as on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
