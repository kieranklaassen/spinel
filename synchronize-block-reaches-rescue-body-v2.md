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

The rule a begin's ensure follows is now one function, `emit_ensure_exc_out`, and the three kinds of region call it, and with them the methods that share their code: `Monitor#synchronize`, `reject!`, `keep_if`, `delete_if`, `filter!`. A begin's ensure writes the C it wrote, and so does a block's region where a rescue lies between: it raises by class and message with the object it may hold left pending. Under a begin with clauses of its own it raises the same way and under the same test of the cause, so a clause binds the object that an ensure inside the block handed up.

Not here: an exception that leaves the block with no cause while another exception is being handled (a new object raised in a rescue body, or any raise with `cause: nil`) is handed on as before, since the raise here would give it the handled exception as its cause, where Ruby gives none or master's landing has not set it; and the two cases the pull request beneath leaves (a program that may give a class a `===` of its own; under a bare clause, a class the runtime cannot place) are left here.

Cost (callgrind, -O2, on the pull request this depends on, then this, with gcc 13.3 and with clang 18.1). A region with no ensure around it writes the C it wrote. With no exception gcc counts the same to the instruction: the eighteen such programs of the round, and a synchronize block under a named clause and under a bare one and `select!` under a named clause (`select!` under a bare clause takes 26 instructions more in a whole run, at the program's start). clang counts the synchronize block the same, and `select!` two instructions a call less under a clause that names a class (191,987,004 to 190,987,004 for 500,000 calls) and two more under a bare one (191,987,082 to 192,987,108): it assigns the function's registers anew for any text at that place. An exception that leaves such a block for a begin whose clauses do not take it now pays for their tests, as one leaving an inner ensure does: 20,000 such out of a synchronize block, 73,863,650 to 177,001,081 with gcc and 76,165,212 to 183,390,288 with clang, and more with each further class the clauses name. Every other exception path measured is unchanged.

The first test raises in a synchronize block and in `select!`'s loop under a begin with rescue clauses and an ensure; with a begin between the block and the ensure, whose clause takes the exception or misses it; under each kind of clause, taken and missed; with an object of the program's own class, and with an ensure inside the block; and many times over. The second holds the cause: an exception raised with `cause: nil` in a synchronize block and in `select!`'s block while another is handled, and one raised again in a synchronize block while one it caused is handled; master prints it right, and a raise without the test of the cause does not.

Measured on master c52df8a11 with the pull request this depends on. The tests are right at -O0 to -O3, with clang, under both stress modes and as the gate's shared leg builds them; master has 45 of the first test's 46 lines wrong at every level and the second right. No corpus program's C changes (6,837 hashed against the C beneath) and no refusal changes. optcarrot's C is unchanged.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, on master c52df8a11 with the pull request this depends on: the build from nothing, the two tests in the seven builds, as the gate's shared leg builds them and with clang at -O0 under `--int-overflow=wrap` and `promote`, `ruby tools/gate.rb check` with the commit staged, the C of every corpus program against the C beneath, `make backtrace-test`, `make scale-test`, `make int-min-test`, `make share-strings-test`, optcarrot's C, and the cost programs under callgrind. And merged with master 55aa88e97: the build from nothing and both pull requests' five tests, in the default build and with `--share-strings`, plain and under both stress modes, and with clang at -O0 under both overflow modes; and `ruby tools/gate.rb check-range HEAD^1 HEAD` over the commit there, which exits 0 (it found no Ruby 4.0 to check the `.expected` files with).

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (they match CRuby 3.3.6 run so; 4.0 is not on this machine)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: the pull request "An exception leaving an inner ensure reaches the rescue around it", whose rule this one gives to the two block regions
