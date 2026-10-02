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

`emit_array_mutate_stmt` now declines such a push and the statement is written as the value form with its value dropped, which already binds its operands in order. The new `push_stmt_takes_value_form` decides (an argument may store into the variable the receiver reads, several arguments follow a receiver that runs code, or two of the operands run code and are not all plain reads). Every other push keeps its single call: the emitted C of 5,496 of the 5,526 programs in `test/*.rb` and `benchmark/*.rb` is byte-identical before and after, and each of the 30 that change (27 tests, 3 benchmarks) has such a push. Those tests print their `.expected` plain, under `SPINEL_GC_STRESS=1` and under `SPINEL_GC_SLAB=0 SPINEL_GC_STRESS=1`; the benchmarks cost 808,169 to 808,579 instructions under callgrind for `bm_micro_lisp`, 901,072 to 901,163 for `bm_jekyll_lite` and 690,817 to 691,083 for `bm_sinatra_mini` (at most 0.05%). No function over 1,000 lines is touched; `emit_array_mutate_stmt_body`, `emit_stmt_inner` and `emit_call_body` are as they were.

Found with the operand order probe (#PROBE_PR), which lists this as its largest family.

Still on the old path, left for their own changes: `<<` and `push` on a boxed value whose receiver is a call, statement `[]=` and `concat` on Integer and mixed Arrays, and an argument whose code is hoisted ahead of the whole statement (an Array or Hash literal holding a call, a parenthesised sequence).

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
