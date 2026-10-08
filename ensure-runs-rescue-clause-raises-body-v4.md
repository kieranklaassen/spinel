<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def go
  raise ArgumentError, "y"
rescue ArgumentError
  puts "logged"
  raise
ensure
  puts "ensure"
end

begin
  go
rescue ArgumentError
  puts "caught"
end
```

prints `logged` and `caught`. CRuby prints `ensure` between them.

After: CRuby's three lines.

The begin's one frame is popped when it lands, so the rescue clauses ran with no frame of this begin, and what they raised went to the enclosing one, past the ensure. A new `raise`, a call that raises, an `exit` and a `throw` in the clause skipped the ensure the same way. A clause's body now runs under a frame of its own when the begin has an ensure. It is pushed on the landing path, so a begin that raises nothing enters one frame as before. Its landing stores the exception for the ensure, as the arm for no match does; a `retry` pops the frame before it jumps, and `return`, `break` and `next` count it already.

A `next` that an ensure inside the clause hands on to this one did not count it: it popped one frame whatever stood between, and left the clause's handler to the `next` itself, which counted it only while the clause had no frame. The hand-on now pops the frames down to the region's base and the handlers of the clauses it leaves (`emit_ensure_next_chain`); outside a rescue clause it is the line it was.

Left alone: a begin with no ensure emits the C it did.

Cost (callgrind, gcc -O2): a raise that a clause rescues pays that clause's frame, 83 instructions (42,840,335 to 44,500,335 for 20,000). A begin with rescue clauses and an ensure that raises nothing pays three instructions more an entry in a method (146,349,135 to 149,349,135 for 1,000,000 entries) and two in a loop at the top level (121,349,099 to 123,349,099). A begin with no rescue clause, or with no ensure, pays nothing.

The test raises from a rescue clause beside an ensure: the smallest case, a file the ensure closes, a bare raise, a new error that takes the handled one as its cause, a call that raises, the second of two clauses as a value, three deep with each ensure running once in order; a clause that ends quietly, returns or retries, as before; break and next from a clause in a loop; a throw from a clause; many times over, so the frames balance; a begin inside the clause with a rescue of its own; a next under an ensure of its own inside the clause, seventy turns and then `$!`, the same from a rescue clause and from the body of a begin between the two; and `exit` from a clause.

Measured on master 9922a2c74, above the pull requests named. The test is right at -O0 to -O3, with clang and under both stress modes; master has 20 of its 37 lines wrong and ends with status 1 at every level. `make backtrace-test` passes. Of the 6,541 corpus programs the C of 26 changes besides the new test, all of them tests, each in a begin that has rescue clauses and an ensure; the 26 print their `.expected`, and 6,514 are identical. The scale-test ratios are 4.73, 6.14 and 4.13, under their limits. `emit_rescue` goes from 348 lines to 379, `emit_expr_node` from 843 to 848, `emit_stmt_inner` from 722 to 726 and `emit_begin` from 359 to 358; the new `emit_ensure_next_chain` is 12 lines. `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit above the pull request beneath on master 9922a2c74: the build, the test in the seven builds, `ruby tools/gate.rb check` with the change staged, the C of all 6,541 corpus programs against the C beneath, the 26 tests whose C changed and the new one built and run, `make backtrace-test`, `make scale-test`, `make int-min-test`, optcarrot's C by hash, and the 34 cost programs under callgrind.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: the pull request "A rescue that does not match hands the exception on with its cause"
