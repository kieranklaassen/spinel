<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def build
  keep = []
  50000.times { |i| keep << "y" + i.to_s }
  RuntimeError.new("first")
end
x = build.exception("again")
p x.message
```

prints `"first"` in a plain run built with gcc, at -O0 to -O3. After, as CRuby: `"again"`.

This is a regression. The program printed `"again"` until the merged change "Exception#exception keeps an empty or frozen message as new does", which gave the message to `sp_exc_msg_given` in the same C call that evaluates the receiver.

```ruby
e = RuntimeError.new("first")
x = e.exception("one").exception("again")
p x.message
```

prints `"again"` in a plain run; under `SPINEL_GC_STRESS=2` it prints fifteen 0xDB bytes built with gcc and aborts with "the mark reached a freed slot" built with clang. After: `"again"` in both.

Cost (callgrind, instructions a copy, gcc and clang): a receiver that is a variable is the C it was. A receiver that may allocate pays for the rooted temp, 6 to 15 instructions a copy with gcc and clang, the more where the receiver builds its exception: 6 with both where a call hands an exception back (873 to 879 with gcc, 868 to 874 with clang), 13 and 15 where the call builds one or the receiver is `RuntimeError.new("first")` (1,546 to 1,559 and 1,552 to 1,567), 13 and 15 for a copy of a copy (1,514 to 1,527 and 1,504 to 1,519). The temp is taken wherever the receiver may allocate, also where the message turns out to need none (nil, an empty literal).

A frozen String given as a message, a literal's too, travels as a counted copy that `sp_exc_msg_given` allocates. `emit_exc_exception` wrote that call and the receiver as the two operands of one C call. C leaves the two unsequenced, and a literal counts as an operand that cannot allocate (`subtree_allocates`), so the operand rule that orders and roots two allocating operands did not apply. gcc ran the receiver after the copy was built, and a collection in the receiver swept the copy: in the first program its slot was taken by the next message allocated, the receiver's own. clang ran the receiver first, and the copy's allocation swept the receiver.

A receiver whose evaluation can allocate (`operand_may_allocate`) is now evaluated first, into a rooted temp, as `emit_str_eq_ordered` does for a String comparison. The message is built after it and goes straight into `sp_exc_exception`, which roots it.

Left alone: a receiver that is a variable, and one the operand rule already bound to a temp, are written as before. Of the corpus's 6,530 programs the C of one changes, test/systemcallerror_message_from_errno.rb, and it prints its `.expected` as before.

Not here, the same on master:

- A receiver that is a boxed value: `[build][0].exception("again")` dies at run time with "undefined method 'exception' for an instance of RuntimeError (NoMethodError)".

The test copies an exception answered by a method that allocates, with a literal, a frozen String that is no literal, a message with a NUL and an empty one; copies a copy; keeps 300 copies of a copy and counts their messages; copies an instance of a class of the program and reads its field; takes the receiver from a conditional, a block and a `begin`; and raises a copy and rescues it.

Measured on master 9922a2c74. The test is right at -O0 to -O3, with clang and under both stress modes; master has one line wrong at -O0 to -O3 built with gcc. `make backtrace-test` passes. The scale-test ratios are 4.73, 6.14 and 4.13, under their limits. `emit_exc_exception` goes from 27 lines to 41. `ruby tools/gate.rb check` with the change staged answers 0. Of 550 attack programs (the receiver in eleven shapes, the message in ten, the copy in five places; each built plain and, with a small churn, run under `SPINEL_GC_STRESS=2`), run on master 3d629868d, master is right on 300 and wrong under stress on 250; with the change all 550 are right, plain and under stress.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit on master 9922a2c74: the build, the test in the seven builds, `ruby tools/gate.rb check` with the change staged, the C of all 6,530 corpus programs and of optcarrot against master's, the two programs whose C is new or changed built and run, `make backtrace-test`, `make scale-test` and `make int-min-test`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none
