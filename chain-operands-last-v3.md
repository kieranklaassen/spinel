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

The compiler's time doubles with every link of such a chain: `spinel -c` takes 0.2 s at 12 links, 3.4 s at 16 and 56 s at 20, so a chain of 30 would take hours. It is any chain on an object whose methods are written in Ruby and whose arguments are calls, with `.` or with `&.`. The program it compiles is right.

Now 20 links compile in 0.03 s, 40 in 0.09 s and 200 in 2.6 s.

`emit_operands_in_order` renders two or more observable operands, emits the call with them bound, and declines when the call did not take them so; the caller then renders the whole call again. A method written in Ruby binds its arguments in order already and declines every time, and as the receiver of the next link it is emitted twice, so each link doubled the work below it. A lone operand had the same fault and was cured by rendering it after the call (`operands_last`). A call that has declined two or more is now remembered by node (`g_bind_declined`, a byte a node) and takes that path from then on. One line of `emit_operands_in_order`, in `src/codegen_call.c`.

What was not chosen: rendering the operands last for every call, with nothing remembered. It gives the same programs, but it renumbers the temps in the C of programs across the corpus, where this renumbers one.

Test: `make scale-test` compiles the new `test/scale/call_chain_operands.rb`, forty links in seven shapes, under its 20 s CPU limit: about a second here, and master is killed at the limit. The file is only compiled, so it has no `.expected`.

Generated C against master (`make cident REF=06064727f`): 6332 identical, 1 differ, 0 refusal changes. The one is `test/typed_array_assoc_nil`: a call that had declined is emitted again where it takes its operands, and their temps are numbered after the bindings instead of before; it prints the same. `make cident` ends with status 1 for it, since it counts any differing byte. optcarrot's generated C is byte-identical.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the new file is only compiled)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
