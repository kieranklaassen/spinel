<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class K
  def say(s) = puts(s)
  def bump(a) = ($c += 1; a)
end
def find(c) = c ? K.new : nil
$c = 0
x = find(true)
x&.say("hi")
p "#{$c} #{x&.bump([1, 2])}"
```

- Before "A &. call's block emitters wait for its nil guard": `hi`, then `"0 [1, 2]"`.
- Now: it does not build (`variable or field '_snr5' declared void`); without the `say` line it prints `"1 [1, 2]"`.
- CRuby: `hi`, then `"0 [1, 2]"`.

Since that change, where the value of a `&.` call on a typed receiver hoists a statement (an argument that is built, or that runs), the guard is an `if` ahead of the statement with the call inside it, assigned to a temp. A call with no C value (a method that ends in `puts`, a hand-written `v=`) gets a `void` temp. And the call runs before what is written before it wherever the statement does not sequence its operands itself: an interpolation, a multiple assignment, a parenthesized operand.

Now the guard jumps over what the value hoisted and the value stays in the call's place, `(nil ? nil : call)`, with no temp. The hoisted statements still do not run under a nil receiver, which is what that change was for: the 20 `safe_nav_*` tests on master pass with gcc and clang, plain and under stress. A jump and not a block, because the value names what the hoisted statements declare.

Only where it is safe. What a later operand of the statement hoists runs ahead of the statement too, so before a call left in place: `"#{o&.bump([1])} #{o&.bump("a#{$c}")}"` is right on master because both calls run ahead, in order. So `sn_stays_in_place` walks up from the call to its statement, and the value stays in place only if everything evaluated after the call on the way is a literal or a plain read; a parent it does not know answers no. Where it answers no, the C is master's.

A jump may not pass a declaration that has a cleanup (clang refuses it, and gcc would run the cleanup on a flag nothing set), and a root is one. So `sn_roots_to_pushes` (`src/codegen.c`) reads the roots back out of the hoisted text, the way the frame pass reads them: each becomes a bare push, popped by one count saved ahead of the guard. At a function's top scope `gc_frame_build` turns those pushes into frame entries and drops the count, so the function is the one from before that change plus the guard's two lines. `gc_roots_take_back` no longer stops at this one forward jump.

Two commits. The first makes the parent map `lent_enclosing_closure` kept its own into `node_parent`, for the walk, and changes no generated C (`make cident REF=3cb8982d8`: 6391 identical, 0 differ). The second is the fix.

Cost, instructions under callgrind for 200,000 calls of a method with rooted locals and `r = @o&.note([i, i])`: 134,551,146 before that change, 137,754,263 on master, 134,756,702 here: the guard's test, one or two instructions a call over the first. Below the top scope the hoisted roots are a push each and one pop, where master has a push and a pop each.

Not here:

- A boxed receiver. `"#{$c} #{b&.bump([1, 2])}"`, with `b` a K or an Integer, prints `"1 [1, 2]"` before that change and now; that arm has always computed the call ahead of the statement.
- A later operand that hoists. `"#{$c} #{o&.bump([1])} #{o&.bump("a#{$c}")}"` is `"0 [1] a1"` in CRuby, `"2 [1] a1"` on master and `"1 [1] a1"` here: the first call keeps its temp, ahead of the statement.
- A call in an argument, `&.` or not. `"#{$c} #{o&.bump(o2&.bump([3]))}"` is `"0 [3]"` in CRuby, `"2 [3]"` on master and `"1 [3]"` here, which is what `o.bump(o2.bump([3]))` prints on master: an argument that is a call runs ahead of the statement.

Test: `test/safe_nav_call_stays_in_place.rb`, 27 lines; it does not build on master.

Generated C against the first commit (`make cident`, both commits on 3cb8982d8): 6380 identical, 12 differ, 0 refusal changes. The 12 are the new test and 11 tests that have such a call: four `safe_nav_*` tests, `proc_safe_nav_call`, `dispatch_block_param_arms`, `exception_circular_cause`, `nil_write_boxes_range_time_slot`, `setter_nullable_result` and `super_anon_block_bare_variants`. Each of the 11 prints what it prints on master, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`. optcarrot's generated C is byte-identical.

Three sets of small programs, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`, on 3cb8982d8. 462 written for this change (a `&.` call on each kind of typed receiver, with each kind of argument, in each place a statement puts it, the receiver nil and not): 336 are right in all six on master, 361 here, and none loses a cell. 1,280 with the guarded call first and a later operand of each kind, in each container: 1,116 have master's C; of the 164 that differ, 150 are right in all six on master and 162 here, none loses a cell, and the two left are the second point under "Not here". 291 from the nil receiver work: 232 are right on master and the same 232 here, and no program's result differs.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
