<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A frozen object was changed and nothing said so. Stated cost: in a program that freezes an object of a class, `s.n += 1` on any object of that class now runs the plain writer's frozen check, 4 instructions a write with gcc 13 and clang 18. A program that freezes no object of the class keeps its generated C.

```ruby
class S
  attr_accessor :n, :m
  def initialize(n) = @n = n
  def memo = (@m ||= 7)
end
s = S.new(0)
s.freeze
begin; s.n += 1; puts "no raise"; rescue => e; puts e.class; end
begin; s.m ||= 5; puts "no raise"; rescue => e; puts e.class; end
begin; s.memo; puts "no raise"; rescue => e; puts e.class; end
p s.n, s.m
```

```
spinel diff: output-diff
  program: witness.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,5 +1,5 @@
-FrozenError
-FrozenError
-FrozenError
-0
-nil
+no raise
+no raise
+no raise
+1
+5
```

That is master (8dc552254), in the default build and under `--share-strings`. `s.n = 1` on the same object raises on master, as in CRuby.

The plain writer checks its receiver; so do `@n += 1` and an operator-assign whose value is used, which is rewritten to the writer. Four stores did not:

- the statement `s.n op= v`, which writes the slot through its bound receiver;
- the same statement on a receiver whose class is known only at run time (`def bump(o) = o.n += 1`), which stores in one arm for each class;
- the conditional store every attribute `||=` / `&&=` on a typed slot goes through (`emit_slot_orw_value`), and the one a String slot that holds a shared handle has of its own;
- the statement `@x ||= v` in the object's own method.

Each now emits the writer's guard (`emit_frozen_obj_guard`) on the object that owns the slot, inside the arm that stores. `s.n ||= 5` where `n` is set stores nothing and raises nothing, as in CRuby.

Of 180 forms (an `attr_accessor` class, a Struct and a keyword Struct; `+=`, `-=`, `*=`, `<<=`, `|=`, `||=`, `&&=`, a String's and a Float's `+=`, and `=` beside them; at top level, in a method given the object, in the object's own method, with the value used, in a block, and on an object that is not frozen): on master 114 change the frozen object silently and 66 are right; here all 180 are right, in the default build and under `--share-strings`.

**Cost**, callgrind instructions for 200,000 turns, master then this:

| program | gcc 13 | clang 18 |
|---|---|---|
| `s.n += 1; s.m \|\|= i`, another object of the class frozen | 4,272,111 → 5,072,109 (+4.0 a turn) | 3,630,581 → 4,430,580 (+4.0) |
| the same, nothing frozen | 4,271,990, the same C | 3,630,504, the same C |
| `def memo = (@m \|\|= 7)` read 200,000 times | 1,864,584 → 1,864,586 | 2,026,000 → 2,225,975 (+1.0) |
| `s = S.new; s.m \|\|= i`, storing each turn | 21,877,496 → 21,877,523 | 20,072,152 → 20,272,068 (+1.0) |
| `bump(o)` with `o.n += 1`, objects of two classes, one class frozen somewhere | 8,576,025 → 8,976,030 (+2.0) | 7,934,513 → 8,334,513 (+2.0) |

For scale, the guard of master's own `s.n = i` costs 4 instructions a write with gcc (664,620 → 1,464,623 between the program that freezes nothing and the one that does) and 7 with clang (627,914 → 2,026,039).

**Not here**, each as on master:

```ruby
s.n += bump          # frozen: raises without calling `bump`; CRuby calls it first.
s.m ||= bump         # The plain writer `s.n = bump` has the same order on master.
s.instance_eval { @n ||= 5 }   # frozen: raises nothing
def memo(o) = o.m ||= 5        # a receiver of two possible classes: refused
```

`tools/cident.sh 8dc552254`: 6443 identical, 5 differ: the new test and the four programs that print the revision.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
