<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def fetch
  tries = 0
  begin
    raise IOError, "again" if tries < 2
    tries
  rescue IOError
    tries += 1
    begin
      retry if tries < 3
    rescue ArgumentError
      0
    end
    1
  end
end

200.times { fetch }
puts "done"
```

stops with `stack level too deep (SystemStackError)`, exit 1. After, as CRuby: `done`.

A `retry` is a `goto` back to the label before its begin. It popped the rescue clause's own entry and nothing else. A begin written in the clause around the retry had armed a setjmp frame; the goto left it on the handler stack, one more at every retry, and the stack holds 64.

The label now keeps the frame depth it stands at (`g_retry_exc_base`), and a retry pops the frames above it (`emit_retry_unwind`), as a `next` does for its loop. Both begin emitters set and restore it with the label; both forms of retry, statement and value, call it.

Left alone: a retry with no frame between it and its clause is the `goto` it was. The C of all 6,418 corpus programs is identical; only the new test's differs. Cost: one subtraction from `sp_exc_top` at a retry that leaves a frame, none anywhere else.

Not here, each the same on master:

- A retry with a begin/ensure between it and its clause (`begin; retry if again; ensure; log << :e; end` in the clause) is still the bare `goto`: that ensure has to run first and does not, and its frame stays. The retry is emitted as it was wherever an ensure stands between.
- A retry inside a rescue modifier's expression in the clause (`(retry if again) rescue nil`) leaves the modifier's frame: that frame is not counted yet. "A return, next or break out of a rescue modifier's expression pops its frame" counts it; with both fixes in, the retry pops it.
- A retry in a modifier's fallback (`work rescue retry`, in a clause) restarts the enclosing begin, where CRuby restarts the modifier's expression.
- `redo` is a bare `goto` too: out of a begin in a block or a while body it leaves that frame (200 calls end in a SystemStackError), and past a begin/ensure it skips the ensure.

The test calls six methods 200 times each: a retry in a begin of the clause, in two begins, in value position, under an outer ensure, before a raise that the inner begin rescues, and in a begin inside a while of the clause. It then reads `$!` and rescues one more exception.

Measured on master 9274c732e. The test is right at -O0 to -O3, with clang and under both stress modes; master prints 4 of its 10 lines wrong at every level and exits 1 (`stack level too deep`). Of 588 attack programs (a retry, as a statement and in value position, under 14 things that can stand between it and its clause; in a begin that is plain, has an ensure, has an else or is in value position, and in a method-level rescue; in a method, a while, a block, under an outer ensure and inside another rescue clause; each called 200 times, then a raise nothing rescues) master is right on 210 and this on 378; none is lost. The 210 left print master's bytes: 168 are a retry inside a rescue modifier and 42 a begin/ensure between, the first two items above. Above "A return, next or break out of a rescue modifier's expression pops its frame" the same set is right on 546, with none lost and those 42 left. `make backtrace-test` passes. The scale-test ratios are master's (1.71, 4.74, 6.13, 4.17). `emit_begin` goes from 323 lines to 325 and `emit_expr_node` from 843 to 844; `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
