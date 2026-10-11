<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
begin
  raise KeyError, "handled"
rescue KeyError
  begin
    begin
      raise TypeError.new("t")
    ensure
      puts "ie"
    end
  rescue TypeError => e
    puts "took #{e.message} cause #{e.cause.inspect}"
  end
end
```

prints `ie` and `took t cause nil`, at every level. CRuby prints `ie` and `took t cause #<KeyError: handled>`.

After: CRuby's lines.

A raise stages the cause in `sp_pending_cause` and leaves it to the rescue that catches the exception to put it on the object. An ensure's landing is no catch: an exception raised by class and message gets its object there, holding the staged cause, but an object that already exists was left as it was. The ensure then resumes the exception with `sp_reraise_continues`, which reads the cause from the object, and found none. `$!.cause` read in the ensure's own body was nil for the same reason.

An object now takes that cause at the raise that first hands it over, where it has none and no `cause:` was given, as CRuby gives it at the raise: the exception being handled, else the one in flight through an ensure, by the test `sp_raise_cls` stages it with (`sp_exc_implicit_cause`). `sp_exc_takes_cause` does it, called for an object the program raises (`sp_raise_exc`) and for one the runtime makes as it raises: a NoMethodError that holds its name, a KeyError that holds its key, a StopIteration, a signal's exception. Every landing then sees the cause: an ensure, a `Mutex#synchronize` block, a filter's block, an else clause. An explicit `cause: nil` stays nil, an object that has a cause keeps it, a frozen object takes none.

A landing that raises again the exception it holds, a rescue that does not match or `Kernel#loop`, does not call it: that raise is not the first, and giving the cause there would put the handled exception on an object raised with `cause: nil`.

Not here: an exception that passes a rescue none of whose clauses takes it is raised anew there and takes the handled exception as its cause where it has none, an explicit nil too. That is the pull request "A rescue that declines an exception passes it on with its cause".

Not here either: a fiber's or a thread's exception, raised again in the one that resumes or joins it while an exception is handled there, has no cause when it leaves through an ensure, as on master; CRuby gives it the handled exception. That raise is a landing's too.

In `lib/spinel_rt.h` `sp_exc_takes_cause` is new, with its declaration for the runtime's own units; a line calling it is added to `sp_raise_exc`, to `sp_raise_stop_iteration` and to the signal's raise, and two lines are edited to pass the object just made through it: the return of `sp_exc_recover_named` and the line of `sp_raise_cls` that calls `sp_exc_apply_staged`. No name is removed and no signature changes.

Cost (callgrind, -O2, master then this, with gcc 13.3 and with clang 18.1). The compiler is untouched, so no program's C changes. Where no exception is raised nothing moves: 25 programs (an ensure, a rescue, a rescue modifier, a `synchronize` block, a filter's block, nested, as a value and in a method, a guard that would raise an object, each run a million times) count the same to the instruction with both compilers, but for two `synchronize` programs with gcc, which count 2,269 and 2,265 fewer in a whole run of 358 million, all of it in glibc's read of the process map at a thread's start. On the exception's path a raise by class and message that makes no object counts nothing more: the same to the instruction with gcc, and with clang the same or, where it leaves a `synchronize` block, 4 to 8 fewer a pass. A pass that raises an object in a rescue body through an ensure, three raises with the one that resumes, goes from 8,264 instructions to 8,313 with gcc and from 8,171 to 8,212 with clang; a pass that rescues a `Hash#fetch` of a missing key, from 2,773 to 2,799 and from 2,689 to 2,718.

The test raises an object while another exception is handled and lets it leave through an ensure: taken by a clause of the begin around, out of a method's own ensure, with `$!.cause` read in the ensure, with a class that has an initialize of its own, out of a `synchronize` block, out of a filter's block, in an else clause, and made by the runtime (a NoMethodError, a KeyError out of `fetch`, a StopIteration). Beside them are seven cases master has right: raised by class and message, an explicit `cause: nil`, an object that has a cause, a frozen object, and an object raised with `cause: nil` that a rescue declines before an ensure clause, before a method's own ensure, and that leaves a `loop`.

Measured on master 0890056b9665. The test is right at -O0 to -O3, with clang, under both stress modes, with `--share-strings` and as the gate's shared leg builds it; master has 13 of its 35 lines wrong at every level. No corpus program's C changes (6,911 programs, in the default build and with `--share-strings`), so no refusal is added or lifted. optcarrot's C is unchanged.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

On Linux x86-64, on this head, one commit on master 0890056b9665: the build from nothing with gcc and with clang; the test in the seven builds, as the gate's shared leg builds it, with `--share-strings` under both stress modes, and with clang at -O0 under `--int-overflow=wrap` and `promote`; `ruby tools/gate.rb check` with the commit staged and `check-range` over it; the C of every corpus program against master's, in both settings; the 544 tests of `test/` that raise and hold a rescue or an ensure built and run (two need `--int-overflow=promote`, which this runner does not pass, and answer as on master); `make backtrace-test`, `make scale-test`, `make int-min-test`, `make gc-stress-test`, `make share-strings-test`, and `make share-verify-test`, which answers as it does on master; optcarrot's C; the cost programs under callgrind on master and on this head.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (compared with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: none
