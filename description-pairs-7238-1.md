# PR 7238: description changes for the added commit 59aabda7

Internal hand-off. This thread cannot read the live description. Every Old
below is copied from `pr-body.md` beside this file (the text the PR was opened
from), and each occurs once there; the Mac matches each against the live text
and says if one differs. The gate block and the checklist are NOT in these
pairs: the gate pair comes after the Mac's gate on 59aabda7 merged with
master, and the checklist is at the end as a request, because the Mac wrote
those lines from its own runs.

The title stays as it is.

## Pair 1: the ownership sentence

Old:

```
a `next` in a `while` or in an iterator's block inside the body is that loop's, and one in a proc or lambda written there is the proc's.
```

New:

```
a `next` in a `while` or in an iterator's block inside the body is that loop's, and one in a proc or lambda written there is the proc's. One in the receiver, an argument or the `&blk` of a call that has a block, or in the collection of a `for`, is evaluated in the body and is the body's (second commit, below).
```

## Pair 2: a paragraph for the second commit, before the test paragraph

Old:

```
`test/fiber_thread_enumerator_block_next.rb` has the `next` with a value, without one and with several;
```

New:

```
The second commit answers a review finding on #7256, which carries this change underneath: `subtree_owns_next` returned at a call with a block before it looked at the receiver and the arguments, and at a `for` before it looked at its collection, though both are evaluated in the body. So `Fiber.new { r = (next 7 if c; [1, 2]).each { |v| v }; r }.resume` and `Thread.new { [3, 4].inject((next 8 if c; 10)) { |s, v| s + v } }.value` still stopped at the C compiler, and `proc { Fiber.new { r = (next 5 if c; [1, 2]).map { |v| v + 1 }; r } }.call.resume` built and answered `nil`, as did the same `next` under an `ensure`. The one-node form of the walk now looks in the receiver, the arguments and a `&blk` of a call with a block, and in the collection of a `for`; the three answer 7, 8 and 5. The any-`next` form, which master's splice emitters ask (a yielded block, `tap`, `Array.new` with a block, `emit_fallback_block_value`), answers as before, so nothing outside a fiber, thread or generator body changes: the emitted C of the 5,474 programs in `test/`, the 64 in `benchmark/`, the 142 package tests and optcarrot is byte-identical for the first commit and the second. That form has the same gap and is left for its own change: `emit_fallback_block_value` leaves the leading statements out of a `delete` block that has a `next` (`h.delete(:z) { |k| puts "lead"; next 5 if c; 7 }` prints 7 and no "lead" on master), and with the walk changed for both forms `h.delete(:z) { |k| puts "lead"; (next 5 if c; [k]).each { |v| p v }; 7 }` goes from a C error to that wrong answer.

`test/fiber_thread_enumerator_block_next.rb` has the `next` with a value, without one and with several;
```

## Pair 3: the new test, after the first test's paragraph

Old:

```
It prints its `.expected` plain and under `SPINEL_GC_STRESS=1`, and fails to build on master.
```

New:

```
It prints its `.expected` plain and under `SPINEL_GC_STRESS=1`, and fails to build on master.

`test/fiber_block_next_in_call_operand.rb` (second commit) has the `next` in the receiver, in an argument and in the collection of a `for`, each in a fiber, a thread and a generator; in a `&blk`; in the receiver and an argument of a call given a `&blk`; and two calls deep; an iterator's block and a `for` inside the body that keep their own; a fiber in a proc and a proc in a fiber; and an `ensure` the `next` leaves, in a fiber and in a generator. It prints its `.expected` plain and under `SPINEL_GC_STRESS=1` and `2`, and fails to build on the first commit.
```

## Pair 4: the last sentence of "Still not built"

Old:

```
is taken as its value in any block, as before.
```

New:

```
is taken as its value in any block, as before, and so is one that is the whole of a parenthesised receiver, `((next 7 if c); [1, 2]).map { |v| v + 1 }`.
```

## The checklist, a request to the Mac (no Old known here)

- The `.expected` line: there are now two test files. The new one was written
  from ruby 3.3.6 with `--enable-frozen-string-literal`. Its 26 lines are: bare
  Integers; Arrays of Integers; two Arrays of Integers and Symbols
  (`[1, :after, 3, :after, :end]`, `[4, :outer]`); one nested Array
  (`[[10], 0, [30]]`); and two lines written by `puts` ("ensure", "generator
  ensure"). No bare Symbol, no nil, no Hash, no Float. If the
  live line says CRuby 4.0.7 was run on the first file, please run
  `ruby --enable-frozen-string-literal test/fiber_block_next_in_call_operand.rb`
  on 4.0.7, compare with the `.rb.expected`, and word the line for both files.
- The optcarrot line: optcarrot's C did not change with the second commit
  either (12,255 lines, byte-identical for cd3ddfe2 and 59aabda7, in the cloud).
- The gate block: after the Mac's `make gate` on 59aabda7 merged with master.
