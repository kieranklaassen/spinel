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
p e.next    # master: a different number each run
```

valgrind on master's binary: `Invalid read of size 1 at _fiber_body_1 ... 24 bytes inside a block of size 52 free'd at realloc, by sp_String_append_bin`. `e.peek` for the first `e.next` is a segfault; `with_index`, `each_slice` and `to_enum(:each)` on a class's own `each` read the freed buffer the same way.

A method that itself calls `Fiber.yield` is now loud in `param_borrow_loud`: it keeps the copy, and the program prints 115, the String as it was at the call. No other method changes. One paused through a block it yields to, a method it calls, a proc or a Yielder is loud on master already, so the test follows no call (47 programs: master reads the freed buffer in 28, this in none).

The cost: where the String is changed in place while the method is paused and its buffer does not move, the borrow read what CRuby reads and the copy does not. With `s.upcase!` for the append and `s.getbyte(0)` read, CRuby and master print 72 and this prints 104. Pull request 7674 made the same choice for `Fiber.new`: the same program with `Fiber.new { peek(s) }` and `resume` prints 104 on master. CRuby's answer needs the parameter to be the handle.

The new test fails on master in 30 runs of 30 and passes with this, also under `SPINEL_GC_STRESS` and valgrind. `tools/cident.sh`: 6,334 corpus programs identical; the one that differs is the new test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
