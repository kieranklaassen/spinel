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
- Now: it does not build (`variable or field '_snr4' declared void`); without the `say` line it prints `"1 [1, 2]"`.
- CRuby: `hi`, then `"0 [1, 2]"`.

Since that change, where the value of a `&.` call on a typed receiver hoists a statement (an argument that is built, or that runs), the guard is an `if` ahead of the statement with the call inside it, assigned to a temp. A call with no C value (a method that ends in `puts`, a hand-written `v=`) gets a `void` temp. And the call runs before what is written before it wherever the statement does not sequence its operands itself: an interpolation, a multiple assignment, a parenthesized operand.

Now the guard jumps over what the value hoisted and the value stays in the call's place, `(nil ? nil : call)`, with no temp. The hoisted statements still do not run under a nil receiver, which is what that change was for: the 21 `safe_nav_*` tests on master pass with gcc and clang, plain and under stress. A jump and not a block, because the value names what the hoisted statements declare.

A jump may not pass a declaration that has a cleanup (clang refuses it, and gcc would run the cleanup on a flag nothing set), and a root is one. So `sn_roots_to_pushes` (`src/codegen.c`) reads the roots back out of the hoisted text, the way the frame pass reads them: each becomes a bare push, popped by one count saved ahead of the guard. At a function's top scope `gc_frame_build` turns those pushes into frame entries and drops the count, so the function is the one from before that change plus the guard's two lines. `gc_roots_take_back` no longer stops at this one forward jump.

Cost, instructions under callgrind for 200,000 calls of a method with rooted locals and `r = @o&.note([i, i])`: 134,551,146 before that change, 137,749,392 on master, 134,751,831 here (one a call over the first: the guard's test). Below the top scope the hoisted roots are a push each and one pop, where master has a push and a pop each.

Not here: a boxed receiver. `"#{$c} #{b&.bump([1, 2])}"`, with `b` a K or an Integer, prints `"1 [1, 2]"` before that change and now; that arm has always computed the call ahead of the statement.

Test: `test/safe_nav_call_stays_in_place.rb`, 25 lines; it does not build on master.

Generated C against master (`make cident REF=c534bbf9a`): 6350 identical, 13 differ, 0 refusal changes. The 13 are the new test and 12 tests that have such a call: six `safe_nav_*` tests, `proc_safe_nav_call`, `dispatch_block_param_arms`, `exception_circular_cause`, `nil_write_boxes_range_time_slot`, `setter_nullable_result` and `super_anon_block_bare_variants`. Each of the 12 prints what it prints on master, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`. optcarrot's generated C is byte-identical.

Two sets of small programs, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`, on c534bbf9a. 462 written for this change (a `&.` call on each kind of typed receiver, with each kind of argument, in each place a statement puts it, the receiver nil and not): 336 are right in all six on master, 386 here; the 50 more are the ones that were right before that change, and none loses a cell. 291 from the nil receiver work: 232 are right on master and the same 232 here, and no program's result differs.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
