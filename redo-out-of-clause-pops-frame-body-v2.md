<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def read(items)
  n = 0
  items.each do |x|
    n += 1
    begin
      raise IOError, "again" if n == 1
    rescue IOError
      redo
    end
  end
  $!
end

p read([1, 2])
```

prints `#<IOError: again>`. After, as CRuby: `nil`. On master the 65th call of `read` stops the program with `rescue nesting too deep (> 64)`. With the redo in the begin's body instead (`begin; redo if n == 1; rescue IOError; end`) the 64th call ends in `stack level too deep (SystemStackError)`.

A `redo` is a `goto` back to the label at the top of its body. It popped nothing. A begin written around it had armed a setjmp frame, which stayed on the handler stack. A rescue clause around it had made its exception the one being handled, and it stayed that: `$!` after the loop, and one more entry at every redo.

The label now keeps what stands open where it is placed: frames, ensure regions, rescue clauses. A redo pops the frames above its label (`emit_redo_unwind`), as a `next` does for its loop, and the exceptions of the rescue clauses entered since the label. Those are counted from the label and not by frame depth: a loop written inside a rescue clause stands at that clause's own depth, and its redo leaves that clause's exception alone (the test's last method).

Two commits. The first is a refactor: the four places that open a redo label (a loop body, the block spliced at a yield, an iterator's step statements and its loop statements) each tested the stack for room, took a temp and stored the body and the label; `redo_label_push` does that once. Against master, the C of all 6,530 corpus programs is identical and no refusal changes. The second is the fix: three stores in that helper and the pops before the `goto`.

Left alone: a redo with nothing between it and its body is the `goto` it was. So is one under 32 open ensure regions: past them an ensure is not counted and could not be seen, and such a program stops as it did. Of the 6,530 corpus programs the C of 6,529 is identical; one existing test's C changes (`test/redo_block_keeps_writes.rb`: a redo in a begin's body now pops the frame it left behind on master) and it prints its `.expected`. Cost: one or two subtractions at a redo that leaves something, none anywhere else; optcarrot's C is unchanged.

Not here:

- A rescue modifier's frame is not counted on master, so a redo out of a modifier's expression leaves that frame as it did; with a modifier inside the begin the one pop takes the modifier's frame and the begin's stays, where master leaves both. "A return, next or break out of a rescue modifier's expression pops its frame" counts that frame, and above it such a redo leaves nothing.
- A redo with a begin/ensure between it and its body (`begin; redo if n == 1; ensure; done; end`) skips that ensure and leaves its frame, as on master. The ensure has to run before the jump, which is a change of its own; such a redo is the `goto` it was.
- A redo as a rescue modifier's fallback (`work rescue redo`) leaves the fallback's exception as the one being handled, as on master: its push is not counted. Inside a rescue clause the redo now pops one of the two, so `$!` after the loop is the clause's exception where master had the fallback's, and the program stops at the 64th such redo where it stopped at the 32nd.
- A redo written in an ensure clause while an exception is on its way drops that exception, as CRuby does, but the next raise takes it as its cause. Master stopped before it got there (`stack level too deep`); with `while true ... next ... break` in place of the redo it prints the same line:

  ```ruby
  items.each do |x|
    n += 1
    begin
      begin
        raise IOError, "again" if n % 3 == 1
      ensure
        redo if n % 3 == 1
      end
    rescue IOError
    end
  end
  begin
    raise ArgumentError, "after"
  rescue ArgumentError => e
    p e.cause
  end
  ```

  prints `#<IOError: again>` for CRuby's `nil`.
- The block of `sort` runs once for each comparison, and spinel's sort does not compare as often as CRuby's: a count kept in the block differs (59 for CRuby's 62 over 14 items), with a redo in it or with the `next` loop in its place. A program that redoes out of a begin in that block stopped on master after a few calls and now prints that count at every call.

The test calls eight methods 200 times each: a redo in a begin's body, in two begins, in a rescue clause, in a while, in a block given to a method that yields, in `map`, in `each_char`, and in a loop that stands inside another rescue clause. It then reads `$!` and rescues one more exception.

Measured on master 9922a2c74. The test is right at -O0 to -O3, with clang and under both stress modes; master prints 6 of its 12 lines wrong at every level and exits 1 (`stack level too deep`). Of 1,615 attack programs (a redo under 17 things that can stand between it and its body; in 19 kinds of loop: while, until, for, loop, a method that yields, each, times, each_with_index, each_with_object, upto, downto, step, map, each_char, each_line, each_byte, each_index, a Hash's each and a Range's each; in a method, in a begin's body, in a rescue clause, under an ensure and in a while; each called 203 times, then `$!` read, one more exception rescued and one left uncaught) master is right on 380 and this on 1,235; none is lost. The 380 left print master's bytes: 190 have a rescue modifier between and 190 an ensure, the first two items above. `make backtrace-test` passes. The scale-test ratios are master's (4.73, 6.14, 4.13). No function grows past its limit: `emit_stmt_inner` goes from 721 lines to 723, the four that open a label lose 6 to 8 lines each, and the two helpers are 8 and 7 lines; `ruby tools/gate.rb check` answers 0 with either commit staged.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, two commits on master 9922a2c74: the build of each commit, the test in the seven builds, `ruby tools/gate.rb check` with each commit staged, the C of all 6,530 corpus programs after each commit against the C beneath it, the changed test and the new one built and run, `make backtrace-test`, `make scale-test` and `make int-min-test` at each commit, optcarrot's C by hash, and the 1,615 attack programs on this head and on master.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none
