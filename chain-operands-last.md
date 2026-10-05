<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
def col(n) = "c" + n.to_s
class Q
  def initialize = @w = []
  def where(x) = (@w << x; self)
end
q = Q.new.where(col(1)).where(col(2)).where(col(3))   # ... and so on
```

Before: the compiler's time doubled with every link of such a chain. `spinel -c` took 0.15 s at 12 links, 1.5 s at 16 and 26 s at 20, so a chain of 30 would take hours. It is any chain on an object whose methods are written in Ruby and whose arguments are calls (`col(1)`, `id(1)`, `v.to_s`, `@k.to_s`, `:c1.to_s`), with `.` or with `&.`, on one line or split over lines. The program it compiled was right.

After: 20 links compile in 0.02 s, 40 in 0.05 s, 200 in 1.5 s. Past that the time grows with the square of the chain's length (0.6 s at 128 links, 2.4 s at 256, 10.9 s at 512), as a chain with literal arguments does on master.

| links | 8 | 12 | 16 | 20 | 40 | 100 | 200 |
|---|---|---|---|---|---|---|---|
| master, `.where(col(i))` | 0.01 s | 0.15 s | 1.53 s | 26.0 s | | | |
| this change | 0.01 s | 0.01 s | 0.02 s | 0.02 s | 0.05 s | 0.33 s | 1.54 s |
| master, `&.me(lg(i))` | 0.01 s | 0.19 s | 2.10 s | 31.2 s | | | |
| this change | 0.01 s | 0.01 s | 0.01 s | 0.02 s | 0.07 s | 0.37 s | 1.82 s |
| a literal argument, both | 0.01 s | 0.01 s | 0.01 s | 0.01 s | 0.04 s | 0.17 s | 0.67 s |

How: `emit_operands_in_order` renders two or more observable operands, emits the call with them bound, and declines when the call did not take them so; the caller then renders the whole call again, operands included. A method written in Ruby binds its arguments in order already and declines every time. As the receiver of the next link it is emitted twice, once to be bound and once in that call's arm, so each link doubled the work below it. #4925 was the same with a lone operand, cured by rendering it after the call (`operands_last`). A call that has declined two or more is now remembered by node (`g_bind_declined`, a byte a node) and takes that path from then on: it is emitted with its operands named, and they are rendered only if it takes them. One line of `emit_operands_in_order`, in `src/codegen_call.c`.

Generated C against master (`make cident REF=5c2dea515`): 6075 identical, 3 differ, 0 refusal changes. `benchmark/bm_tree_walker_frames` and `test/poly_getbyte_beside_native_getbyte` differ only in the numbers of their string literals (`_fzl_20` is now `_fzl_17`): the renderings master threw away had taken numbers. In `test/typed_array_assoc_nil` a call that had declined is emitted again where it takes its operands, and their temps are numbered after the bindings instead of before. The stripped binaries of all three are byte-identical to master's. optcarrot's generated C is byte-identical.

So the C can differ from master's in the numbers the compiler counts up (string literals, dispatch helpers, temps) and in functions nothing refers to, which a thrown-away rendering leaves behind on master and which are gone here. Over 3,251 small programs written to order operands: 3,158 byte-identical, 37 differ in literal numbers, 24 in temp numbers, 22 are shorter by such dead functions and none is longer, 4 are refused by both, 6 are chains master does not finish. The 89 that differ or that only this change compiles, run with gcc and clang at `SPINEL_GC_STRESS` 0, 1 and 2: every one prints what master prints, and the 6 chains print what Ruby prints.

`make scale-test` compiles the new `test/scale/call_chain_operands.rb`, forty links in seven shapes, under its 20 s CPU-time limit. With this change it takes under a second; without it the leg is killed at the limit.

Not taken: rendering the operands last for every call, with nothing remembered. It gives the same programs, but it renumbers the temps in the C of 523 corpus programs where this renumbers one.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no new test with an `.expected`; the scale file is only compiled)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
