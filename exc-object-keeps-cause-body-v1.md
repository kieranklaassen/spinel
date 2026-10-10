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

`sp_raise_cls` now gives an object it raises the staged cause where the object has none, as CRuby does at the raise. Every landing then sees it: an ensure, a `Mutex#synchronize` block, a filter's block, an else clause. What the staging decides is as it was: an explicit `cause: nil` stays nil, an object that has a cause keeps it, a frozen object takes none.

Not here: an exception that passes a rescue none of whose clauses takes it is raised anew there and takes the handled exception as its cause, an explicit nil too. That is the pull request "A rescue that declines an exception passes it on with its cause".

In `lib/spinel_rt.h` one statement is added to `sp_raise_cls`, on the line that stages the cause, with a comment: no name is removed and no signature changes.

Cost (callgrind, -O2, master then this, with gcc 13.3 and with clang 18.1). The compiler is untouched, so no program's C changes. Where no exception is raised nothing moves: 22 programs (an ensure, a rescue, a rescue modifier, a `synchronize` block, a filter's block, nested, as a value and in a method, each run a million times) count the same to the instruction with both compilers. On the exception's path a pass that raises once and is rescued counts 8 instructions more with gcc and 4 with clang, of 2,775 and 2,708; a pass that raises an object in a rescue body through an ensure, three raises with the one that resumes, goes from 8,264 instructions to 8,282 with gcc and from 8,171 to 8,183 with clang.

The test raises an object while another exception is handled and lets it leave through an ensure: taken by a clause of the begin around, out of a method's own ensure, with `$!.cause` read in the ensure, with a class that has an initialize of its own, out of a `synchronize` block, out of a filter's block, in an else clause. Beside them are four cases master has right: raised by class and message, an explicit `cause: nil`, an object that has a cause, a frozen object.

Measured on master dacaa29cb84e. The test is right at -O0 to -O3, with clang, under both stress modes, with `--share-strings` and as the gate's shared leg builds it; master has 8 of its 23 lines wrong at every level. No corpus program's C changes (6,898 programs, in the default build and with `--share-strings`), so no refusal is added or lifted. optcarrot's C is unchanged.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

On Linux x86-64, on this head, one commit on master dacaa29cb84e: the build from nothing; the test in the seven builds, as the gate's shared leg builds it, with `--share-strings` under both stress modes, and with clang at -O0 under `--int-overflow=wrap` and `promote`; `ruby tools/gate.rb check` with the commit staged and `check-range` over it; the C of every corpus program against master's, in both settings; the 542 tests of `test/` that raise and hold a rescue or an ensure built and run (two need `--int-overflow=promote`, which this runner does not pass, and answer as on master); `make backtrace-test`, `make scale-test`, `make int-min-test`, `make gc-stress-test`, `make share-strings-test`, and `make share-verify-test`, which answers as it does on master; optcarrot's C; the cost programs under callgrind on master and on this head.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (compared with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: none
