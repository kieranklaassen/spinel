<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Depends on "A next in a String iterator, each_index or Array.new ends its own turn". Those iterators run their block as a C loop of their own without recording the frame depth at its entry, so a `next` in one of them, inside a modifier's expression, would pop the modifier's frame now that it is counted: without that fix this test ends in an uncaught ArgumentError at `(text.each_line { |l| next if l.strip.empty?; n += 1 }; Integer("z")) rescue n += 100`, which is right on master.

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

A block's `break` is the one exit that asks whether any frame stands between it and its wrapper: with none it is a `goto`, with any it is a throw. A modifier's frame was never seen there, so a break past one has always been a `goto`, and a right one, because the wrapper's landing restores `sp_exc_top`. It stays that `goto`: `g_exc_modifier_frames` records which frames are a modifier's, and the break asks whether anything else stands above its wrapper. Counted like a begin's frame, a break out of a modifier written in a rescue clause, right on master, would go by the throw and leave the clause's exception handled. The record is 64 frames wide, as the runtime's handler stack is unless a build raises `SP_EXC_STACK_MAX`; a modifier under 64 frames or more is emitted as it was, byte for byte.

Left alone: a modifier with no `return`, `next`, `break` or ensure inside its expression. The C of 6,412 corpus programs is identical to the C above the fix this depends on; one existing test's C changes (`test/thread_stop_wakeup.rb`: a return path through a `synchronize` inside a modifier now pops the frame) and it prints its `.expected`.

Cost: none at run time. An exit that leaves a modifier subtracts one more from `sp_exc_top` in the statement it already ran. optcarrot's C is unchanged.

Not here, each the same on master:

- An exit written in the FALLBACK (`v = (Integer(s) rescue (return 0 if quiet; -1))`) leaves the rescued exception handled; 70 calls end in `rescue nesting too deep`. The fallback is not registered as a rescue body.
- A `throw` out of a modifier that stands in a rescue clause leaves the clause's exception handled, as a throw out of the clause itself does.
- `retry` and `redo` are bare gotos: written inside a begin, or a modifier's expression, they leave that frame on the stack (64 of them end in a SystemStackError). "A retry out of a begin nested in its rescue clause pops that frame" takes the retry; with both fixes in, it pops a modifier's frame as well.

Measured on master e527d205d, above the fix this depends on; this and that fix merge cleanly into 9274c732e. The test is right at -O0 to -O3, with clang, under both stress modes and with `--debug`. Above the fix this depends on alone it prints 6 of its 44 lines wrong at -O0 and aborts at -O1 to -O3 (`stack smashing detected`; a segmentation fault with clang).

Two sets of attack programs put each exit under each way a modifier is written, call the subject 200 times and end on a raise nothing rescues. In the first (1,170: twelve ways to write the modifier; a return, next, break or throw, direct or inside an inner loop, block, begin, ensure or modifier; in a method, a while, an until and the blocks of each, times, loop, map, each_with_index and upto) master and the fix this depends on are right on 618 and this on 1,113. In the second (1,220: the same inside the iterators that fix changes, each_line with and without `chomp: true`, each_char, each_byte, each_codepoint, each_grapheme_cluster, each_index, `Array.new` with a block) master is right on 677, that fix on 693 and this on 1,165. None is lost in either. The 112 left print the bytes they print above that fix: 95 are an exit written in the fallback and 17 a throw out of a modifier in a rescue clause, both named above. A third set (83) puts the modifier under 0 to 65 frames and inside a lambda, a proc, `define_method` and a Fiber: master is right on 36 and this on 69, none lost; the C of the 14 left is identical to the C above that fix, a modifier under 64 and 65 frames (12) and `redo` (2).

`make backtrace-test` passes. The scale-test ratios are those above that fix (1.71, 4.74, 6.13, 4.17). `emit_proc_literal_here`, over 1,000 lines, keeps its 1,293; `emit_stmt_inner` goes from 709 to 713 and `emit_and_or_begin_expr` from 338 to 342. `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: "A next in a String iterator, each_index or Array.new ends its own turn"
