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

After its ensure body a region hands the exception it holds straight to the enclosing ensure, unless a begin's frame lies between the two. The rescue clauses of the enclosing begin share that ensure's frame, so they were passed. The regions of `Mutex#synchronize` and of `select!`'s loop made no such check at all. And inside the enclosing begin's rescue clause, where that frame is gone already, the hand-on popped one more, the caller's: an exception raised under an inner ensure there died uncaught under a caller's `rescue`.

The three epilogues now ask one helper, `emit_ensure_exc_out`. The exception is raised again when a begin's frame lies between, or when the enclosing region has rescue clauses and its body is what is being left; else it goes to the enclosing ensure through `emit_ensure_exc_hand_on`, which pops that region's frame only if it is still live.

Depends on "An exception handed from an inner ensure to the outer one stays alive", whose helper it calls, on "An ensure keeps the exception it holds while its body runs" and on "An ensure runs when no rescue clause of its begin matches": it is built above the three, and the helper carries the last one's line that puts an exception's frames back in a debug build.

Left alone: where neither case holds the C is what it was.

Measured above those three on master c121a0cbd: the test is right at -O0 to -O3, with clang and under both stress modes (master: 30 lines wrong, dying uncaught, at every level), the tests of the three beneath stay right at every level, and `make backtrace-test` passes. Of 6,364 corpus programs the C of two changes besides the new test (rescue_return_with_ensure, toplevel_proc_return_ensure), and they pass; 6,361 are identical.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged by this commit)
- [ ] Depends on: "An exception handed from an inner ensure to the outer one stays alive", "An ensure keeps the exception it holds while its body runs", "An ensure runs when no rescue clause of its begin matches"
