<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def churn
  a = []
  4000.times { |i| a << ("filler string number " + i.to_s) }
  a.length
end

def go(n)
  raise ArgumentError, "the message of error number " + n.to_s
ensure
  begin
    churn
  rescue TypeError
  end
  churn
end

begin
  go(0)
rescue => e
  puts e.message
end
```

prints `filler string number 3334`, in a plain run at every level. CRuby prints `the message of error number 0`. And

```ruby
begin
  begin
    begin
      raise KeyError, "boom"
    ensure
      x = 1
    end
  ensure
    keep = []
    50000.times { |i| keep << "y" + i.to_s }
  end
rescue => e
  puts e.message
end
```

prints `y4466` for `boom`.

After: CRuby's lines.

While an ensure body runs, the exception that is raised again after it waits as a class and a raw message in C locals, and the message does not outlive the body. A begin the body enters takes the slot the message was read from, and an inner ensure that hands its exception to the ensure around it has popped that slot's frame, so the first collection in the body frees the message. The rescue that takes the exception afterwards reads freed bytes, and so do the report of an uncaught exception and a thread's join.

The ensure already has the exception as an object at its entry: the one `$!` reads in the body and a raise in the body takes as its cause. That object is kept alive while the body runs and owns a copy of the message. The ensure now holds that object, making it there when the raise carried none, and raises it again after the body as `raise e` does. In `emit_begin` that is the entry statement and the two raise lines. The regions of `Mutex#synchronize` and of `select!`'s loop raise an object that an ensure inside their block handed up the same way, and raise by class and message as before when they hold none. The runtime is not changed.

Two more answers become CRuby's with it. The rescue after an ensure binds the object `$!` read in the body, where master builds a second one (`e.equal?($seen)` is false there). And a literal's message stays frozen through an ensure.

Cost (callgrind, gcc -O2, master then this). Nothing is added on the path with no exception: 1,000,000 calls of a method whose ensure calls a method take 142,351,724 instructions before and 140,351,760 after, and with a rescue clause on the same begin 142,351,830 and 140,351,794; of the eighteen such programs measured, 11 are cheaper by two instructions a call and the dearest is 18 instructions over its whole run. An exception through an ensure is cheaper when the raise carried no object, since one object is made for it where master makes two: 20,000 raises through one ensure, 67,568,999 to 51,611,546; through two, 84,477,732 to 54,091,736. One that a rescue clause of the same begin has declined is an object already, and its message is now read from the object: 37 instructions more for each (144,233,938 to 144,974,335 for 20,000). optcarrot's C changes in its one ensure, by the two statements: 2,367,098,996 to 2,367,106,016 instructions (+0.0003 percent), checksum 59662.

The test keeps a message through an ensure body that enters a begin of its own, and an object with what it holds through a body that raises and rescues; hands both from an inner ensure to an outer one that allocates; raises them again to a rescue that does not take them and holds them once more; hands them on to the region of a synchronize block and of `select!`'s loop, and raises in such a block under an ensure that allocates; checks that the rescue binds the object `$!` read in the body; and drops the exception by a `return` in the ensure body.

Measured on master 2d5b3d121. The test is right at -O0 to -O3, with clang, under both stress modes and as the gate's shared leg builds it; master has 4 of its 27 lines wrong at every level, in a plain run. The C of 263 corpus programs changes (227 tests, 36 package tests) and of 6,496 does not; no refusal changes. The 227 tests print their `.expected`, and the package tests answer as they do on master (35 of 36 right on both).

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, one commit on master 2d5b3d121: the build from nothing, the test in the seven builds and as the gate's shared leg builds it, `ruby tools/gate.rb check` with the commit staged, the C of every corpus program against master's, the tests whose C changed built and run, the package tests whose C changed on master and here, `make backtrace-test`, `make scale-test`, `make int-min-test`, `make share-strings-test`, optcarrot built and run plain and under callgrind, and twenty-seven cost programs under callgrind on master and here.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (above)
- [ ] Depends on: none
