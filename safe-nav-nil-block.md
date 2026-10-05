<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class Node
  def initialize(v) = @v = v
  def sum; t = @v; yield t; end
end
def find_node(k) = k ? Node.new(3) : nil
o = find_node(false)
p o&.sum { |i| i }                # nil in Ruby; SIGSEGV here
```

Before: a `&.` call with a block, on a nil receiver, to a method that yields ran the method anyway. Its arguments ran, its body ran and the block ran, and the call answered what the body answered where Ruby answers nil. A body that reads an instance variable read it through NULL, which is the SIGSEGV above.

After: nothing runs and the call answers nil.

How: a method that yields is spliced at its call, and the splice bound self to the receiver without looking at the operator. `emit_inline_call_x` now splices such a call under a nil test when the receiver is an object pointer: the receiver goes into a temp, the splice runs on it only when it is not NULL, and what the splice hoists stays under the test with it. The root the splice gives self is taken at the nil test instead, so a receiver nothing else holds, `K.new(v)&.add([K.new(1), K.new(2)]) { }`, is kept while the arguments are built, and no root is added. Files: `src/codegen_iter.c`, `src/codegen_internal.h`.

`test/safe_nav_nil_receiver_runs_no_block.rb` prints 70 lines. On master it prints three, two of them wrong, and ends in SIGSEGV; here it prints its `.expected` with gcc and with clang, and under `SPINEL_GC_STRESS=1` and `2`. `test/safe_nav_block_fresh_receiver_kept.rb` holds the fresh receiver: it prints `0 0 0 13333 0 0 0`.

Generated C against master (`make cident REF=origin/master`): CIDENT_LINE. Besides the two new tests one test differs, `yield_inherited_self_class`, whose `&.` call with a block gets the nil test, and it still prints its `.expected`. optcarrot's generated C is byte-identical.

Cost, callgrind on a non-nil receiver: a million `o&.add(i) { |x| x + 1 }` run the same 10,344,955 instructions as on master.

Left alone, wrong on master and unchanged:

- A yielding method added to Integer, called `i&.m { }` on a nil Integer, still runs its body.
- `o&.priv { }` on a nil receiver still raises for a private method.
- A receiver that reaches the call boxed, `a.pop&.m(x) { }` or `a.delete_at(0)&.m(x) { }`, goes through a dispatcher and not the splice; with an argument that hoists it answers as on master.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: #SAFE_NAV_PR (a `&.` call on a nil receiver runs none of its arguments; without it two arguments with effects are still ordered ahead of the call and run)
