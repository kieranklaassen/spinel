<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`recv.v = value` on a receiver that nothing keeps while the value is built stored the value into another object:

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

The receiver's temp is now rooted (`writer_recv_wants_root`, `src/codegen_stmt.c`) at the four places that take the receiver of a plain write first: the typed statement, the statement on a class with subclasses, the statement on a boxed receiver, and the write read for its value (`y = (K.new(1).v = x)`, `src/codegen_call_class.c`):

```c
{ sp_K *_t3 = sp_K_new(...); SP_GC_ROOT(_t3); { __typeof__(_t3) _wb1 = _t3; _wb1->iv_v = VALUE; sp_gc_wb((void *)_wb1); } }
```

It is rooted only where the value can make something and can leave the receiver held by nothing else:

- a receiver nothing keeps: an object made in place, a call's result (`mk(i).v = ...`, `pool.pop.v = ...`);
- a local or an instance variable the value itself rebinds (`o.v = (o = nil; ...)`, `read_rebound_by`);
- any other receiver something keeps (`subtree_reads_held`: a global, a class variable, an Array's element, a Hash's value under a builtin key, a field read off one, `self.o`, a local behind a sequence) where the value can take it out of its holder: it rebinds a variable the receiver reads, or it can store into state at all, as any call that is not a plain read can. `@@o.v = (@@o = nil; ...)`, `self.o.v = (@o = nil; ...)`, `(0; o).v = (o = nil; ...)`, `a[0].v = (a.clear; ...)`, `$g.v = ($g = nil; ...)` and `h.o.v = (h.o = nil; ...)` take the root. `$g.v = [i]`, `a[i].v = [i]`, `h[:k].v = [i]`, `CK.o.v = [i]` and `$g.o.v = [i]` make an Array and run nothing: the holder keeps the receiver, and they compile to master's C.

`self` and a constant take no root. Neither does a receiver that a statement around this one already ran into a temp of its own (`arg_ran_first`), nor any receiver when the value makes nothing: an Integer, a Float or a boolean computed from plain reads (`K.new(i).v = i + 1`, `K.new(i).v = i * 0.5`) is a call to `operand_may_allocate` and allocates nothing.

Two tests, both wrong on master in a plain run, so they are ordinary tests and not in `GC_STRESS_TESTS`:

- `test/attr_writer_receiver_held.rb` goes 5,000 times through nine forms with eight objects made by the value, and counts the rounds where one of the eight no longer holds its own String: a receiver made in place; the same read for its value; a boxed receiver taken out of an Array; a local and an instance variable the value sets to nil; a slot that holds a String; a class one object of which is frozen; a Struct member; and a receiver a local holds, which compiles as before. On master (9c4eec71e, Linux x86-64) it prints `[2, 0, 0, 0, 0, 0, 1, 0, 0]` in a plain run and `[4920, 55, 5000, 5000, 5000, 5000, 4999, 4983, 0]` at level 1, with gcc and with clang.
- `test/attr_writer_holder_emptied.rb` does the same for four receivers whose holder the value empties before it allocates: a class variable, `self.o`, a local behind a sequence, and an Array's element. On master it prints `[2, 0, 0, 2]` in a plain run and `[1628, 931, 3021, 5000]` at level 1, with gcc and with clang.

With this change merged into 9c4eec71e both print zeros at plain, level 1, level 1 with `SPINEL_GC_VERIFY=1` and level 2 with both compilers, and under `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1 SPINEL_GC_STRESS=1`.

Measured with both compilers built on fa08b100d, each program with gcc and clang at plain, level 1, level 1 with verify and level 2:

