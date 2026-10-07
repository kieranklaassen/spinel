<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class K
  def bump(a) = ($c += 1; a)
end
$c = 0
b = [K.new, nil, 5][ARGV.size]
p "#{$c} #{b&.bump([1, 2])}"
```

- Master: `"1 [1, 2]"`.
- CRuby: `"0 [1, 2]"`.

Where the value of a `&.` call on a boxed receiver (a value read out of a container, here) hoists a statement (an argument that is built, or that runs), the guard is an `if` ahead of the whole statement, with the call inside it, assigned to a temp. So the call runs before what is written before it wherever the statement does not sequence its operands itself: an interpolation, a multiple assignment. It is not left by this week's guard changes: 06064727f prints the same.

Now the guard jumps over what the value hoisted and the value stays in the call's place, `(nil ? nil : call)`, with no temp. That is what the typed arm does since "A `&.` call whose value hoists builds, and runs in its place", which this depends on, and it is done where that arm does it: where nothing the statement evaluates after the call hoists a statement of its own (`sn_stays_in_place`). Elsewhere the C is master's. The hoisted statements still do not run under a nil receiver.

Two commits. The first moves the typed arm's jump (the saved root count, the jump, its label) into `sn_guard_over_hoists` and changes no generated C (`make cident` against the change this depends on: 6430 identical, 0 differ, 0 refusal changes). The second calls it from the boxed arm.

Cost, instructions under callgrind for 200,000 calls each of a method with rooted locals and `r = @o&.note([i, i])`, on a boxed `@o` that is an object and on one that is nil: 339,101,127 on master and 334,899,916 here with gcc, 337,242,403 and 331,441,322 with clang.

Not here:

- A later operand that hoists: `"#{$c} #{b&.bump([1])} #{b&.bump("a#{$c}")}"` is `"0 [1] a1"` in CRuby and `"1 [1] a1"` on master and here, as in the change this depends on.
- A call in an argument of a call on a typed receiver, that change's line: `"#{$c} #{o&.bump(b&.bump([3]))}"` prints `"1 [3]"`. Where the outer receiver is boxed the line is right here: `"#{$c} #{b&.bump(o2&.bump([3]))}"` prints `"0 [3]"`, `"2 [3]"` on master.
- The arguments of a builtin method still run under a nil receiver (`s&.rjust(lg(5), lg("b"))` logs both). That is the next change, on top of this one.
- `a&.values_at(0, [1].size)` on a boxed Array does not build, on master or here.
- A `&.` call that appends, with a second `&.` on its answer: `s&.concat("x")&.size` leaves `s` without the append, on master and here, typed or boxed.

Test: `test/safe_nav_boxed_call_stays_in_place.rb`, 46 lines, 21 of output; 7 of the 21 are wrong on master.

Generated C against the first commit (`make cident`, the stack on 759d120fd): 6417 identical, 14 differ, 0 refusal changes. The 14 are the new test and 13 tests that have such a call: five `safe_nav_*` tests (`arg_iterators`, `block_calls`, `chunk_family`, `iter_stmt`, `tap_then_nil`), `proc_safe_nav_call`, `block_arg_poly_symbol`, `boxed_struct_deconstruct_keys`, `builtins_partition_group_by`, `poly_dispatch_args_forwarded_block_proc_form`, `poly_recv_arg_iterators`, `poly_recv_find_chunk` and `poly_recv_while_family`. Each of the 13 prints what it prints on master, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`. optcarrot's generated C is byte-identical.

Four sets of small programs, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`, on 759d120fd with the change this depends on. 462 with a `&.` call on a boxed receiver (each kind of argument, in each place a statement puts it, the receiver nil and not): 394 have that change's C; of the 68 that differ, 57 are right in all six there and 67 here. The one left is the last point under "Not here": it logs its argument twice there and once here, and leaves the String without the append on both. 462 with the same calls on a typed receiver: every one has that change's C. 291 from the nil receiver work: 290 have that change's C, and the one that differs is right in all six on both. 1,280 with the guarded call first and a later operand of each kind: 1,214 have that change's C; of the 66 that differ, 60 are right in all six there and 66 here. No program loses a cell in any of the four.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A `&.` call whose value hoists builds, and runs in its place": these two commits stand on its two)
