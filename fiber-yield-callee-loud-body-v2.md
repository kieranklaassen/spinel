<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A read-only String parameter borrows the caller's buffer, and pull request 7674 turned that off for a program with a thread, a fiber, a signal handler or an ffi_callback. It asks for the fiber by `Fiber.new`. An Enumerator's `next` runs its block on a fiber with no `Fiber.new` in the program, so a method that calls `Fiber.yield` there is paused holding the buffer and reads it freed:

```ruby
def peek(s)
  Fiber.yield 1
  s.getbyte(0) + s.bytesize
end
s = +"hello"
t = s
t << " world"
e = Enumerator.new { |y| y << peek(s) }
e.next
s << ("x" * 1_000_000)
p e.next    # CRuby 1000115; master: a different number each run
```

```
spinel diff: nondeterministic
  ruby:    exit 0
  spinel:  exit 0
  the spinel binary disagreed with its own second run; a value that changes per run (rand, a pid, a time, thread order) is in the output
-1000115
+1906740123
```

valgrind on master's binary: `Invalid read of size 1 at sp_peek ... 24 bytes inside a block of size 52 free'd at realloc`. `e.peek` for the first `e.next` is a segfault; `with_index`, `each_slice` and `to_enum(:each)` on a class's own `each` read the freed buffer the same way.

A method that itself calls `Fiber.yield` is now loud in `param_borrow_loud`: it keeps the copy, and the program prints 115 in every run, the String as it was at the call (`spinel diff: output-diff`; the same program with `Fiber.new` and `resume` prints 115 on master too). No other method changes. One paused through a block it yields to, a method it calls, a proc or a Yielder is loud on master already, so the test follows no call. Of 388 programs of a second reading, master borrows and this copies in 296: master reads the freed buffer in 172 of them, this in none.

The cost: where the String is changed in place while the method is paused and its buffer does not move (an append that fits, `upcase!`), the borrow read what CRuby reads and the copy does not. With `s.upcase!` for the append and `s.getbyte(0)` read, CRuby and master print 72 and this prints 104; 67 of the 388 programs are of this kind, and none outside it. Nothing at compile time tells them from the ones that read freed memory: the text is the same and only the size of the append at run time differs. Pull request 7674 made the same choice for `Fiber.new`: the same program with `Fiber.new { peek(s) }` and `resume` prints 104 on master. CRuby's answer needs the parameter to be the handle.

An instance method that pauses, with the big append, was a segfault on master and now prints the copy's answer too (104011 for CRuby's 1104011), the number master prints for every parameter it copies.

The new test fails on master in 30 runs of 30 and passes with this, also under `SPINEL_GC_STRESS` and valgrind. `tools/cident.sh`: 6,342 corpus programs identical; the one that differs is the new test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
