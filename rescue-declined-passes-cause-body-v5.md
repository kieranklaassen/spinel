<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
begin
  raise KeyError, "handled"
rescue KeyError
  begin
    begin
      begin
        raise TypeError, "a", cause: nil
      ensure
        puts "ie"
      end
    rescue IOError
      puts "miss"
    ensure
      puts "oe #{$!.cause.inspect}"
    end
  rescue TypeError => e
    puts "out #{e.cause.inspect}"
  end
end
```

prints `ie`, `oe #<KeyError: handled>` and `out #<KeyError: handled>`, at every level. CRuby prints `ie`, `oe nil` and `out nil`.

After: CRuby's lines.

A rescue none of whose clauses takes an exception raised it again as a new raise, and a new raise works the cause out anew: the exception left with the handled exception as its cause, whatever it was raised with. An explicit `cause: nil` was lost, an explicit cause that is another exception was replaced, and a rescue modifier did the same to what is no StandardError. A nested ensure raises into the rescue around it, so an exception leaving an inner ensure for clauses that decline it came this way too.

In CRuby a rescue that does not match is no raise: the exception goes on. The pass-through now sets `sp_reraise_continues`, as an ensure that resumes an exception does, and `sp_raise_cls` hands on the object's own cause. An exception raised by class and message has no object at that point: its cause is still staged in `sp_pending_cause`, and continuing keeps that. A `Mutex#synchronize` block or a filter's block resumes an exception that has no object through the same raise, so `raise TypeError, "t", cause: nil` leaving such a block in a rescue body kept the handled exception as its cause, and now has none there either.

Not here: a rescue with a clause whose operand runs code of the program before the rescue declines. That code may raise and rescue on its own, which replaces the staged cause, so such a rescue raises anew as master has it (`rescue_operand_runs_code`):

```ruby
def pick
  begin
    raise ArgumentError, "inside pick"
  rescue ArgumentError
    nil
  end
  IOError
end
begin
  begin
    raise KeyError, "low"
  rescue KeyError
    begin
      raise TypeError, "t", cause: nil
    rescue pick
      puts "not reached"
    end
  end
rescue TypeError => e
  p e.cause
end
```

prints `#<KeyError: low>` before and after, where CRuby prints `nil`. An operand read where the clause stands, a constant, through a path of constants too, or a variable, splatted or not, runs no code and continues like a class name.

In `lib/spinel_rt.h` the line of `sp_raise_cls` that stages the cause is edited (a raise that continues with no object keeps the staged cause) and the comment of `sp_reraise_continues` is extended: no name is removed and no signature changes.

Cost (callgrind, -O2, master then this, with gcc 13.3 and with clang 18.1). The rescue's pass-through gains one store, on the path of an exception no clause took. Where no exception is raised nothing moves: 25 programs (an ensure, a rescue, a rescue modifier, a clause on a splat, a `synchronize` block, a filter's block, nested, as a value and in a method, each run a million times) count the same to the instruction with both compilers, but for two `synchronize` programs with gcc, which count 2,269 and 2,265 fewer in a whole run of 358 million, all of it in glibc's read of the process map at a thread's start. A pass in which a rescue declines an exception goes from 7,625 instructions to 7,619 with gcc and from 7,588 to 7,577 with clang; an object raised in a rescue body, declined, from 12,272 to 12,292 and from 12,211 to 12,251; by class and message in a method of its own, declined, from 6,626 to 6,622 and from 6,627 to 6,639. A raise that a clause takes at once runs the edited line of `sp_raise_cls` too: 1 instruction more with gcc, 2 fewer with clang. The compiler writes 26 bytes more of C for each such rescue; compiling a file of 1,000 of them takes 978,417 instructions more of 2,677,793,306, and 2,000 take 1,948,210 more of 5,900,892,263.

The test raises while another exception is handled, under a rescue that declines: an explicit `cause: nil` by name, with the ensure of that begin reading the cause, through an inner ensure first, an explicit cause that is another exception, two clauses that decline, an object with an explicit nil, out of a `synchronize` block and out of a filter's block, with a clause declining around and with none, a rescue modifier declining what is no StandardError as a statement and as a value, an exception raised again while the one it caused is handled, and clauses on a list held in a constant, on a class held in a local, and on a list and a class held in a module's constants. Beside them are four cases master has right: no cause given, by name and as an object, and a KeyError out of `fetch` that a rescue declines, with an inner ensure before it too.

Measured on master 0890056b9665 with "An exception object keeps its cause through an ensure" beneath. The test is right at -O0 to -O3, with clang, under both stress modes, with `--share-strings` and as the gate's shared leg builds it; master has 21 of its 34 lines wrong at every level. The C of 1,982 corpus programs changes and of 4,930 does not (400 of the tests among them were built and run: 399 print their `.expected`, and the other needs arguments this runner does not pass and prints the same on master): 1,951 by that one store in each rescue that can decline and nothing else. In the other 31 the added bytes also move where a top level past 64 KB is cut into parts: built and run on both commits they print the same lines, and the 26 whose count does not move from run to run count from 10,976 fewer instructions to 40 more in a whole run (0.02% at most). No refusal is added or lifted. optcarrot's C is unchanged.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

On Linux x86-64, on this head, two commits on master 0890056b9665: the build from nothing with gcc and with clang; both tests in the seven builds, as the gate's shared leg builds them, with `--share-strings` under both stress modes, and with clang at -O0 under `--int-overflow=wrap` and `promote`; `ruby tools/gate.rb check` with the commit staged and `check-range` over it; the C of every corpus program against the commit beneath, in both settings, and 400 of the tests whose C changed built and run; the 544 tests of `test/` that raise and hold a rescue or an ensure built and run (two need `--int-overflow=promote`, which this runner does not pass, and answer as on master); `make backtrace-test`, `make scale-test`, `make int-min-test`, `make gc-stress-test`, `make share-strings-test`, and `make share-verify-test`, which answers as it does on master; optcarrot's C; the cost programs under callgrind on master and on this head.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (compared with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: "An exception object keeps its cause through an ensure"
