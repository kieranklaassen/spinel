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

The label now keeps what stands open where it is placed: frames, ensure regions, rescue clauses. A redo pops the frames and the clauses above its label (`emit_redo_unwind`), as a `next` does for its loop. The clauses are counted by how many were entered since the label, not by frame depth: a loop written inside a rescue clause stands at that clause's own depth, and its redo leaves that clause's exception alone (the test's last method).

Two commits. The first is a refactor with no change in generated C: the four places that open a redo label (a loop body, the block spliced at a yield, an iterator's step statements and its loop statements) each tested the stack for room, took a temp and stored the body and the label; `redo_label_push` does that once. `make cident REF=9274c732e` on it: 6,418 identical, 0 differ, 0 refusal changes. The second is the fix: three stores in that helper and the pops before the `goto`.

Left alone: a redo with nothing between it and its body is the `goto` it was. The C of 6,417 corpus programs is identical; besides the new test, one existing test's C changes (`test/redo_block_keeps_writes.rb`: a redo in a begin's body now pops the frame it left behind on master) and it prints its `.expected`. Cost: one or two subtractions at a redo that leaves something, none anywhere else; optcarrot's C is unchanged.

Not here, each the same on master:

- A redo with a begin/ensure between it and its body (`begin; redo if n == 1; ensure; done; end`) skips that ensure and leaves its frame. The ensure has to run before the jump, which is a change of its own; such a redo is the `goto` it was.
- A redo inside a rescue modifier's expression (`(redo if n == 1; work) rescue 0`) leaves the modifier's frame, which master does not count. "A return, next or break out of a rescue modifier's expression pops its frame" counts it, and above that fix this one pops it: all 190 such programs of the attack set are right there.

The test calls eight methods 200 times each: a redo in a begin's body, in two begins, in a rescue clause, in a while, in a block given to a method that yields, in `map`, in `each_char`, and in a loop that stands inside another rescue clause. It then reads `$!` and rescues one more exception.

Measured on master 9274c732e. The test is right at -O0 to -O3, with clang and under both stress modes; master prints 6 of its 12 lines wrong at every level and exits 1 (`stack level too deep`). Of 1,615 attack programs (a redo under 17 things that can stand between it and its body; in 19 kinds of loop: while, until, for, loop, a method that yields, each, times, each_with_index, each_with_object, upto, downto, step, map, each_char, each_line, each_byte, each_index, a Hash's each and a Range's each; in a method, in a begin's body, in a rescue clause, under an ensure and in a while; each called 203 times, then `$!` read, one more exception rescued and one left uncaught) master is right on 380 and this on 1,235; none is lost. The 380 master has right are a redo with nothing around it, in an if, in a begin's else and after a finished begin. The 380 left print master's bytes: 190 have an ensure between and 190 a rescue modifier, the two items above. `make backtrace-test` passes. The scale-test ratios are master's (1.71, 4.74, 6.13, 4.17). No function grows past its limit: `emit_stmt_inner` goes from 709 lines to 711, the four that open a label lose 6 to 8 lines each, and the two new helpers are 8 and 7 lines; `ruby tools/gate.rb check` answers 0 with either commit staged.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
