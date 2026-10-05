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

Before: the compiler's time doubled with every link of such a chain. `spinel -c` took 0.11 s at 12 links, 1.7 s at 16 and 25 s at 20, so a chain of 30 would take hours. It is any chain on an object whose methods are written in Ruby and whose arguments are calls (`col(1)`, `id(1)`, `v.to_s`, `@k.to_s`, `:c1.to_s`), with `.` or with `&.`, on one line or split over lines. The program it compiled was right.

After: 20 links compile in 0.02 s, 40 in 0.06 s, 200 in 1.6 s. Past 100 links the time grows four to six times for each doubling: 0.44 s at 128, 2.6 s at 256, 10.3 s at 512, 56 s at 1,024, and 93 s there with `&.`. A chain with literal arguments grows about four times for each doubling, on master and here (about 1 s at 256, 4 to 5 s at 512, 17 to 18 s at 1,024).

| links | 8 | 12 | 16 | 20 | 40 | 100 | 200 |
|---|---|---|---|---|---|---|---|
| master, `.where(col(i))` | 0.02 s | 0.11 s | 1.67 s | 25.1 s | | | |
| this change | 0.01 s | 0.01 s | 0.02 s | 0.02 s | 0.06 s | 0.27 s | 1.60 s |
| master, `&.me(lg(i))` | 0.02 s | 0.13 s | 1.61 s | 29.9 s | | | |
| this change | 0.01 s | 0.01 s | 0.02 s | 0.02 s | 0.07 s | 0.43 s | 1.92 s |
| master, a literal argument | 0.01 s | 0.01 s | 0.01 s | 0.01 s | 0.04 s | 0.18 s | 0.62 s |
| this change | 0.01 s | 0.01 s | 0.01 s | 0.02 s | 0.04 s | 0.20 s | 0.68 s |

The times are user and system CPU seconds of one `spinel -c`, on master fa08b100d.

How: `emit_operands_in_order` renders two or more observable operands, emits the call with them bound, and declines when the call did not take them so; the caller then renders the whole call again, operands included. A method written in Ruby binds its arguments in order already and declines every time. As the receiver of the next link it is emitted twice, once to be bound and once in that call's arm, so each link doubled the work below it. #4925 was the same with a lone operand, cured by rendering it after the call (`operands_last`). A call that has declined two or more is now remembered by node (`g_bind_declined`, a byte a node) and takes that path from then on: it is emitted with its operands named, and they are rendered only if it takes them. One line of `emit_operands_in_order`, in `src/codegen_call.c`.

Generated C against master (`make cident REF=fa08b100d`): 6109 identical, 1 differ, 0 refusal changes. The one is `test/typed_array_assoc_nil`: a call that had declined is emitted again where it takes its operands, and their temps are numbered after the bindings instead of before (`_t13` is now `_t12`). `make cident` ends with status 1 for it, since it counts any differing byte. Built from the two C files against one runtime and linked with `-Wl,--build-id=none`, its stripped binary is byte-identical to master's, with gcc and with clang. optcarrot's generated C is byte-identical.

So the C can differ from master's in the numbers the compiler counts up (dispatch helpers, temps) and in functions nothing refers to, which a thrown-away rendering leaves behind on master and which are gone here. Of 3,251 programs written for the argument-order work, compiled by both: 3,196 have identical C, 24 differ in temp numbers only, 22 in such unreferenced functions only, 4 are refused by both alike, and 5 are chains master does not finish compiling. The 46 that differ were built with gcc and with clang and run at `SPINEL_GC_STRESS` 0, 1 and 2: each prints under this change what it prints on master in every cell (38 print CRuby's output, 8 the same wrong lines, faults of their own). The 5 chains print CRuby's output in every cell.

One thing a chain that now compiles can show. A `&.` call on a nil receiver runs its arguments on master, where CRuby runs none: `mk(false)&.two(lg(1), lg(101))` logs both. Forty links of that did not finish compiling; they compile now and log all eighty. Master logs the same way at 1, 2 and 8 links, where this change's C is master's byte for byte. The pull request "A `&.` call on a nil receiver runs none of its arguments" is the cure for that fault; this one does not need it and does not touch it.

`make scale-test` compiles the new `test/scale/call_chain_operands.rb`, forty links in seven shapes, under its 20 s CPU-time limit. With this change it takes under a second; without it the leg is killed at the limit. The file is only compiled, so there is no `.expected`.

Not taken: rendering the operands last for every call, with nothing remembered. It gives the same programs, but it renumbered the temps in the C of 523 corpus programs (measured on master 5c2dea515) where this renumbers one.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
