<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def first_number(words)
  words.each do |w|
    return Integer(w) if w =~ /\A\d+\z/
  end rescue nil
  0
end

p first_number(["a", "42", "b"])
p Integer("oops")
```

prints

```
42
*** stack smashing detected ***: terminated
```

and aborts, at every optimization level. After, as CRuby, the uncaught error is reported:

```
42
invalid value for Integer(): "oops" (ArgumentError)
```

Called 65 times, `first_number` alone stops the program on master with `stack level too deep (SystemStackError)`.

`expr rescue fallback` arms a setjmp frame around `expr`, but the frame was never counted in `g_exc_frame_depth`, the number a `return`, `next` or `break` reads to pop the frames it leaves. Such an exit left the modifier's frame on the stack, its `jmp_buf` in a function that had returned, and the next uncaught raise jumped into it.

An ensure inside the expression read the same count. Under an outer ensure it took itself for that region's direct child and handed its exception straight on, past the modifier that rescues it:

```ruby
def number(text, log)
  begin
    n = (begin
      Integer(text)
    ensure
      log << "inner"
    end rescue -1)
    n + 1
  ensure
    log << "outer"
  end
end

log = []
p number("x", log)
p log
```

master: `invalid value for Integer(): "x" (ArgumentError)`, exit 1. After, as CRuby: `0` and `["inner", "outer"]`.

Both forms of the modifier, statement and value, now count their frame while the expression is emitted. The fallback is emitted with the frame gone, as it was. Every exit then pops the frame by the arithmetic it already had.

A block's `break` is the one exit that asks whether any frame stands between it and its wrapper: with none it is a `goto`, with any it is a throw. A modifier's frame was never seen there, so a break past one has always been a `goto`, and a right one, because the wrapper's landing restores `sp_exc_top`. It stays that `goto`: `g_exc_modifier_frames` records which frames are a modifier's, and the break asks whether anything else stands above its wrapper. Counted like a begin's frame, a break out of a modifier written in a rescue clause, right on master, would go by the throw and leave the clause's exception handled.

Left alone: a modifier with no `return`, `next`, `break` or ensure inside its expression. The C of 6,391 corpus programs is identical; one existing test's C changes (`test/thread_stop_wakeup.rb`: a return path through a `synchronize` inside a modifier now pops the frame) and it prints its `.expected`.

Cost: none at run time. An exit that leaves a modifier subtracts one more from `sp_exc_top` in the statement it already ran. optcarrot's C is unchanged.

Not here, each the same on master:

- An exit written in the FALLBACK (`v = (Integer(s) rescue (return 0 if quiet; -1))`) leaves the rescued exception handled; 70 calls end in `rescue nesting too deep`. The fallback is not registered as a rescue body.
- A `throw` out of a modifier that stands in a rescue clause leaves the clause's exception handled, as a throw out of the clause itself does.
- `retry` written inside a begin, or a modifier, nested in its rescue clause leaves that frame on the stack (200 retries end in a SystemStackError).

Measured on master 5a752fceb; d02a49fb7 merges clean and touches none of these functions. The test is right at -O0 to -O3, with clang, with `--debug` and under both stress modes; on master 6 of its 26 lines are wrong at -O0, and at -O1 to -O3 it aborts (a segfault with clang) with none of its lines out. Of 1,170 generated programs (12 ways to write the modifier: statement and value, parenthesized and `begin`/`end`, as an argument, as a condition, nested, inside a begin, an ensure region, an ensure body, a rescue clause, and in the fallback; 23 expressions: plain, raising, `return`, `next`, `break`, `throw`, loops and blocks with their own `next` and `break`, a begin, an ensure or another modifier that returns; 9 surroundings: the method body, `while`, `until`, `loop`, and `each`, `times`, `map`, `each_with_index`, `upto` blocks; each called 3 times, then 200 times, then followed by an uncaught raise), master is wrong for 552. Here 1,113 are right and none that master had right is lost; the 57 left print what master prints: 48 with the exit in the fallback and 9 throws out of a clause, the first two points above. `make backtrace-test` passes; the scale-test ratios are master's (1.71, 4.74, 6.10, 4.18); `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
