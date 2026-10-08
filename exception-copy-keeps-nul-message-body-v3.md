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

Cost (callgrind, gcc -O2, 200,000 copies): a receiver that is a variable is the C it was (172,710,442 instructions, 14 more in the whole run). A receiver that is a call pays 6 instructions a copy for the rooted temp (174,910,441 to 176,121,664, 0.7%), and a copy of a copy 11 (303,816,109 to 306,042,740, 0.7%).

A frozen String given as a message, a literal's too, travels as a counted copy that `sp_exc_msg_given` allocates. `emit_exc_exception` wrote that call and the receiver as the two operands of one C call. C leaves the two unsequenced, and a literal counts as an operand that cannot allocate (`subtree_allocates`), so the operand rule that orders and roots two allocating operands did not apply. gcc ran the receiver after the copy was built, and a collection in the receiver swept the copy: in the first program its slot was taken by the next message allocated, the receiver's own. clang ran the receiver first, and the copy's allocation swept the receiver.

A receiver whose evaluation can allocate (`operand_may_allocate`) is now evaluated first, into a rooted temp, as `emit_str_eq_ordered` does for a String comparison. The message is built after it and goes straight into `sp_exc_exception`, which roots it.

Left alone: a receiver that is a variable, and one the operand rule already bound to a temp, are written as before. Of the corpus's 6,497 programs the C of 6,493 is identical. Four change, test/conditional_require_line.rb, test/require_expression_lines.rb, test/source_file_required.rb and test/systemcallerror_message_from_errno.rb, and print their `.expected` as before.

Not here, the same on master:

- A receiver that is a boxed value: `[build][0].exception("again")` dies at run time with "undefined method 'exception' for an instance of RuntimeError (NoMethodError)".

The test copies an exception answered by a method that allocates, with a literal, a frozen String that is no literal, a message with a NUL and an empty one; copies a copy; keeps 300 copies of a copy and counts their messages; copies an instance of a class of the program and reads its field; takes the receiver from a conditional, a block and a `begin`; and raises a copy and rescues it.

Measured on master 3d629868d. The test is right at -O0 to -O3, with clang and under both stress modes; master has one line wrong at -O0 to -O3 built with gcc. Of 550 attack programs (the receiver in eleven shapes, the message in ten, the copy in five places; each built plain and, with a small churn, run under `SPINEL_GC_STRESS=2`) master is right on 300 and wrong under stress on 250; here all 550 are right, plain and under stress. `make backtrace-test` passes. The scale-test ratios are master's (4.74, 6.14, 4.13). `emit_exc_exception` goes from 27 lines to 41. `ruby tools/gate.rb check` with the change staged answers 0. Merged into master 9c7ea3ce0 (tree 80b07485c984) it builds and the test is right in the same seven builds; that master alone has the line wrong at -O0 to -O3.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
