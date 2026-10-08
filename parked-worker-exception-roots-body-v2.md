<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** The message of an error on its way out, or of one just rescued, was freed by a collection another thread ran, and `e.message` came back as one of that thread's Strings. The cost is in threaded programs only: every time a worker goes idle it runs 9 instructions more of 253 with gcc and 6 more of 226 with clang if it has raised nothing, and 25 and 34 more while the message of an exception it rescued is still in its slot (the numbers are below).

```ruby
def churn(n)
  a = []
  n.times { |i| a << ("x" * (i % 50)) }
  a.size
end
def fail_with(i)
  raise ArgumentError, "bad " + i.to_s
ensure
  churn(40)
end
t = Thread.new do
  s = 0
  300.times { s += churn(20000) }
  s
end
bad = 0
first = nil
100000.times do |i|
  begin
    fail_with(i)
  rescue => e
    unless e.message == "bad " + i.to_s
      bad += 1
      first ||= [i, e.message]
    end
  end
end
p t.value
p bad
p first
```

Ruby prints `6000000`, `0` and `nil`. Master (3d629868d), in a plain run, counts 15, 6, 5, 12 and 2 wrong messages in five runs built with gcc and 11, 8, 12, 11 and 14 built with clang; the first of one run is `[11727, "xxxxxxxx"]`, a String the other thread made. With this change ten runs count 0.

The error is raised in `fail_with`, and its message waits in the exception stack while the `ensure` body runs. The body allocates; when the other thread collects just then, this one waits for it, and nothing it handed over named the message.

Without the `ensure` the window is too short for a plain run, and the collector's own lanes show it:

```ruby
begin
  Integer("zz")
rescue ArgumentError
  puts "rescued"
end
t = Thread.new { a = []; 2000.times { |i| a << "s#{i}" }; a.length }
p t.value
b = []
2000.times { |i| b << "m#{i}" }
```

This stops on master, gcc and clang, at `SPINEL_GC_STRESS=2`, and at level 1 with `SPINEL_GC_VERIFY=1`: "the mark reached a freed heap string", phase `globals:exceptions`. Three of the suite's own tests stop the same way at those levels and pass with this change: `test/fiber_cross_thread.rb`, `test/ffi_io_buffer_arg.rb`, `test/io_close_wakes_parked_reader.rb`.

The exception stack is thread-local. The worker that collects marks its own in `sp_mark_in_flight_exceptions`: each frame's message and object, the slot one past the top that a rescue arm has popped and still reads, and it clears every slot above that. A worker that waits while another one collects hands its roots over in `sp_publish_worker_roots`, and that published only the objects of the open frames. `sp_raise_cls` stores a heap copy of every message, so after any rescue the slot one past the top names a heap String, and nothing published it. An exception object nothing had bound went the same way, and so did whatever a slot above the window still named once the next `begin` put that slot back inside it.

`sp_publish_worker_roots` now does for a waiting worker what `sp_mark_in_flight_exceptions` does for the collecting one: it publishes each frame's message, the message and the object one past the top and the cause an `ensure` holds, and it clears the slots above.

It runs every time a worker goes idle or enters a blocking call, not only when it parks for a collection, so all of that but the cause's one test is behind a mark the worker keeps, `sp_exc_slots_hw`: one past the highest slot that may hold what a raise stored. `sp_raise_cls` raises the mark at its store, the only place a heap message or an object is written into a slot (`sp_raise_stack_overflow` stores a literal, which no collection frees). The hook publishes and clears below the mark only, and puts it back to 0 when it finds no message and no object there. A context switch needs no mark of its own: a thread stays on the worker that started it, and its context is saved with the frames below the top, which are armed and empty. Of the 502 tests that name a Thread, a Fiber, a Queue, a Mutex or an Enumerator, built against a runtime that reports a loaded context that brings a message or an object, none reports one.

Cost, callgrind's inclusive count of `sp_publish_worker_roots` a call, on 3d629868d; a Queue handed back and forth between two threads 300,000 times (574,201 to 821,263 calls of it in a run):

| | gcc before | gcc after | clang before | clang after |
|---|---|---|---|---|
| no thread raises | 253 | 262 | 226 | 232 |
| each thread rescues one `Integer("zz")` before the loop; its message stays in the slot one past the top | 253 | 278.00 | 226 | 259.69 |
| the same, and each thread then passes a `begin` that raises nothing, which empties that slot | 253 | 262 | 226 | 232 |

The first two programs run about 3,000 instructions for each call of the hook with gcc, so those rows are 0.3% and 0.9% of them. The third row is the mark put back to 0: without that it is 276.51 with gcc and 257.21 with clang. A program with no threads is built without the hook. The compiler is untouched: its binary is byte-identical, so no program's generated C changes.

**Not in this change:** an `ensure` body with a `begin`/`rescue` of its own loses the message of the exception on its way out, with or without a thread: the ensure keeps the message in a C local, and the inner `begin` zeroes the slot that rooted it.

```ruby
n = 3
begin
  begin
    raise ArgumentError, "outer #{n}"
  ensure
    begin
      raise TypeError, "inner #{n}"
    rescue => e1
      puts e1.message
    end
    p Thread.new { churn("a") }.value
    p churn("x")
  end
rescue => e
  puts e.message          # outer 3
end
```

On master this prints `x0` for the last line at level 1, and stops at level 2 and with the verifier. Here it prints `x0` at level 1 and with the verifier and seven bytes of a freed String at level 2, exit 0 each time: the other thread's collection no longer frees what this change publishes, so the run goes on to the wrong line. With `p 2000` in place of the thread's line, master and this change print the same wrong lines (`x35`, `x35`, seven such bytes) with exit 0.

Test: `test/thread_parked_rescue_rooted.rb`, in `GC_STRESS_TESTS`: a message the runtime formats and one the program formats, an exception object bound and not bound, the rescuing thread waiting and the main thread waiting, a handler still open, a slot above the open handlers that the next `begin` covers again, and an `ensure` running while its exception is on the way out. On master it prints its `.expected` in a plain run and at `SPINEL_GC_STRESS=1`, and aborts in every run at level 1 with `SPINEL_GC_VERIFY=1` and at level 2, with and without the verifier (6 runs a lane, gcc and clang); with this change it is right in 60 runs across the five lanes, gcc and clang. Each part taken out in turn makes it abort again (12 runs a lane, gcc): the mark's set, the message roots, the object's root and the cause's root in every run at level 2 and at level 1 with the verifier; the clearing of the slots above at level 1 with the verifier only, in every run; and a mark that drops while a message is still in its slot in 6 runs of 12 at level 1 with the verifier and in 7 of 12 at level 2. Two lines change nothing in the test when taken out: the drop itself, which is only the cost's, and the line that keeps the mark up for an object stored with no message, which no raise in the test does.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal`. No value is past 2^31. optcarrot's generated C did not change: the compiler is untouched. This depends on no other pull request.
