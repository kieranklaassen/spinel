<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def locked(m)
  m.synchronize { raise TypeError, "held" }
rescue TypeError => e
  puts "rescued " + e.message
ensure
  puts "outer ensure"
end
m = Mutex.new
locked(m)
p m.locked?
```

prints `outer ensure` and dies of the TypeError, uncaught, at every level. CRuby prints `rescued held`, `outer ensure`, `false`. A `select!` whose block raises does the same in that place.

After: CRuby's lines.

A `Mutex#synchronize` block and the loop of `select!` each run in a region of their own, which unlocks the mutex or puts the Array back when the block raises and then passes the exception on. With an ensure region around it, a begin's ensure asks two things before it hands the exception to that region: whether a begin with a rescue lies between the two, and whether the enclosing begin has rescue clauses of its own. Either way it raises the exception again, so the clauses are offered it first. The two block regions ask only the first, so the clauses of the begin that has the ensure are passed by.

The rule a begin's ensure follows is now one function, `emit_ensure_exc_out`, and the three kinds of region call it. A begin's ensure writes the C it wrote, and so does a block's region where a rescue lies between: it raises by class and message with the object it may hold left pending. Under a begin with clauses of its own it raises the same way, so a clause binds the object that an ensure inside the block handed up.

Cost (callgrind, gcc 13.3 -O2, on the pull request this depends on, then this; counted in one shell). On the path with no exception, and for a block with no ensure around it, seventeen of the eighteen programs measured take the instructions they took, to the instruction; the eighteenth, a `select!` under a begin with rescue clauses and an ensure, takes one instruction less a call (201,527,025 to 201,027,025 for 500,000 calls), its region now ending in the raise where it ended in the hand-on. An exception that leaves such a block for a begin whose clauses do not take it now pays for their tests, as one leaving an inner ensure does: 20,000 such, 73,862,461 to 176,799,892. Every other exception path measured is unchanged.

The test raises in a synchronize block and in `select!`'s loop under a begin with rescue clauses and an ensure; with a begin between the block and the ensure, whose clause takes the exception or misses it; under each kind of clause, taken and missed; with an object of the program's own class, and with an ensure inside the block; and many times over.

Measured on master c52df8a11 with the pull request this depends on. The test is right at -O0 to -O3, with clang, under both stress modes and as the gate's shared leg builds it; master has 45 of its 46 lines wrong at every level. No corpus program's C changes (6,836 hashed against the C beneath) and no refusal changes. optcarrot's C is unchanged.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, on master c52df8a11 with the pull request this depends on: the build from nothing, the test in the seven builds, as the gate's shared leg builds it and with clang at -O0 under `--int-overflow=wrap` and `promote`, `ruby tools/gate.rb check` with the commit staged, the C of every corpus program against the C beneath, `make backtrace-test`, `make scale-test`, `make int-min-test`, `make share-strings-test`, optcarrot's C, and twenty-seven cost programs under callgrind.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: the pull request "An exception leaving an inner ensure reaches the rescue around it", whose rule this one gives to the two block regions
