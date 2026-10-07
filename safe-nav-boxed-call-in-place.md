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

Where the value of a `&.` call on a boxed receiver (a value read out of a container, here) hoists a statement (an argument that is built, or that runs), the guard is an `if` ahead of the whole statement, with the call inside it, assigned to a temp. So the call runs before what is written before it wherever the statement does not sequence its operands itself: an interpolation, a multiple assignment, an array literal. It is not left by this week's guard changes: 06064727f prints the same.

Now the guard jumps over what the value hoisted and the value stays in the call's place, `(nil ? nil : call)`, with no temp. That is what the typed arm does since "A `&.` call whose value hoists builds, and runs in its place", which this depends on. The hoisted statements still do not run under a nil receiver.

Two commits. The first moves the typed arm's jump (the saved root count, the jump, its label) into `sn_guard_over_hoists` and changes no generated C (`make cident REF=59f96842f`: 6370 identical, 0 differ). The second calls it from the boxed arm: +9 −23 in `emit_call_safe_nav_arms`.

Cost, instructions under callgrind for 200,000 calls each of a method with rooted locals and `r = @o&.note([i, i])`, on a boxed `@o` that is an object and on one that is nil: 339,150,807 on master, 334,949,577 here.

Not here:

- The arguments of a builtin method still run under a nil receiver (`s&.rjust(lg(5), lg("b"))` logs both). That is the next change, on top of this one.
- `a&.values_at(0, [1].size)` on a boxed Array does not build, on master or here.

Test: `test/safe_nav_boxed_call_stays_in_place.rb`, 18 lines; 7 of them are wrong on master.

Generated C against the first commit (`make cident REF=dbdeb6b30`): 6356 identical, 15 differ, 0 refusal changes. The 15 are the new test and 14 tests that have such a call: six `safe_nav_*` tests, `proc_safe_nav_call`, `block_arg_poly_symbol`, `boxed_struct_deconstruct_keys`, `builtins_partition_group_by`, `poly_dispatch_args_forwarded_block_proc_form`, `poly_recv_arg_iterators`, `poly_recv_find_chunk` and `poly_recv_while_family`. Each of the 14 prints what it prints on master, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`. optcarrot's generated C is byte-identical.

Three sets of small programs, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`, against master a39414338 with the change this depends on. 462 with a `&.` call on a boxed receiver (each kind of argument, in each place a statement puts it, the receiver nil and not): 380 are right in all six there, 396 here. 462 with the same calls on a typed receiver: 386 and the same 386. 291 from the nil receiver work: 232 and the same 232. No program loses a cell in any of the three.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (the pull request of "A `&.` call whose value hoists builds, and runs in its place")
