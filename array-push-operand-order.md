<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Ruby runs a call's receiver, then its arguments left to right, each once. An Array push whose value is not used did not:

```ruby
def t(n) = (puts n; n)
a = []
a << t(1) << t(2)             # printed 2 then 1

nxt = -> { i += 1; toks[i - 1] }
out << nxt.call << nxt.call   # ["b", "a"]
```

A statement push never reaches `emit_call`, so `emit_operands_in_order` is never asked about it: `emit_stmt_inner` hands it to `emit_array_mutate_stmt`, whose push arms write one C call per argument with the receiver and the value as sibling arguments, which gcc evaluates right to left. The same shape is a lifetime hole: `live << C.new(i) << C.new(-i)` builds the second object first and holds it nowhere while the first push allocates, so a loop summing such chains gives another total under `SPINEL_GC_SLAB=0 SPINEL_GC_STRESS=1`.

`emit_array_mutate_stmt` now declines such a push and the statement is written as the value form with its value dropped, which already binds its operands in order. The new `push_stmt_takes_value_form` decides (an argument may store into the variable the receiver reads, several arguments follow a receiver that runs code, or two of the operands run code and are not all plain reads). Every other push keeps its single call.

One push needed more than that to stay as it was. In `@buffer << @mixer.sample`, `read_rebound_by` takes the call on another object to run any code, so the receiver would be read first and rooted across the call: 13 instructions a push under callgrind (65,409,103 to 84,531,113 on a loop of that shape), and it is the shape of optcarrot's APU. But no code can hand that read another Array when nothing but a constructor assigns the ivar, so `ivar_set_only_by_ctor` asks: no write of it in another method, in a block or a lambda, no writer, no `instance_variable_set` or `remove_instance_variable` in the program, and no `initialize` called, sent or aliased by name. Then the push keeps its single call, and that loop's C is the same byte for byte as master's. The answer is kept per ivar name.

The emitted C of 5,507 of the 5,535 programs in `test/*.rb` and `benchmark/*.rb` on 01d9d2f0 is byte-identical before and after. The 28 that change are tests, each with such a push; no benchmark changes. They print their `.expected` plain, under `SPINEL_GC_STRESS=1` and under `SPINEL_GC_SLAB=0 SPINEL_GC_STRESS=1`. No function over 1,000 lines is touched; `emit_array_mutate_stmt_body`, `emit_stmt_inner` and `emit_call_body` are as they were.

Three tests. `test/array_push_stmt_operand_order.rb` has the order and lifetime cases and each way an ivar is reassigned behind a call on another object (the owner's method, a lambda held in an ivar, a module's method, a writer, `instance_eval`, the argument itself), beside one that only a constructor assigns. `test/array_push_stmt_ivar_set_by_name.rb` and `test/array_push_stmt_ctor_aliased.rb` are programs of their own because either turns the single call off for a whole program. Each rule of the new check, removed in turn, fails one of the three.

Found with the operand order probe (#PROBE_PR), which lists this as its largest family.

Still on the old path, left for their own changes: `<<` and `push` on a boxed value whose receiver is a call, statement `[]=` and `concat` on Integer and mixed Arrays, and an argument whose code is hoisted ahead of the whole statement (an Array or Hash literal holding a call, a parenthesised sequence).

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
  OPTCARROT_LINE
- [ ] Depends on: #
