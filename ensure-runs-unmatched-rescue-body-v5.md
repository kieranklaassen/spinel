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

The same commit changes what a `synchronize` block and the block of `select!` and its siblings do with an exception, because either change alone turns a right program wrong. A `synchronize` block and the loop of `select!` and its siblings emit an ensure region of their own, for the unlock and for the array's repair. Inside a begin's ensure region they handed an exception straight to that ensure and popped one frame, whatever stood between:

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

The second commit keeps the backtrace such an exception had. In a `--debug` build the raise after the ensure body took a new snapshot at the begin, where the old arm had set `sp_bt_keep`. A debug build now saves the frames as no clause matches (`sp_bt_save`) and puts them back for the raise after the ensure body (`sp_bt_restore`), so they also survive an ensure body that raises and rescues an exception of its own or resumes a Fiber, either of which takes the one buffer. The lines are emitted under `--debug` only: the C of all 6,536 corpus programs is the same with and without the second commit. `test/backtrace/pass_through_ensure.rb` runs five such ensure bodies under `make backtrace-test`.

Depends on "An ensure keeps the exception it holds while its body runs". This sends an exception to an ensure body that master skipped, and without that fix the body runs with the exception unrooted:

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

would hand `filler string number 3334` to the caller's `rescue => e` as `e.message`, where master and the two together give `the message of error number 0`.

And on "An exception handed from an inner ensure to the outer one stays alive": the first commit calls its helper, `emit_ensure_exc_hand_on`.

Not here, each the same on master:

- An ensure with no rescue clause beside it still cuts the frames in a debug build.
- An ensure is still skipped when a rescue clause or the else clause of its begin raises. For the same reason a `synchronize` or `select!` block written in such a clause, under a begin of its own, still hands its exception past that begin's rescue.
- A `synchronize` or `select!` block directly in the body of a begin that has rescue clauses and an ensure still passes those clauses: "An exception leaving an inner ensure reaches the rescue around it".
- A `return` or a `next` that leaves such a block through a begin inside an ensure region still leaves a frame armed.

Left alone: a begin that lacks either clause emits the C it did.

Cost (callgrind, gcc -O2): entering a begin with both clauses costs what it did (149,348,449 instructions for 1,000,000 entries, before and after). A raise that no clause matches now runs the ensure body and is raised again, 785 instructions more each (134,857,867 to 150,550,934 for 20,000). In a debug build, where each raise takes a backtrace of some 240,000 instructions, the first commit alone takes a second one and the second commit saves it (measured on an earlier master, 26d456ec1035: 4,776,103,885 before, 4,977,081,625 with the first commit, 4,791,801,625 with both).

Measured on master 9922a2c74, above "An exception handed from an inner ensure to the outer one stays alive" and "An ensure keeps the exception it holds while its body runs". The two tests of the first commit are right at -O0 to -O3, with clang and under both stress modes; master has 12 of the 30 lines of the one and 9 of the 10 of the other wrong at every level. `make backtrace-test` passes at both commits, with the second commit's file at the second. Of the 6,534 corpus programs the C of 21 changes with the first commit besides the two new tests, each in a begin that has both clauses, and they print their `.expected`; the second commit changes the C of none. The scale-test ratios are 4.73, 6.14 and 4.13, under their limits. `emit_rescue` goes from 338 lines to 347 and `emit_begin` from 346 to 355 over the two. `ruby tools/gate.rb check` with each commit staged answers 0.

The attack set was run on an earlier master, 8dc552254, with these two commits as they stood there. Of 400 attack programs (the inner region a begin with an ensure, two nested, one with a rescue that does not match beside its ensure, a `synchronize` block, a `select!` block; between it and the outer begin nothing, an `if`, a begin with an ensure, with a rescue that matches, with one that does not, two begins, a rescue modifier as a value and as a statement; in the outer begin's body, rescue clause, else clause and ensure body, the outer begin written out or a method body; its own rescue matching, not matching or absent) master is right on 151 and each of the two commits on 233; none is lost at either. Either half of the first commit alone loses four, the `synchronize` and `select!` blocks under a begin where no clause matches. Of the 167 left, 20 build on neither and 147 are wrong: 124 print master's bytes, and 23 differ from them where both are wrong: in 11 the inner begin's ensure body, which master skipped, now runs and the outer one still does not or its rescue is still passed; in 12 the outer ensure body runs twice under a rescue modifier, whose frame master does not count.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, two commits above the pull request beneath on master 9922a2c74: the build of each commit, the two tests in the seven builds, `ruby tools/gate.rb check` with each commit staged, the C of all corpus programs after each commit against the C beneath it, the 21 tests whose C changed and the two new ones built and run, `make backtrace-test`, `make scale-test` and `make int-min-test` at each commit, optcarrot's C by hash, and the 34 cost programs under callgrind.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: the pull request "An ensure keeps the exception it holds while its body runs"
