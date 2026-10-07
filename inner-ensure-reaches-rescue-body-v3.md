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

Left alone: everywhere else the C is what it was. Of 6,451 corpus programs the C of 6,449 is identical. Two change: the new test, and test/toplevel_proc_return_ensure.rb, which prints its `.expected` as before.

Not here, each the same on master:

- In a rescue or else clause of the enclosing begin the region has no frame, and the hand-on there is as it was. An inner ensure written straight in such a clause still pops a frame that is not its own, so its exception dies uncaught under a caller's `rescue`; with a begin or a rescue modifier between, the exception still goes past that rescue to the outer ensure. "An ensure runs when a rescue clause of its begin raises" and its sibling for the else clause give the clause a frame.
- A rescue modifier between the inner ensure and the body: its frame is not counted on master, so under a begin with an ensure alone the inner region does not see it. "A return, next or break out of a rescue modifier's expression pops its frame" counts it: with both, 12 more programs of the attack set are right and none is lost.

Measured on master 8dc552254, above the two commits of "An ensure runs when no rescue clause of its begin matches". The test is right at -O0 to -O3, with clang and under both stress modes; master prints 24 of its 26 lines wrong at every level, and so does the head beneath. Of 400 attack programs (the inner region a begin with an ensure, two nested, one with a rescue that does not match beside its ensure, a `synchronize` block, a `select!` block; between it and the outer begin nothing, an `if`, a begin with an ensure, with a rescue that matches, with one that does not, two begins, a rescue modifier as a value and as a statement; in the outer begin's body, rescue clause, else clause and ensure body, the outer begin written out or a method body; its own rescue matching, not matching or absent) master is right on 151, the head beneath on 233 and this on 283; none is lost against either. Of the 117 left, 20 build on neither and 97 are wrong, each printing the bytes of the head beneath: 66 stand in a rescue or else clause and 31 have a rescue modifier between, the two items above. `make backtrace-test` passes. The scale-test ratios are master's (1.71, 4.74, 6.13, 4.17); `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged by this commit)
- [ ] Depends on: "An ensure runs when no rescue clause of its begin matches"
