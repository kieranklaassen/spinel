## What this changes

Since #7531 a read-only String parameter takes a shared String's live buffer. In a callee that hands control away before its last read, the buffer can be freed under it. This gives such a callee its copy back, which is the answer before #7531. It is a trade, and this is the program that pays for it: the buffer does not move while the callee is paused, so master's answer today is CRuby's, and the copy's is not.

```ruby
def peek(s)
  Fiber.yield 1
  s.getbyte(0) + s.bytesize
end
s = +"hello"
t = s
t << " world"
f = Fiber.new { peek(s) }
f.resume
s << "!"
p f.resume    # CRuby 116. Before #7531: 115. Master: 116. With this: 115.
```

With `s << ("x" * 1_000_000)` in place of `s << "!"` the buffer moves. CRuby prints 1000115, master before #7531 printed 115, and master now prints a different number on each run (1091263511, 4181771985, 961907247). valgrind on master's binary: `Invalid read of size 1 at _fiber_body_1 ... Address is 24 bytes inside a block of size 52 free'd at realloc, by sp_String_append_bin, by _sp_main_body`. Two forms print nothing and exit 139: `s.getbyte(s.bytesize - 1)`, and an instance method reached through another with the handle in an instance variable. With this each prints what it printed before #7531, and valgrind reports nothing. No list can prove the buffer does not move, so the small append goes back with the large one.

**How.** `param_borrow_loud` answers yes for a builtin with no receiver or on a class that is named `yield`, `sleep`, `pass` or `stop`: `Fiber.yield`, `sleep`, `Thread.pass`, `Thread.stop`. It goes by the name, since `F = Fiber; F.yield` is the same call. Such a callee keeps the copy, and its call compiles to the C it had before #7531, byte for byte. A signal handler and a finalizer run at a safe point of whatever method is running, so a program that calls `trap` or `define_finalizer` marks no read at all. That costs the corpus nothing: 17 programs under `test/` call one or the other, none of them had a borrowed read, and the C of all 17 is unchanged.

**Not CRuby's answer.** CRuby prints 1000115 for the long append. That needs the parameter to be the handle, which is a sharing rule (#6765).

**The ways a quiet callee hands control away,** one program each, the String grown by a megabyte meanwhile. "Copy" is the answer before #7531.

| in the callee | master 9c4eec71 | with this |
|---|---|---|
| `Fiber.yield`, with or without a value; `F = Fiber; F.yield` | reads freed memory | copy |
| `sleep`, `Kernel.sleep`, `Thread.pass`, `Thread.stop`, another thread appends | reads freed memory | copy |
| a signal handler that appends, the signal arriving in the callee's loop or sent by `Process.kill` there | reads freed memory | copy |
| a finalizer that appends, run by `GC.start` in the callee | reads freed memory | copy |
| `g.resume` on a Fiber, `th.join`, `th.value`, `q.pop`, `q.push` on a SizedQueue, `m.lock`, `m.synchronize`, `cv.wait(m)`, `e.next`, `y << v` on a Yielder | copy: the receiver's type is loud already | copy |
| `yield`, `blk.call`, a proc in a variable, `send(name)` | copy: loud already | copy |

The signal handler and the finalizer need no thread and no call in the callee.

**Limits.** Two threads that share a String with no Mutex, where the reader does not ask for the other to run:

```ruby
def peek(s)
  i = 0
  n = 0
  while i < 300_000_000
    n += s.getbyte(0)
    i += 1
  end
  n / 300_000_000 + s.bytesize
end
s = +"hello"
t = s
t << " world"
th = Thread.new { sleep 0.05; s << ("x" * 1_000_000) }
p peek(s)     # 115 before #7531; a different number on each run on master and with this
th.join
```

Threads run in parallel, so no call in the callee decides whether the appender runs, and docs/limitations.md leaves that race to the program ("Thread data races are observable"). A blocking `io.gets` and `system` in place of the loop do the same. Giving every program that starts a Thread its copies back would cover them, and would take the borrow from every threaded program. I did not build that.

**Measured** on 9c4eec71, and the test again on 5d08e9c6:

- The new test fails on master in 60 runs of 60 (exit 139), and each of its three cases alone in 40 of 40: two crash, one prints a different number on each run. With this it passes and valgrind reports nothing. Each String in it reads the same after the pause as before it, so the copy's answer is CRuby's. On master it fails through what glibc's `free` writes into the freed block. An allocator that leaves a freed block untouched could let it pass on an unfixed master; with the fix it reads no freed block, on any allocator.
- #7531's own test passes. Its C and the C of `benchmark/bm_str_readonly_param.rb` are byte-identical to master's.
- `tools/cident.sh`: 6,136 corpus programs identical, 0 differ, so none of #7531's corpus programs goes back to the copy.
- 48 programs written for this: 26 compile to the C of 52c5ccf7, the master before #7531, byte for byte; 16 were loud already; 6 keep the borrow (no pause, or the Limits above).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
