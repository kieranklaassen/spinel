<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A chained push written as a statement gave wrong answers when the C compiler evaluates a call's arguments right to left, as gcc does:

```ruby
q = [1, "a"]; i = 4
q << "a#{i}" << "b#{i}" << "c#{i}"     # SPINEL_GC_STRESS=2: "the mark reached a freed heap string"

h = { 1 => ["p"] }
h[1] << "v#{h[1].size}" << "w#{h[1].size}"
p h[1]                                  # master with gcc: ["p", "v1", "w1"]; Ruby: ["p", "v1", "w2"]

bump << @n                              # bump adds 1 to @n and returns @a: master with gcc pushes the old @n
```

The statement arms wrote the push as one C call, `sp_PolyArray_push(RECEIVER, VALUE)`, and for a chain the receiver is the chain of earlier pushes. C leaves the order of the two open. gcc builds the value first, so nothing holds it while the earlier links push and grow the array, and a value that reads what an earlier link changed reads it too early. The value form of the same chain already ran its receiver first.

`emit_push_recv_temp` (`src/codegen_stmt.c`) now serves the three statement arms: a push onto an Array of anything, onto a typed Array, and onto a boxed receiver.

- A receiver that can allocate is evaluated first, as Ruby does, into a temp the pushes go through: `{ sp_PolyArray *_t3 = <chain>; SP_GC_ROOT(_t3); sp_PolyArray_push(_t3, <value>); }`.
- The temp is not rooted when every value is a number, a boolean, nil or a Symbol read from where it is kept: nothing can run between the receiver and its push.
- A receiver that is a pure read (`a << x`, `@a << x`, `obj.items << x`, `rows[i] << x`) stays where it was and compiles as before.

`test/array_push_chain_value_root.rb` builds 80,000 chains of Strings made in place and counts the wrong ones, then prints four lines of chains whose values read what the earlier links did. On master (ab9b925aa, Linux x86-64, gcc 13) a plain run prints `4` wrong chains and three of the four order lines wrong; level 1 is wrong too (1,862 chains) and level 2 aborts. With this change it prints Ruby's output with gcc and with clang, in a plain run and at levels 1 and 2. With clang, which evaluates left to right, master is already right, so the test fails on master only where the C compiler is gcc. It is not added to `GC_STRESS_TESTS`: the plain run fails without the fix.

Measured with both compilers built on ab9b925aa:

- 30 more programs (chains, receivers that run code, several values, splats, nested and boxed receivers), each built with gcc and with clang and run plain and at levels 1 and 2: none is right on master and wrong with this change, and none that stopped on master goes on to a wrong answer. With gcc, master is wrong on 10 of them in a plain run and on 10 at level 2, where this change is right; with clang the two trees answer alike. Three abort at level 2 on both trees (the first line under "Not in this change").
- Generated C: 101 of the 5,797 programs in `test/*.rb` and 22 of the 156 package tests (ffi 13, fiddle 8, net 1) change, none of the 64 in `benchmark/`. All 123 print the same bytes before and after in a plain run and at levels 1 and 2. All pass in a plain run; at level 2 the same nine fail before and after (`hash_iterator_boxed_callable`, which fails at level 1 too, `issue_3227_matrix`, six ffi tests and `fiddle_closure`).
- callgrind, a million pushes each: `items << i` through a reader 16,709,055 before and after; `q << i << i + 1` 25,750,391 and 24,750,389; `h[k] << i` 681,774,487 before and after. A first version rooted every such temp and cost 10 instructions a push through a reader; that is why the temp is rooted only when a value can run code.
- optcarrot: two lines of its C change, the two pushes that build the name and attribute tables at start-up (98,304 pushes in all). 2,376,393,817 instructions before, 2,376,561,024 after (+0.0070%), checksum 59662 both times.

Not in this change:

- Several fresh values pushed onto a boxed receiver in one call (`g.last.push("d#{i}", "e#{i}")`) still abort at level 2, before and after: the values sit unrooted beside each other.
- Master's order for a receiver that is a pure read is kept as it is, so `rows[i] << (i += 1)` still reads `i` after the value with gcc.
- A value whose own operands master moves ahead of the whole statement still runs before the receiver chain, on master and with this change, with both compilers. `mk << lg(1) << [lg(2)]` logs `[2, :r, 1]` where Ruby logs `[:r, 1, 2]`, and `h[1] << (z = lg(1)) << lg(z + 1)` pushes 1 and 1 where Ruby pushes 1 and 2; an Array literal, a Hash literal, a block call or a conditional as the value do the same. This is the largest family the title could be read to cover and does not: the move happens where the value is emitted, not in the push.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it is `0` and four Arrays)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (two start-up lines change: 2,376,393,817 before, 2,376,561,024 after, checksum 59662 both times, on ab9b925aa)
- [ ] Depends on: # (nothing)
