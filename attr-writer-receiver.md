<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

An attribute writer on a receiver that only the statement holds stored its value into another object:

```ruby
class K
  attr_accessor :v
  def initialize(v) = @v = v
end
bad = 0
20_000.times do |r|
  K.new("v").v = (made = Array.new(8) { |i| K.new("k#{i}") }; r)
  bad += 1 unless made.all? { |k| k.v.is_a?(String) }
end
p bad    # 0 in Ruby; 1 on master in a plain run, 5467 with SPINEL_GC_STRESS=1
```

The writer takes its receiver into a C temp and builds the value after it:

```c
{ __typeof__((sp_K_new(...))) _wb1 = (sp_K_new(...)); _wb1->iv_v = VALUE; sp_gc_wb((void *)_wb1); }
```

Nothing holds `_wb1` while `VALUE` allocates. The receiver is collected, one of the objects the value makes takes its slot, and the store lands in that object. `SPINEL_GC_STRESS=2` does not show it: a freed slot is not handed out again there, so the stray store changes nothing a program reads.

The receiver's temp is now rooted (`writer_recv_wants_root`, `src/codegen_stmt.c`) at the four places that take the receiver first: the typed statement, the statement on a class with subclasses, the statement on a boxed receiver, and the writer read for its value (`y = (K.new(1).v = x)`, `src/codegen_call_class.c`):

```c
{ sp_K *_t3 = sp_K_new(...); SP_GC_ROOT(_t3); { __typeof__(_t3) _wb1 = _t3; _wb1->iv_v = VALUE; sp_gc_wb((void *)_wb1); } }
```

It is rooted only where the value can allocate (`operand_may_allocate`) and nothing else holds the receiver for the statement: an object made in place, a call's result (`mk(i).v = ...`, `pool.pop.v = ...`), or a local or an instance variable the value itself rebinds (`o.v = (o = nil; ...)`, `read_rebound_by`). A receiver that is a plain read keeps the C it had: `self`, a constant, a local or an instance variable the value does not rebind, a field read off one (`subtree_is_pure_read`). So does a receiver that a statement around this one already ran into a temp of its own (`arg_ran_first`), and any receiver when the value makes nothing (`K.new(i).v = i + 1`).

`test/attr_writer_receiver_held.rb` goes 5,000 times through nine forms with eight objects made by the value, and counts the rounds where one of the eight no longer holds its own String: a receiver made in place; the same read for its value; a boxed receiver taken out of an Array; a local and an instance variable the value sets to nil; a slot that holds a String; a class one object of which is frozen; a Struct member; and a receiver a local holds, which compiles as before. On master (ebb73f701, Linux x86-64; c6bbdfbc9 the same) it prints `[2, 0, 0, 0, 0, 0, 1, 0, 0]` in a plain run and `[4920, 55, 5000, 5000, 5000, 5000, 4999, 4983, 0]` at level 1, with gcc and with clang. With this change it prints nine zeros at plain, level 1, level 1 with `SPINEL_GC_VERIFY=1` and level 2 with both compilers, and under `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1 SPINEL_GC_STRESS=1`. It is wrong on master in a plain run, so it is an ordinary test and not one of `GC_STRESS_TESTS`.

Measured with both compilers built on ebb73f701, each program with gcc and clang at plain, level 1, level 1 with verify and level 2:

- 393 programs: 293 written for this change (a statement, the writer's value, `&.` and a multiple assignment over seventeen kinds of receiver: made in place, a method's result, popped from an Array, an element, a Hash value, a conditional, a subclass, a frozen class, a Struct, a held local, a held field, and a local, a field and an instance variable the value clears; and six kinds of value) and 100 kept from two readings of the `&.` writer. No program right on master under a setting is wrong there with this change. 74 that fail on master, in a plain run or at level 1, are right under all eight. 230 are right before and after. 89 fail the same way before and after, for other causes: 81 raise NoMethodError for the writer on a boxed receiver given a value that is not its slot's first type, six end in SIGSEGV through `&.` (five on a nil receiver, one on a local the value sets to nil), and two are other faults. In 19 of the 81 master aborted at level 2, and that level now raises as the plain run does.
- Generated C: 8 of the 5,826 programs in `test/*.rb` change (`array_op_assign_reads_slot_first`, `attr_op_write_value`, `attr_or_write_slot_kinds`, `attr_or_write_unset_slot`, `dlx_subclass_ring_attr`, `poly_writer_builtin_default`, `puts_in_case_value_arm`, `subclass_ring_dispatch`), each by such a root; all eight are right at the four settings with both compilers before and after. The 64 programs in `benchmark/`, the 156 package tests and optcarrot are byte-identical.
- Cost (callgrind, 200,000 rounds). The C is master's, and so is the count, where the value makes nothing (`K.new(i).v = i + 1`, 12,002,134) and where a local holds the receiver (`k.v = [i]`, 62,972,010; `o&.v = [i]`, 312,525,616). The root costs 7 instructions a call on a typed receiver (`K.new(i).v = [i]`, 79,276,382 to 80,676,382), 16 where the writer's value is read, 6 on a boxed receiver and 2 on a class with subclasses.

The question whether the value can allocate is `operand_may_allocate`'s, as for a call's sibling arguments, and it takes any call for one that can: `@r.flag = !@r.flag` and `right.left = left` through a reader that dispatches on the class gain a root they do not need (the eight tests above; between 7 and 86 instructions over a whole test run).

Not in this change:

- A receiver read through a field whose holder the value clears, `h.o.v = (h.o = nil; ...)`: the field read is a plain read and stays unrooted. The ten programs I wrote for it are right on master and with this change.
- The targets of a multiple assignment, `a, K.new(1).v = x, y`: right on master in the programs above.
- A writer on a boxed receiver that raises NoMethodError for a value that is not its slot's first type (`pick(i).v = [1]` where the subclasses' `@v` holds an Integer): the same before and after.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it is one line, an Array of nine zeros)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on ebb73f701)
- [ ] Depends on: # (nothing)
