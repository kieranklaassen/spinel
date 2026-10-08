<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
begin
  ["a", "b"].each { |c|
    begin
      begin
        next if c == "a"
      ensure
        print "e"
      end
    rescue
      print "r"
    end
  }
  raise "late"
rescue => ex
  puts ex.message
end
```

prints `eerlate` (`spinel diff`: output-diff). CRuby prints `eelate`. A `next` under an `ensure` ran the ensure and then the loop's C `continue`, and the frame of the `begin`/`rescue` around the ensure stayed on the exception stack. The raise after the loop landed in it: the rescue clause of a turn that was over ran. One frame stays for every such `next`, so a loop of two hundred turns ends in SystemStackError with no raise in it.

The deferred `break` beside it already pops the frames it leaves, down to the enclosing ensure's or down to the loop's. The deferred `next` now pops the same counts, where the loop's body owns the `begin`: the `continue` is `sp_exc_top -= N; continue;`, and where the `next` chains to an enclosing ensure its `sp_exc_top--` is `sp_exc_top -= N`.

Cost: none at run time on a program that was right. The C changes only after an ensure that holds a `next` of the loop its `begin` stands in; any other `begin` emits the C it did: no corpus program's generated C changes but the new test's (`tools/cident.sh`), and optcarrot's C is unchanged. Compile time is master's: whether the loop's body owns a `begin` is asked for every such `begin`, so the body is walked once and its nodes marked (`loop_body_owns`). One `each` whose body is 500, 2,000 or 8,000 such statements compiles to C in 0.12, 1.88 and 29.1 seconds, against 0.13, 1.79 and 29.4 on master.

Checked on generated programs, C first and then by run against CRuby: 19,992 programs (17 loops, 14 nests of begin, rescue and ensure, 7 ways out, with and without a raise after the loop, in 6 places); the C changes in 2,520; of 1,195 of those run, 816 that were wrong or ended in SystemStackError are right, 151 were right and are, and 228 are wrong as before, each with a `redo` inside a `begin` (below). None that was right is wrong, and none that raised or did not build prints a wrong answer.

Not in this change:
- A block whose loop another emitter writes leaves the frame as before, and that is most iterators. Of 62 loop forms tried with the first program, 21 are cured (`each`, `reverse_each`, `each_slice`, `each_cons`, `each_entry`, `each.with_index`, `zip`, `tap`, `for`, `while`, `until`, `times`, `upto`, `downto`, `step`, a Range's `each`, a Hash's `each`, `each_pair`, `each_key` and `each_value`, and `scan` with a block) and in 35 the raise after the loop still lands in the frame a turn left (most print `eerlate`): `each_with_index`, `each_with_object`, `map`, `map!`, `map.with_index`, `flat_map`, `filter_map`, `select`, `reject`, `partition`, `group_by`, `sort_by`, `min_by`, `max_by`, `sum`, `count`, `all?`, `any?`, `none?`, `find`, `find_index`, `take_while`, `drop_while`, `inject`, `cycle`, `uniq`, `times.map`, a Range's `map`, a Hash's `map`, `select` and `any?`, `gsub`, `then`, a method's `yield` and a called `&blk`.
- One chain keeps master's count: an `ensure` that stands directly in the `rescue` or `else` clause of a `begin` with its own `ensure` leaves no frame, and the `next` still pops one. `begin; ["a", "b"].each { |c| begin; print "t"; raise "x" if c == "a"; rescue; begin; print "e"; next; ensure; print "E"; end; ensure; print "u"; end; print "v" }; raise "late"; rescue => ex; puts ex.message; end` prints `teEutuv` and dies with `late (RuntimeError)` where CRuby prints `teEutuvlate`.
- A `redo` inside a `begin` with an `ensure` does not run the ensure: `n = 0; ["a", "bb", "c"].each { |x| begin; if n == 11 && x.size > 1; n += 1; redo; end; n += 1; ensure; n += 10; end }; p n` prints `34` where CRuby prints `44`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
