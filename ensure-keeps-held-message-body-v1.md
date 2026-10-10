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

An exception that reaches the ensure with no object is given one at the ensure's entry: the one `$!` reads in the body and a raise in the body takes as its cause. That object is kept alive while the body runs, and it owned a copy of the message. It now holds the raw message itself in the copy's place (`sp_exc_new_for_ensure`, new in `lib/sp_exc.c`) wherever the two are the same bytes, so the message lives for as long as the body can see the object. The entry statement of `emit_begin` calls that function where it called `sp_exc_new_for_catch`, and that one name is the whole change in the generated C. The raise after the body, and the hand to an ensure or to a block's region around it, are the C they were, and each copies the message before anything can collect: `sp_raise_cls` begins with a copy that is made without a collection, and the new function roots the raw message before it makes the object.

Why this form. The object made at the entry is not the one raised again: a rescue of a class of the program with attributes and no `initialize` takes a pending object for its own layout, and this one is the base size. And the ensure's raw-message local is not pointed at the object's copy: an assignment to it in the entry statement, or its address passed there, changes how gcc lays out the function, and costs programs with no exception 5 to 13 instructions a call.

Not in this change. The rescue after an ensure still builds its own object, so it is not the one `$!` read in the body, and a literal's message comes out of an ensure unfrozen. A raise with no message carries an empty string of its own, which the object answers with its class's name and so cannot hold: that string is still read after the body, and `raise ArgumentError` can come out of such an ensure with a string the body built. A message with a NUL in it travels counted, which the object's copy decodes, and is still read after the body too. An exception raised as an object is left as it was: a rescue reads its message from the object, and the report of an uncaught one still reads the raw message. And where master itself makes the object, at the catch when a cause waits or in a rescue clause that declines, the object is master's: for a class of the program with attributes and no `initialize` it is shorter than the class's own, before and after alike.

Cost (callgrind, gcc 13.3 -O2, master then this). Nothing is added on the path with no exception, where the generated C differs in the one name: the eighteen such programs measured take the instructions they took, to within 2,265 in a whole run (1,000,000 calls of a method whose ensure calls a method, 142,356,599 and 142,356,599). An exception that reaches an ensure with no object pays 45 instructions more for each ensure it passes, for the root, the store and its barrier: 20,000 raises through one ensure, 68,494,921 to 69,395,238; through two, 85,843,805 to 87,645,906. One raised as an object pays nothing: five such programs of 20,000 raises take the instructions they took. optcarrot's C changes in its one ensure, by the one name: 2,367,130,228 to 2,367,131,287 instructions, checksum 59662.

The test keeps a message through an ensure body that enters a begin of its own, and an object with what it holds through a body that raises and rescues; hands both from an inner ensure to an outer one that allocates; raises them again to a rescue that does not take them and holds them once more; hands them on to the region of a synchronize block and of `select!`'s loop, and from that loop to a rescue that stands before an ensure around it, and raises in such a block under an ensure that allocates; raises a class of the program with twelve attributes and no `initialize` by name through an ensure that makes other exceptions, and stores all twelve in the rescue; reads `$!`'s message in the body, before and after it allocates; and drops the exception by a `return` in the ensure body.

Measured on master 2b0ebc0a6. The test is right at -O0 to -O3, with clang, under both stress modes and as the gate's shared leg builds it; master has 3 of its 44 lines wrong at every level, in a plain run. The C of 150 corpus programs changes (117 tests, 33 package tests) and of 6,668 does not; no refusal changes. The 117 tests print their `.expected`, and the package tests answer as they do on master (32 of 33 right on both, 1 wrong on both).

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, one commit on master 2b0ebc0a6: the build from nothing, the test in the seven builds and as the gate's shared leg builds it, `ruby tools/gate.rb check` with the commit staged, the C of every corpus program against master's, the tests whose C changed built and run, the package tests whose C changed on master and here, `make backtrace-test`, `make scale-test`, `make int-min-test`, `make share-strings-test`, optcarrot built and run plain and under callgrind, and thirty-three cost programs under callgrind on master and here.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (above)
- [ ] Depends on: none
