<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def go
  raise TypeError, "t"
rescue ArgumentError
  puts "not reached"
ensure
  puts "ensure"
end

begin
  go
rescue TypeError
  puts "caught"
end
```

prints `caught`. CRuby prints `ensure` first.

After: both lines.

A begin with rescue clauses and an ensure has one frame. On landing the clauses run with that frame popped, and the arm for no match raised again at once: a jump to the enclosing frame, past the ensure, so a lock stayed held and a file stayed open. `exit` inside a begin with a bare rescue skipped the ensure the same way. That arm now stores the exception as a begin with no rescue does and falls into the ensure, which raises it again after its body.

The commit also changes what a `synchronize` block and the block of `select!` and its siblings do with an exception, because either change alone turns a right program wrong. A `synchronize` block and the loop of `select!` and its siblings emit an ensure region of their own, for the unlock and for the array's repair. Inside a begin's ensure region they handed an exception straight to that ensure and popped one frame, whatever stood between:

```ruby
def go(m, log)
  begin
    begin
      m.synchronize { raise IOError, "in" }
    rescue IOError
      log << "rescued "
    end
  ensure
    log << "ensure "
  end
end
```

left `ensure ensure ` in log and raised the IOError out of `go`; CRuby rescues it and leaves `rescued ensure `. The frame popped was the inner begin's: its rescue never saw the exception, and the outer frame, still armed, caught the raise after the ensure body and ran the body again. Where neither begin has a clause that matches, the body ran once only because the outer begin's arm for no match went past it the second time; that arm runs it now, so with this change alone such a program would print `ensure` twice. The two regions now look for a frame between as `emit_begin`'s own tail does (`emit_ensure_exc_block_out`) and raise the exception again when one stands there. `EnsureCtx` gains `live`, cleared when the region's body is done: in a rescue or else clause of the outer begin no frame of it is armed, a re-raise would leave without the ensure body, and the exception is handed over as it was.

The exception keeps its backtrace through the ensure body. In a `--debug` build the arm for no match set `sp_bt_keep` before it raised again, and the raise after the ensure body would take a new snapshot at the begin. A debug build saves the frames as no clause matches (`sp_bt_save`) and puts them back for the raise after the ensure body (`sp_bt_restore`), so they also survive an ensure body that raises and rescues an exception of its own or resumes a Fiber, either of which takes the one buffer. The lines are emitted under `--debug` only. `test/backtrace/pass_through_ensure.rb` runs five such ensure bodies under `make backtrace-test`.

The local that holds the object is assigned in that arm now. Where an exception can pass every clause it is declared with no initializer, which would be a store on every entry (the local lives across the `setjmp`), and `volatile`, which keeps it in the frame; it is written wherever the flag is set and read only under the flag. A begin whose clauses end at `rescue Exception` keeps master's declaration.

Depends on the pull request "An ensure keeps the exception it holds while its body runs". This sends an exception to an ensure body that master skipped, and without that pull request the body runs with the exception unrooted:

```ruby
def churn
  a = []
  4000.times { |i| a << ("filler string number " + i.to_s) }
end

def go(n)
  raise ArgumentError, "the message of error number " + n.to_s
rescue TypeError
ensure
  begin
    churn
  rescue TypeError
  end
end
```

would hand `filler string number 3334` to the caller's `rescue => e` as `e.message`, where master and the two together give `the message of error number 0`. This also calls that pull request's helper, `emit_ensure_exc_hand_on`.

Not here, each the same on master:

- An ensure with no rescue clause beside it still cuts the frames in a debug build.
- An ensure is still skipped when a rescue clause or the else clause of its begin raises. For the same reason a `synchronize` or `select!` block written in such a clause, under a begin of its own, still hands its exception past that begin's rescue.
- A `synchronize` or `select!` block directly in the body of a begin that has rescue clauses and an ensure still passes those clauses. That is a change of its own.
- A `return` or a `next` that leaves such a block through a begin inside an ensure region still leaves a frame armed.
- An ensure body left by a `throw` or a proc's `return` while a rescue clause of an outer begin is running leaves that clause's exception as the cause of a later raise (`raise "later"` then has the outer clause's exception for its cause where CRuby has none). Master does the same wherever it already ran the ensure.

Left alone: a begin that lacks either clause emits the C it did.

Cost (callgrind, gcc -O2, the pull request beneath then this): entering a begin with both clauses costs what it did (139,350,468 instructions for 1,000,000 entries, before and after; four more programs with such a begin are the same), but for one shape of those measured: two nested begins in a method, the outer with both clauses, where gcc saves one more register and each entry pays one instruction (237,349,761 to 238,349,761 for 1,000,000). A raise that no clause matches now runs the ensure body and is raised again, 768 instructions more each (134,776,970 to 150,128,909 for 20,000). In a debug build, where each raise takes a backtrace of some 300,000 instructions, the same 20,000 take 6,153,771,138 on master and 6,171,916,835 here.

Measured on master 84f5b5020, above the pull request "An ensure keeps the exception it holds while its body runs". The two tests are right at -O0 to -O3, with clang and under both stress modes; master has 12 of the 30 lines of the one and 9 of the 10 of the other wrong at every level. `make backtrace-test` passes with the new file, and so do `make share-strings-test` and `make int-min-test`. Of the 6,611 corpus programs the C of 21 changes besides the two new tests, each in a begin that has both clauses, and they print their `.expected`. The scale-test ratios are 4.73, 6.14 and 4.13, under their limits. `emit_rescue` goes from 338 lines to 347 and `emit_begin` from 346 to 363; `rescue_chain_can_miss` is 12 lines. `ruby tools/gate.rb check` with the commit staged answers 0.

Of 400 attack programs (the inner region a begin with an ensure, two nested, one with a rescue that does not match beside its ensure, a `synchronize` block, a `select!` block; between it and the outer begin nothing, an `if`, a begin with an ensure, with a rescue that matches, with one that does not, two begins, a rescue modifier as a value and as a statement; in the outer begin's body, rescue clause, else clause and ensure body, the outer begin written out or a method body; its own rescue matching, not matching or absent) master is right on 151 and this on 233; none is lost. Of the 167 left, 20 build on neither and 147 are wrong: 124 print master's bytes, and 23 differ from them where both are wrong: in 11 the inner begin's ensure body, which master skipped, now runs and the outer one still does not or its rescue is still passed; in 12 the outer ensure body runs twice under a rescue modifier, whose frame master does not count.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, one commit above the pull request beneath on master 84f5b5020: the build, the two tests in the seven builds, `ruby tools/gate.rb check` with the commit staged, the C of all corpus programs against the C beneath, the 21 tests whose C changed and the two new ones built and run, `make backtrace-test`, `make scale-test`, `make int-min-test` and `make share-strings-test`, optcarrot's C by hash, the 34 cost programs and six nested ones under callgrind on both sides, one of them in a debug build on master and here, a Fiber killed inside such a begin, and the attack set on master and on this head.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: the pull request "An ensure keeps the exception it holds while its body runs"
