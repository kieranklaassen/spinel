<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
begin
  begin
    raise TypeError, "t"
  ensure
    puts "inner ensure"
  end
rescue TypeError
  puts "rescued"
ensure
  puts "outer ensure"
end
```

prints both ensures and dies with the TypeError uncaught. CRuby prints `inner ensure`, `rescued`, `outer ensure`.

After: CRuby's three lines.

After its ensure body a region hands the exception it holds straight to the enclosing ensure, unless a begin's frame lies between the two. The rescue clauses of the enclosing begin itself share that ensure's frame: no frame lies between, and they were passed. A `synchronize` block and the loop of `select!` directly under such a begin passed them the same way.

`EnsureCtx` gains `body_rescue`: the region has rescue clauses and its body is what is being emitted. Where it is set the exception is raised again, and the enclosing begin's frame brings it to those clauses. Where none of them matches, the arm for no match runs the ensure, as it does for what the body itself raises.

Depends on "An ensure runs when no rescue clause of its begin matches". That arm is in its first commit: without it an exception that no clause matches would now skip the outer ensure. The helper the two block regions ask, with the `live` flag beside this one, is in the same commit.

Left alone: everywhere else the C is what it was. Of the 6,536 corpus programs the C of one changes besides the new test (`test/toplevel_proc_return_ensure.rb`), and it prints its `.expected`.

Not here, each the same on master:

- In a rescue or else clause of the enclosing begin the region has no frame, and the hand-on there is as it was. An inner ensure written straight in such a clause still pops a frame that is not its own, so its exception dies uncaught under a caller's `rescue`; with a begin or a rescue modifier between, the exception still goes past that rescue to the outer ensure. "An ensure runs when a rescue clause of its begin raises" and its sibling for the else clause give the clause a frame.
- A rescue modifier between the inner ensure and the body: its frame is not counted on master, so under a begin with an ensure alone the inner region does not see it. "A return, next or break out of a rescue modifier's expression pops its frame" counts it: with both, 12 more programs of the attack set are right and none is lost.

Measured on master 9922a2c74, above the two commits of "An ensure runs when no rescue clause of its begin matches". The test is right at -O0 to -O3, with clang and under both stress modes; master has 24 of its 26 lines wrong at every level. `make backtrace-test` passes. The 34 cost programs run the instructions they ran (callgrind, gcc -O2, each within 20,000). The scale-test ratios are 4.73, 6.14 and 4.13, under their limits. `emit_begin` goes from 355 lines to 358. `ruby tools/gate.rb check` with the change staged answers 0.

The attack set was run on an earlier master, 8dc552254, with this change as it stood there. Of 400 attack programs (the inner region a begin with an ensure, two nested, one with a rescue that does not match beside its ensure, a `synchronize` block, a `select!` block; between it and the outer begin nothing, an `if`, a begin with an ensure, with a rescue that matches, with one that does not, two begins, a rescue modifier as a value and as a statement; in the outer begin's body, rescue clause, else clause and ensure body, the outer begin written out or a method body; its own rescue matching, not matching or absent) master is right on 151, the head beneath on 233 and this on 283; none is lost against either. Of the 117 left, 20 build on neither and 97 are wrong, each printing the bytes of the head beneath: 66 stand in a rescue or else clause and 31 have a rescue modifier between, the two items above.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit above the pull request beneath on master 9922a2c74: the build, the test in the seven builds, `ruby tools/gate.rb check` with the change staged, the C of all 6,536 corpus programs against the C beneath, the changed test and the new one built and run, `make backtrace-test`, `make scale-test`, `make int-min-test`, optcarrot's C by hash, and the 34 cost programs under callgrind.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: the pull request "An ensure runs when no rescue clause of its begin matches"
