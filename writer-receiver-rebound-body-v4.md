<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** A writer statement whose value shows an assignment of the variable its receiver reads now holds that receiver in a temporary, and pays for it whether or not the assignment runs: `@held.n = swap(i)` goes from 45 instructions a store to 64 with gcc and from 54 to 62 with clang (callgrind, on 759d120fd with the pull request below beneath), and with a value that allocates from 215 to 230 and from 224 to 243. It applies to no other statement: a value with no assignment of that variable, in itself or in a method it calls, keeps its C whatever else it calls. The generated C of 1 of the 6,430 programs under `test/`, `benchmark/` and `packages/*/test/` differs, the new test; optcarrot's is byte-identical; eighteen programs that store through writers (a toggle, a ring of nodes, a global, a reader and a boxed receiver, values that allocate and that do not) compile to the C they had.

`recv.x = value` reads its receiver, runs the value, then stores into the receiver it read. As a statement whose receiver is a plain read (a local, an instance, class or global variable, a reader off one), it was emitted with the read in place, inside the store, so a value that rebinds the variable stored into the new object:

```ruby
class N
  attr_accessor :n
  def initialize(n) = @n = n
end
a = N.new(0); b = N.new(0)
c = a
c.n = (c = b; 1)
p [a.n, b.n]             # [1, 0]; master: [0, 1]
```

with gcc and with clang, in a plain run. The same for `@held.n = (@held = b; 2)`, a class variable, a global and `(0; c).n = (c = b; 5)`. Where the assignment is in a method the value calls, the store is one C assignment whose two sides the C compiler orders:

```ruby
def swap(b)
  @held = b
  6
end
def by_call(b)
  @held.n = swap(b)      # into the first object with gcc, into b with clang
end
```

Where the slot can hold a pointer, the write barrier's rewrite reads the receiver into a C temporary first, so the order is right, and nothing holds the temporary: a value that assigns the variable nil and then allocates leaves the receiver to be collected, and the store goes into whatever took its place. `o.v = (o = nil; made = mk8; r)` corrupts one of the eight objects just made in about 280 of 300 rounds at `SPINEL_GC_STRESS=1`, and in one of 1,800 such stores in a plain run.

A statement whose value assigns what its receiver reads now puts the receiver into the temporary the exact-class arm has for a receiver that is no plain read, rooted while a value that may allocate runs. The boxed receiver's arm reads its receiver first already, and roots it under the same test. "A boxed element store keeps a receiver its key or value rebinds" did this for `s[k] = v`.

The assignment counts where the value shows it (`subtree_shows_assign`): written in the value, or in a method the value calls, found by the method's name three calls deep (a method of that name in any class counts); for a reader receiver, an assignment of the instance variable it reads or a call of that attribute's writer; a local a proc assigns is `read_rebound_by`'s. Every other statement keeps its C. `read_rebound_by` alone says yes for an instance variable whenever the value calls on another object, and a hold on that word costs programs master runs right: `@r.f = !@r.f` went from 4 instructions a store to 17.

The search reads a method's body once a compile: what the method assigns and the methods it calls are kept (`assigns_collect`), and a statement's question is answered from that, three calls deep, so a value that calls into a wide graph of methods costs the compile the same. `spinel -c` on a class of K methods that each call all K, none assigning the variable, and S such statements (callgrind, instructions, on 759d120fd with the pull request below beneath):

| | before | after |
|---|---|---|
| K=20, S=200 | 630,183,595 | 631,677,909 |
| K=40, S=200 | 1,945,717,953 | 1,950,597,909 |
| K=80, S=200 | 7,178,478,407 | 7,197,869,046 |
| K=40, S=3,200 | 4,463,366,540 | 4,474,473,508 |
| K=40, S=200, each statement through an instance variable of its own | 2,120,556,238 | 2,130,848,837 |
| K=80, S=200, the same | 7,355,673,960 | 7,394,032,569 |

Compiling optcarrot takes 8,121,914,695 instructions before and 8,121,973,777 after.

80 generated statements (a local, an instance variable, a reader off self and off another object, a class variable and a global as the receiver; a value that assigns it in place, in a block, in a lambda, in a method one to four calls down, or through the attribute's writer; an Integer slot and a String slot): in a plain run master answers 19 otherwise than Ruby with gcc and 32 with clang. This change leaves 1 and 3, the three under the first point below, and none that was right is wrong.

**Not in this change**, each as on master:

- an assignment the value reaches another way: through a proc made outside the value, for an instance, class or global variable (`$g.n = la.call`, wrong with both compilers); in a method more than three calls down (wrong with clang); in the block a `yield` in the value runs (`@held.n = yield`, wrong with both); through `send` or `instance_variable_set`;
- a writer among the targets of a multiple assignment (`d.n, z = (d = b; 7), 2` stores into `b` with both compilers);
- the value form, `x = (c.n = (c = b; 1))`, which reads its receiver first already;
- a receiver nothing else holds where the writer is dispatched on the receiver's class, a call's result (`pool.pop.v = mk`) or an element of an Array the value empties (`a[0].v = (a.clear; mk)`): nothing roots it while the value allocates, and the store goes into an object already freed.

Test: `test/attr_writer_receiver_read_first.rb`. On master (759d120fd) its first five lines and its last differ from Ruby in a plain run with gcc and with clang, and the two through a method with clang.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after)
- [ ] Depends on: # (the pull request "An attribute writer statement holds its receiver while its value runs": this is one commit above it, and the receiver goes into the temporary that change declares)