- 393 programs: 293 written for this change (a statement, the write's value, `&.` and a multiple assignment over seventeen kinds of receiver: made in place, a method's result, popped from an Array, an element, a Hash value, a conditional, a subclass, a frozen class, a Struct, a held local, a held field, and a local, a field and an instance variable the value clears; and six kinds of value) and 100 kept from two readings of the `&.` writer. No program right on master under a setting is wrong there with this change. 74 that fail on master, in a plain run or at level 1, are right under all eight. 230 are right before and after. 89 fail the same way before and after, for other causes: 81 raise NoMethodError for the writer on a boxed receiver given a value that is not its slot's first type, six end in SIGSEGV through `&.` (five on a nil receiver, one on a local the value sets to nil), and two are other faults. In 19 of the 81 master aborted at level 2, and that level now raises as the plain run does.
- 162 programs for a receiver something keeps: seventeen holders (a global, a global's field, a constant's field, an element by a fixed and by a computed index, an Array under a second name, a mixed Array, a Hash's value under a Symbol, a String and an Integer key, a field of a field, a local behind a sequence, a conditional, a class variable, `self`'s field, an instance variable's field, a field a method of `self` clears), the write as a statement and read for its value, and four kinds of value: one that empties the holder and then makes eight objects, one that makes the eight and leaves the holder alone, an Array, an Integer. None right on master under a setting is wrong there with this change. 27 that fail on master are right under all eight, 134 are right before and after, and one fails the same way before and after (the last item under "Not in this change").
- Generated C: 7 of the 5,890 programs in `test/*.rb` change (`attr_op_write_value`, `attr_or_write_slot_kinds`, `attr_or_write_unset_slot`, `dlx_subclass_ring_attr`, `poly_writer_builtin_default`, `puts_in_case_value_arm`, `subclass_ring_dispatch`), each by such a root; all seven print their `.expected` at the four settings with both compilers before and after. The 64 programs in `benchmark/`, the 156 package tests and optcarrot are byte-identical.
- Cost (callgrind, gcc, 200,000 rounds of the line shown, a class `K` with `attr_accessor :v`):

| line | master | this change | a call |
| --- | --- | --- | --- |
| `K.new(i).v = [i]` | 79,276,348 | 80,676,334 | 7 |
| `K.new(i).v = [i]`, `K` with a subclass | 79,275,562 | 80,675,576 | 7 |
| `y = (K.new(i).v = [i])` | 79,651,745 | 82,051,746 | 12 |
| `pick(i).v = [i, i]`, `pick` answering one of two classes | 142,701,101 | 144,936,769 | 11 |
| `$g.v = mk(i)` | 62,970,300 | 65,582,053 | 13 |
| `a[i & 1].v = mk(i)` | 64,604,326 | 67,216,249 | 13 |

  The last two hold nothing in these programs (`def mk(i) = [i]` leaves `$g` and `a` alone), and the compiler does not look into `mk` to know it. These compile to master's C, and count the same to within 14 instructions over the run: `K.new(i).v = i + 1` (12,002,114), `K.new(i).v = i * 0.5` (19,679,339), `k.v = [i]` on a local (62,972,003), `o&.v = [i]` (62,971,989), `b.v = [i]` on a boxed local (65,236,465), `$g.v = [i]` (62,965,131), `a[i & 1].v = [i]` (64,998,984), `h[:k].v = [i]` (69,243,602), `CK.o.v = [i]` (64,845,368), `$g.o.v = [i]` (63,245,375).

A root that holds nothing is still asked for where the receiver is read through an instance variable and the value calls a reader: `@r.flag = !@r.flag`, `@game.score += n`, and `right.left = left` through a reader that dispatches on the class. A reader that dispatches is a call that could rebind the variable, as far as `read_rebound_by` can tell. Four of the seven tests above are such (`attr_op_write_value`, `puts_in_case_value_arm`, `dlx_subclass_ring_attr`, `subclass_ring_dispatch`); the other three root a receiver made in place or a call's result. Over a whole test run six of the seven take between 7 and 88 instructions more, and one 23 fewer.

Not in this change:

- An operator write on a receiver nothing keeps, `mkk(r).v ||= (...)` and `K.new("v").v += (...)`: those take the receiver first in code of their own and are not held. 5,000 rounds of the first leave 2 wrong objects in a plain run and 1,256 at level 1, with both compilers; the second leaves 3 and 1,323 built with clang, and built with gcc is right at plain and level 1 and ends in SIGSEGV at level 2. The same before and after. (`@game.score += n`, whose receiver is a plain read, is written as the plain write and is covered.)
- The targets of a multiple assignment, `a, K.new(1).v = x, y`: right on master in the programs above.
- A writer on a boxed receiver that raises NoMethodError for a value that is not its slot's first type (`pick(i).v = [1]` where the subclasses' `@v` holds an Integer): the same before and after.
- `hd.o.o.v = (hd.o = H.new(nil); ...)` as a statement: right in a plain run and at level 1, and aborts at level 2 with both compilers, before and after. The receiver is held now; the store `hd.o = ...` inside the value gets no write barrier, which is another cause.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (`attr_writer_receiver_held` compared equal under 4.0.7; `attr_writer_holder_emptied` was written from ruby 3.3.6 with that flag and is one line, an Array of four zeros)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on fa08b100d)
- [ ] Depends on: # (nothing)
