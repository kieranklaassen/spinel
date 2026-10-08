<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A frozen object was changed and nothing said so. Stated cost: where a program freezes an object of a class or asks one `frozen?`, `s.n += 1` on any object of that class now runs the frozen check the plain writer `s.n = v` already runs there, under the same class flag: 2 to 3 instructions a write with gcc 13 and clang 18, and 0 to 1 for an `||=`. A program that only asks `frozen?` and freezes nothing is right on master and pays it too: 200,000 turns of `s.n += 1` go from 2,068,879 to 2,468,879 instructions with gcc (+2.0 a write, +19.3%) and from 2,426,913 to 2,826,899 with clang (+2.0, +16.5%). A class whose objects the program neither freezes nor asks `frozen?` keeps its generated C.

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

That is master (5d762fb16), in the default build and under `--share-strings`. `s.n = 1` on the same object raises on master, as in CRuby.

The plain writer checks its receiver; so do `@n += 1` and an operator-assign whose value is used, which is rewritten to the writer. Four stores did not:

- the statement `s.n op= v`, which writes the slot through its bound receiver;
- the same statement on a receiver whose class is known only at run time (`def bump(o) = o.n += 1`), which stores in one arm for each class;
- the conditional store every attribute `||=` / `&&=` on a typed slot goes through (`emit_slot_orw_value`), and the one a String slot that holds a shared handle has of its own (`emit_strbuf_orw_guard`);
- the statement `@x ||= v` in the object's own method.

Each now has the writer's guard (`emit_frozen_obj_guard`) on the object that owns the slot, inside the arm that stores. `s.n ||= 5` where `n` is set stores nothing and raises nothing, as in CRuby.

The guard sits where CRuby calls the writer: after the right side and after the operator. A right side that raises, throws, exits or leaves its block with `next` does so, as it does on master. On a frozen `s`:

```ruby
s.n += loud(1)         # runs `loud`, then raises FrozenError
s.n += 1 / zero        # ZeroDivisionError, as on master
s.n /= zero            # ZeroDivisionError, as on master
t.n += (t.freeze; 1)   # FrozenError: the right side froze `t`
```

For `op=` the slot's value is read into a temporary beside the receiver, the arms compute into the temporary, and the guard and the store follow them. The first commit gives those arms one name for the slot and changes no generated C (`tools/cident.sh`: only the four programs that print the revision differ). For `||=` and `&&=` the stored value is `({ T _fvN = VALUE; <guard> _fvN; })`.

Of 180 forms (an `attr_accessor` class, a Struct and a keyword Struct; `+=`, `-=`, `*=`, `<<=`, `|=`, `||=`, `&&=`, a String's and a Float's `+=`, and `=` beside them; at top level, in a method given the object, in the object's own method, with the value used, in a block, and on an object that is not frozen): on master 114 change the frozen object silently and 66 are right; here all 180 are right, in the default build and under `--share-strings`. All 180 store. Of 24 forms beside them that store nothing (`||=` on a slot that is set and `&&=` on one that is nil; the same three kinds of object; at top level, with the value used, a String's slot, in a method given the object, in the object's own method, in a block), each raises nothing on the frozen object, on master and here, as in CRuby.

Of 240 forms more, whose right side prints, raises or freezes the receiver, or whose operator raises (the same three kinds of object; `+=`, `||=`, `&&=`, a String's and a Float's `+=`, `/=` by zero; at top level, in a method given the object, in the object's own method, with the value used, in a block): on master 132 change the frozen object silently, 78 are right and 30 are wrong; here the 132 are right and the 78 stay right, in both builds. The 30 are the `+=` and `/=` whose value is used, which is the plain writer's order and is as on master (below).

**Cost**, callgrind instructions for 200,000 turns, master then this:

| program | gcc 13 | clang 18 |
|---|---|---|
| `s.n += 1; s.m \|\|= i`, another object of the class frozen | 4,272,118 → 4,872,113 (+3.0 a turn) | 3,630,580 → 4,230,592 (+3.0) |
| the same, nothing frozen, one object asked `frozen?` | 4,269,910 → 4,869,893 (+3.0) | 3,630,383 → 4,230,380 (+3.0) |
| `s.n += 1` alone, nothing frozen, one object asked `frozen?` | 2,068,879 → 2,468,879 (+2.0) | 2,426,913 → 2,826,899 (+2.0) |
| `s.n += 1; s.m \|\|= i`, nothing frozen or asked | 4,271,989, the same C | 3,630,517, the same C |
| `s.n += g(i)`, `g` a method both compilers inline | 2,664,652 → 3,064,652 (+2.0) | 2,426,047 → 3,026,061 (+3.0) |
| `s.f += 0.5`, a Float | 1,071,321 → 1,471,308 (+2.0) | 870,039 → 1,070,037 (+1.0) |
| `def memo = (@m \|\|= 7)` read 200,000 times | 1,864,583 → 1,864,599 | 2,026,013 → 2,225,988 (+1.0) |
| `s = S.new; s.m \|\|= i`, storing each turn | 21,877,495 → 21,877,536 | 20,072,165 → 20,272,081 (+1.0) |
| `bump(o)` with `o.n += 1`, objects of two classes, one class frozen somewhere | 8,576,024 → 8,776,042 (+1.0 a call) | 7,934,526 → 8,134,526 (+1.0) |

The flag is the one `emit_frozen_obj_guard` reads for every writer (`freeze_observed`, set by `freeze` and by `frozen?`), so sparing the class that is only asked would mean splitting it for all of them. For scale, the guard of master's own `s.n = i` costs 4 instructions a write with gcc (664,633 → 1,464,636 between the program that freezes nothing and the one that does) and 7 with clang (627,941 → 2,026,066).

**Not here**, each as on master:

```ruby
s.n = loud(1)                  # frozen: the plain writer, `@n += loud(1)` and `x = (s.n += loud(1))`
                               # raise without calling `loud`; CRuby calls it first
x = (t.n += (t.freeze; 1))     # stores: the writer's check ran before the right side froze `t`
s.instance_eval { @n ||= 5 }   # frozen: raises nothing
def memo(o) = o.m ||= 5        # a receiver of two possible classes: refused
```

`tools/cident.sh 5d762fb16`: 6492 identical and 5 that differ, the new test and the four programs that print the revision; no program is refused that was not. `make share-strings-test` passes, and `make scale-test` gives master's ratios (1.95, 1.86, 1.71, 4.74, 6.14, 4.13).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
