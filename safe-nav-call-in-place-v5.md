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

Since that change, where the value of a `&.` call on a typed receiver hoists a statement (an argument that is built, or that runs), the guard is an `if` ahead of the statement with the call inside it, assigned to a temp. A call with no C value (a method that ends in `puts`; `x&.send(:v=, 1)` for a hand-written `v=`) gets a `void` temp. And the call runs before what is written before it wherever the statement does not sequence its operands itself: an interpolation, a multiple assignment.

Now the guard jumps over what the value hoisted and the value stays in the call's place, `(nil ? nil : call)`, with no temp. The hoisted statements still do not run under a nil receiver, which is what that change was for: the 20 `safe_nav_*` tests on master pass with gcc and clang, plain and under stress. A jump and not a block, because the value names what the hoisted statements declare.

Only where it is safe. What a later operand of the statement hoists runs ahead of the statement too, so before a call left in place: `"#{o&.bump([1])} #{o&.bump("a#{$c}")}"` is right on master because both calls run ahead, in order. So `sn_stays_in_place` walks up from the call to its statement, and the value stays in place only if everything evaluated after the call on the way is a literal or a plain read; a parent it does not know answers no. Where it answers no, the C is master's.

A jump may not pass a declaration that has a cleanup (clang refuses it, and gcc would run the cleanup on a flag nothing set), and a root is one. So `sn_roots_to_pushes` (`src/codegen.c`) reads the roots back out of the hoisted text, the way the frame pass reads them: each becomes a bare push, popped by one count saved ahead of the guard. At a function's top scope `gc_frame_build` turns those pushes into frame entries and drops the count, so the function is the one from before that change plus the guard's two lines. `gc_roots_take_back` no longer stops at this one forward jump.

Two commits. The first makes the parent map `lent_enclosing_closure` kept its own into `node_parent`, for the walk, and changes no generated C (`make cident REF=759d120fd`: 6429 identical, 0 differ, 0 refusal changes). The second is the fix.

Cost, instructions under callgrind for 200,000 calls of a method with rooted locals and `r = @o&.note([i, i])`: 137,754,308 on master and 134,755,574 here with gcc, 141,631,305 and 137,834,806 with clang. Below the top scope the hoisted roots are a push each and one pop, where master has a push and a pop each.

Not here:

- A boxed receiver. `"#{$c} #{b&.bump([1, 2])}"`, with `b` a K or an Integer, prints `"1 [1, 2]"` on master and here; that arm has always computed the call ahead of the statement.
- A later operand that hoists. `"#{$c} #{o&.bump([1])} #{o&.bump("a#{$c}")}"` is `"0 [1] a1"` in CRuby, `"2 [1] a1"` on master and `"1 [1] a1"` here: the first call keeps its temp, ahead of the statement.
- A call in an argument, `&.` or not. `"#{$c} #{o&.bump(o2&.bump([3]))}"` is `"0 [3]"` in CRuby, `"2 [3]"` on master and `"1 [3]"` here, which is what `o.bump(o2.bump([3]))` prints on master: an argument that is a call runs ahead of the statement. With an outer method that has no C value the line did not build and now prints that same answer: `"#{$c} #{o&.say(o2&.bump("g#{$c}"))}|"`, for a `say` that ends in `puts`, is `"0 |"` in CRuby, no build on master and `"1 |"` here, as `o.say(o2.bump("g#{$c}"))` is on master.
- A chain. `"#{$c} #{o&.me([1])&.bump([2])}"`, for a `me` that adds one to `$c` and answers `self`, is `"0 [2]"` in CRuby, `"2 [2]"` on master and `"1 [2]"` here, as `o.me([1]).bump([2])` is on master: the last link stays in its place; the links before it are its receiver and run ahead.
- A call with no C value under a further `&.`: `log&.info(t + "5")&.to_s` as a statement, for an `info` that ends in `puts`, did not build; it builds now and does not run `info`. `p log&.info(t + "6")&.to_s` builds on master and does not run `info` either: the emitter of the further link drops a call with no C value.
- A receiver that is a call, after another part: `"#{side}#{mk&.info(t + "y")}"`, for an `info` with no C value, did not build and now runs `mk` before `side`, as `"#{side}#{mk.info(t + "y")}"` does on master.
- A call with no C value where the value does not stay in its place: `x, y = o&.say("a#{$c}"), o&.say("b#{$c}")` still does not build, with master's message. The same as a Hash literal's value, under `&&` and `||`, in a ternary, as a `case` subject and before a later operand that hoists.
- Parentheses around a written value or around a receiver: `r = ("#{$c} #{o&.bump([1, 2])}")` prints `"1 [1, 2]"` on master and here, with the same C. A desugar takes such parentheses off and leaves their node behind, still naming its child; `node_parent` answers the last node that names one, so the walk meets that dead node and answers no.

Test: `test/safe_nav_call_stays_in_place.rb`, 46 lines, 27 of output; it does not build on master. It is in `GC_STRESS_TESTS`: half the change is the roots.

Generated C against the first commit (`make cident`, both commits on 759d120fd): 6418 identical, 12 differ, 0 refusal changes. The 12 are the new test and 11 tests that have such a call: five `safe_nav_*` tests (`block_calls`, `poly_dispatch`, `specialized_miss`, `tap_then_nil`, `typed_receiver`), `proc_safe_nav_call`, `dispatch_block_param_arms`, `exception_circular_cause`, `nil_write_boxes_range_time_slot`, `setter_nullable_result` and `super_anon_block_bare_variants`. Each of the 11 prints what it prints on master, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`. optcarrot's generated C is byte-identical.

Three sets of small programs, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`, on 759d120fd. 462 written for this change (a `&.` call on each kind of typed receiver, with each kind of argument, in each place a statement puts it, the receiver nil and not): 332 have master's C; of the 130 that differ, 105 are right in all six on master and all 130 here. 1,280 with the guarded call first and a later operand of each kind, in each container: 1,116 have master's C; of the 164 that differ, 150 are right in all six on master and 162 here, and the two left are the second point under "Not here". 291 from the nil receiver work: 81 have master's C; of the 210 that differ, 181 are right in all six on master and the same 181 here, and the other 29 print what they print on master. No program loses a cell in any of the three.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
