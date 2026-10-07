<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A thread that has rescued an exception, and is then parked while another thread collects, lost the exception's message to that collection; its own next collection marked the freed String.

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

On master (759d120fd) at `SPINEL_GC_STRESS=2`, gcc and clang, this stops with "the mark reached a freed heap string", phase `globals:exceptions`. Three of the suite's own tests stop the same way there and pass with this change: `test/fiber_cross_thread.rb`, `test/ffi_io_buffer_arg.rb`, `test/io_close_wakes_parked_reader.rb`.

The exception stack is thread-local. The worker that collects marks its own in `sp_mark_in_flight_exceptions`: each frame's message and object, the slot one past the top that a rescue arm has popped and still reads, and it clears every slot above that. A worker parked while another one collects hands its roots over in `sp_publish_worker_roots`, and that published only the objects of the open frames. `sp_raise_cls` stores a heap copy of every message, so after any rescue the slot one past the top names a heap String, and nothing published it. An exception object nothing had bound went the same way, and so did whatever a slot above the window still named once the next `begin` put that slot back inside it.

`sp_publish_worker_roots` now does for a parked worker what `sp_mark_in_flight_exceptions` does for the collecting one: it publishes each frame's message, the message and the object one past the top and the cause an `ensure` holds, and it clears the slots above.

Cost: a park runs 291 instructions where it ran 253 (callgrind, a Queue handed back and forth between two threads 300,000 times; 623,434 parks). That program's wall time is 12.9 s before and 13.0 s after, the median of three, inside its spread. A program with no threads does not park. The compiler is untouched: its binary is byte-identical, so no program's generated C changes.

Test: `test/thread_parked_rescue_rooted.rb`, in `GC_STRESS_TESTS`: a message the runtime formats and one the program formats, an exception object bound and not bound, the rescuing thread parked and the main thread parked, a handler still open, a slot above the open handlers that the next `begin` covers again, and an `ensure` running while its exception is on the way out. On master it prints its `.expected` in a plain run and aborts at `SPINEL_GC_STRESS=1` (9 runs of 12 with gcc) and in every run at level 2; with this change it is right in 60 runs across the five lanes. Each of the five things added, taken out in turn, makes it abort again at level 2; the clearing of the slots above is the one that depends on when the other thread collects, and shows there in 4 runs of 12 (in every run at `SPINEL_GC_STRESS=1 SPINEL_GC_VERIFY=1`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is untouched)
- [ ] Depends on: # (nothing)
