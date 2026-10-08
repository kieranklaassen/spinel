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

Cost, in instructions for 200,000 raises (callgrind, gcc -O2), the pull request beneath then this: an object raised again in a rescue, 562,155,847 to 565,954,366 (19 a raise: the walk of the handled exception's chain); a raise by class and message in a rescue, 821,469,975 to 822,469,613 (5 a raise); a raise with nothing handled, 407,687,932 to 408,685,314 (5 a raise). The 5 are the call to the new helper.

Not here, each the same on master:

- An exception whose cause `a` is not yet stored in it when it passes an ensure whose body raises `a` (it was raised in the rescue of `a` by class and message, raised there as an object, or raised with `cause: a`): the cause is lost at the ensure, so nothing leads back to `a` and `a` takes the first as its cause. "An exception keeps its cause through an ensure" keeps it there.
- A rescue modifier stores the cause outright where a rescue clause fills only an empty one: an exception that carries a cause and is raised again inside another rescue, caught by a modifier (`(raise e) rescue $!`), has that rescue's exception for a cause.
- `raise orig, "work failed twice"` in the program above: the copy with the new message is another object, so no ring comes of it, but it takes the IOError as its cause where CRuby gives it none.
- An exception that has been another's cause, raised again in the rescue of an exception it did not cause (`raise first` inside `rescue KeyError`), takes that one. In CRuby an exception that has once been a cause takes none after.

The test raises the first error again when the cleanup fails, across three exceptions, from an ensure with the effect in flight and from the object's own ensure; keeps a cause an exception already has; shows the two raises that still take the handled exception; and counts 200 more.

Measured on master 9922a2c74, above "An exception leaving an inner ensure reaches the rescue around it". The test is right at -O0 to -O3, with clang and under both stress modes; master has 5 of its 8 lines wrong at every level. `ruby tools/gate.rb check` with the change staged answers 0.

The attack sets were run on an earlier master, 8dc552254, with this change alone on it. Of 256 attack programs (the chain two or three exceptions long, with the object raised again at its end or in its middle, made with `cause:`, in flight through an ensure, the object in its own ensure, its own rescue, an unrelated rescue, a fresh object, one that carries a cause, `cause: nil` and `cause:` the handled one; raised as `raise x`, `raise x, "again"` and from a method; a RuntimeError, a class of the program, a class under Exception; caught by a rescue clause, across a method, by a rescue modifier) master is right on 132 and this on 216; none is lost. The 40 left print master's bytes: 34 raise the copy with a new message and 6 catch an exception that carries a cause with a rescue modifier, the third and second items above. Of 341 more programs written for "A rescue that does not match hands the exception on with its cause" master is right on 199 and this on 201; none is lost.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit above the pull request beneath on master 9922a2c74: the build, the test in the seven builds, `ruby tools/gate.rb check` with the change staged, `make int-min-test`, optcarrot built and run plain and under callgrind, and the 34 cost programs under callgrind. The compiler is not touched, so no corpus program was compiled again.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: the pull request "An exception leaving an inner ensure reaches the rescue around it"
