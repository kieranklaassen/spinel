<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

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

prints `y4466`, in a plain run. CRuby prints `boom`.

After: CRuby's line.

An ensure region whose body is done hands the exception it waits with to the ensure region around it: it pops that region's frame and jumps to its ensure body. The collector keeps what the exception slots hold up to `sp_exc_top`, and the slot the message was read from lies above that once the frame is popped, so the first collection in the outer ensure body freed the message. The hand-on now puts the message and the object in the popped frame's slot, as a landing in that frame would have left them.

Two commits. The first moves the hand-on line, written out three times (`emit_begin`, the region of `Mutex#synchronize`, the loop of `select!` and its kin), into `emit_ensure_exc_hand_on` and changes no C. The second adds the two stores there.

Cost: two stores where an exception passes from one ensure to the next, six instructions a hand-on (20,000 of them: 84,075,180 to 84,198,172, callgrind, gcc -O2); nothing where none is raised (a method with an ensure called 1,000,000 times: 140,348,420 before and after).

Not here: the outer ensure body takes that slot again when it enters a begin of its own, calls a method that has a rescue or switches to a Fiber, and a Thread can take it under stress; "An ensure keeps the exception it holds while its body runs" roots the exception for the body.

Measured on master 9922a2c74, above "An exception an ensure body dropped is not a later raise's cause" and "An ensure body's exception stays with its fiber". The test is right at -O0 to -O3, with clang and under both stress modes; master has 1 of its 9 lines wrong at every level, in a plain run. The first commit changes the C of no corpus program (6,531 identical). With the second, the C of 29 changes besides the new test, each by the two stores: the 21 of them under `test/` print their `.expected`, and the 8 package tests were not run here. optcarrot's C is the same before and after both commits. `make backtrace-test` passes; the scale-test ratios are 4.73, 6.14 and 4.13, under their limits. `ruby tools/gate.rb check` answers 0 with either commit staged.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, two commits above the two pull requests beneath on master 9922a2c74: the build of each commit, the test in the seven builds, `ruby tools/gate.rb check` with each commit staged, the C of all corpus programs after each commit against the C beneath it, the 21 tests whose C changed and the new one built and run, `make backtrace-test`, `make scale-test` and `make int-min-test` at each commit, optcarrot's C by hash, and six cost programs under callgrind on both sides.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: the pull requests "An exception an ensure body dropped is not a later raise's cause" and "An ensure body's exception stays with its fiber"
