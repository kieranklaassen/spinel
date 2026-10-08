<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def cleanup
  raise IOError, "cleanup failed"
end

def work
  raise ArgumentError, "work failed"
rescue ArgumentError => orig
  begin
    cleanup
  rescue IOError
    raise orig
  end
end

begin
  work
rescue => e
  p e.cause
end
```

prints `#<IOError: cleanup failed>`, and the cause of that IOError is the ArgumentError again: a ring, so `e = e.cause while e.cause` never ends. After, as CRuby: `nil`.

A raise that names no cause takes the exception being handled, or the one an ensure body has in flight. `sp_raise_cls` already made one exception to that: the very object being handled, raised again, keeps the cause it had. The same holds a step further out. The IOError was raised while the ArgumentError was handled, so the ArgumentError is its cause; when the ArgumentError is raised again in the IOError's rescue, taking the IOError would close the ring. Where the cause chain of the handled exception leads back to the object raised, that object now keeps the cause it had (`sp_exc_implicit_cause`, which asks `sp_exc_cause_chain_reaches` as the check of `cause:` does). The exception in flight through an ensure is read the same way, so an object raised from its own ensure (`begin; raise e; ensure; raise e; end`) is no longer its own cause.

Left alone: a raise by class and message, and the raise of an object the handled exception does not lead back to, take the handled exception as before (the test's last two lines). The change is in the runtime only: no generated C changes.

Cost (callgrind, gcc -O2, master then this). The raised object is kept in a local and tested once, so a raise of a class and a message goes on at that test: one instruction more with nothing handled (407,673,516 to 407,873,915 for 200,000 raises) and one less inside a rescue clause (821,452,175 to 821,251,446 for 200,000). A raise handed on by a rescue that does not match pays one more (134,656,953 to 134,696,238 for 20,000 rounds of a raise and a hand-on), and a bare `raise` again three less (57,557,325 to 57,496,624 for 20,000). An object raised again in the rescue of another exception pays the walk of that exception's chain, 14 instructions here (562,134,672 to 564,933,943 for 200,000).

Not here, each the same on master:

- An exception whose cause `a` is not yet stored in it when it passes an ensure whose body raises `a` (it was raised in the rescue of `a` by class and message, raised there as an object, or raised with `cause: a`): the cause is lost at the ensure, so nothing leads back to `a` and `a` takes the first as its cause. Keeping it there is a change of its own.
- A rescue modifier stores the cause outright where a rescue clause fills only an empty one: an exception that carries a cause and is raised again inside another rescue, caught by a modifier (`(raise e) rescue $!`), has that rescue's exception for a cause.
- `raise orig, "work failed twice"` in the program above: the copy with the new message is another object, so no ring comes of it, but it takes the IOError as its cause where CRuby gives it none.
- An exception that has been another's cause, raised again in the rescue of an exception it did not cause (`raise first` inside `rescue KeyError`), takes that one. In CRuby an exception that has once been a cause takes none after.

The test raises the first error again when the cleanup fails, across three exceptions, from an ensure with the effect in flight and from the object's own ensure; keeps a cause an exception already has; shows the two raises that still take the handled exception; and counts 200 more.

Measured on master ed9861279, with this change alone. The test is right at -O0 to -O3, with clang, under both stress modes and with `--share-strings`; master has 5 of its 8 lines wrong at every level. Of 256 attack programs (a chain of two or three exceptions with the object raised again at its end or in its middle, made with `cause:`, in flight through an ensure, in the object's own ensure and its own rescue; raised as `raise x`, `raise x, "again"` and from a method; caught by a rescue clause, across a method and by a rescue modifier) master is right on 132 and this on 216; none is lost. The 40 left print master's bytes: 34 raise the copy with a new message and 6 catch an exception that carries a cause with a rescue modifier, the third and second items above.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, one commit on master ed9861279: the build, the test in the seven builds and with `--share-strings`, `ruby tools/gate.rb check` with the change staged, `make share-strings-test`, `make int-min-test`, `make backtrace-test`, optcarrot's C by hash, eleven cost programs under callgrind, and the 256 attack programs on this head and on master. The compiler is not touched, so no corpus program's C changes.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none
