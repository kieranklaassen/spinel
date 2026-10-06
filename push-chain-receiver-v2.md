<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A chained push written as a statement gave wrong answers when the C compiler evaluates a call's arguments right to left, as gcc does:

```ruby
h = { 1 => ["p"] }
h[1] << "v#{h[1].size}" << "w#{h[1].size}"
p h[1]          # ["p", "v1", "w2"] in Ruby; ["p", "v1", "w1"] on master built with gcc

q = [1, "a"]; i = 4
q << "a#{i}" << "b#{i}" << "c#{i}"     # master with gcc at SPINEL_GC_STRESS=2: "the mark reached a freed heap string"
```

The statement arms wrote the push as one C call, `sp_PolyArray_push(RECEIVER, VALUE)`, and for a chain the receiver is the chain of earlier pushes. C leaves the order of the two open. gcc builds the value first, so a value that reads what an earlier link changed reads it too early, and nothing holds it while the earlier links push. The value form of the same chain already ran its receiver first.

`emit_push_recv_temp` (`src/codegen_stmt.c`) now serves the three statement arms. A receiver that can allocate is evaluated first, as Ruby does, into a temp the pushes go through. A receiver that is a pure read (`a << x`, `@a << x`, `rows[i] << x`) compiles as before.

One decision: the temp is rooted only when a value can run code. Rooting every such temp was tried and cost 10 instructions a push through a reader.

`test/array_push_chain_value_root.rb` counts the wrong chains of Strings made in place and prints four chains whose values read what the earlier links did. On master (dafa0d047) built with gcc it is wrong in a plain run and aborts at level 2; built with clang, which evaluates left to right, master is already right. It is not added to `GC_STRESS_TESTS`: the plain run fails without the fix.

Not in this change: a value whose own operands master moves ahead of the whole statement still runs before the receiver chain. `mk << lg(1) << [lg(2)]` logs `[2, :r, 1]` where Ruby logs `[:r, 1, 2]`, with both compilers, as on master. The move happens where the value is emitted, not in the push.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (two start-up statements change: 2,375,661,925 before, 2,375,804,328 after, +0.006%, checksum 59662 both times, on dafa0d047)
- [ ] Depends on: # (nothing)
