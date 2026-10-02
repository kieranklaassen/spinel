<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A `next` in the block of `Fiber.new`, `Thread.new` or `Enumerator.new` did not build:

```ruby
c = ARGV.length == 0
p Fiber.new { next 5 if c; 7 }.resume                        # 5
p Thread.new { next 3 if c; 4 }.value                        # 3
p Enumerator.new { |y| y << 1; next if c; y << 2 }.to_a      # [1]
```

Each stopped at the C compiler with "continue statement not within a loop". The block of these three is a C function of its own, `static void _fiber_body_N(sp_Fiber *)`, with no loop around it, and the statement emitter wrote the `next` as the `continue` it writes for an iterator's block. Inside a proc the same `next` took the proc's return instead, so `proc { Fiber.new { next 5 if c; 7 } }.call.resume` built and answered `nil`.

A `next` such a body owns now stores its value in `_fb->yielded_value`, where the body's last statement leaves its own, and returns: `nil` for a bare `next`, an Array for `next 1, 2`, and for a generator the value `StopIteration#result` reads. An `ensure` between the `next` and the body runs first, through the chain a deferred return takes, whose tail in a void function is a bare `return`; rescue frames the `next` leaves are popped as `emit_return` pops them.

Which `next` a body owns is read from the source, with the walk `redo` already uses (`subtree_owns_next` beside `subtree_owns_redo`), not from the C loop depth: a `next` in a `while` or in an iterator's block inside the body is that loop's, and one in a proc or lambda written there is the proc's. `emit_fiber_new` names the body it is emitting in `g_fiber_body`. The arm is in a new `emit_next_leaving_body`, which also takes the proc arm out of `emit_stmt_inner` as it stood, so that function is 30 lines shorter and no function over 1,000 lines grows.

Found with the dead code probe (#7223), which puts a `next` at the head of the blocks of 300 tests: 64 of its results on d83c5bd5 were this C error, and all 64 still are on f0263e6c. The 52 in a fiber, thread or generator body build and print their test's `.expected` with this change. The emitted C of the 5,472 programs in `test/*.rb` is byte-identical before and after (both compilers built on f0263e6c), and so is that of the 64 in `benchmark/` and the 142 package tests (both on 0d370b71), so nothing that built before changes.

`test/fiber_thread_enumerator_block_next.rb` has the `next` with a value, without one and with several; nested in `if`, `unless` and `case` and as the block's last statement; after a `Fiber.yield`; a `while`, an `until` and iterator blocks inside the body that keep their own `next`; an `ensure` inside an `ensure`, a `rescue` left and a `next` from inside a `rescue` clause, with a raise afterwards to show the handlers were popped; a proc and a lambda in a fiber, a fiber in a proc, a fiber in a fiber, and bodies in a method that read an ivar. It prints its `.expected` plain and under `SPINEL_GC_STRESS=1`, and fails to build on master.

Still not built, each in an emitter of its own and left for its own change: a `next` in the block of `instance_eval` or `instance_exec`, of `Struct#to_h`, of `catch`, of `define_singleton_method` and of `Class.new`. A `next` in the middle of an expression, `x = (c ? (next 5) : 7)` or `c && (next 4)`, is taken as its value in any block, as before.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it prints Integers, Symbols, Strings, nil and Arrays of them, nothing whose `inspect` changed since)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (OPTCARROT_LINE)
- [ ] Depends on: # (nothing; #7223 is where the numbers come from, and this does not need it)
