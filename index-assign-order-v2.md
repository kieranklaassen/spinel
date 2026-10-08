<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A statement `recv[key] = value` ran its value before its key, and before its receiver, wherever the C compiler chose to.

```ruby
a = [0, 0, 0, 0]
j = 0
a[j] = (j += 2)
p a
```

```
spinel diff: output-diff
  program: moved.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[2, 0, 0, 0]
+[0, 0, 2, 0]
```

```ruby
class Hold
  def initialize = @a = [1, 2, 3]
  def swap
    @old = @a
    @a = [7, 8, 9]
    60
  end
  def go
    @a[1] = swap
    p @old, @a
  end
end
Hold.new.go
```

```
spinel diff: output-diff
  program: swapped.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-[1, 60, 3]
-[7, 8, 9]
+[1, 2, 3]
+[7, 60, 9]
```

Both with gcc, which runs a C call's arguments from the right. Two more are wrong whatever the compiler:

```ruby
def t(n) = (puts "t#{n}"; n)
hh = {0 => [0]}
hh[t(1)] = [t(2)]
p hh.to_a
```

```
spinel diff: output-diff
  program: hoisted.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,3 @@
-t1
 t2
+t1
 [[0, [0]], [1, [2]]]
```

```ruby
def junk(n)
  w = "j"
  n.times { |i| w = w + i.to_s }
  w.size
end
h = { "k0" => 1 }
key = "k" + h.size.to_s
h[key] = (key = "z" + h.size.to_s; junk(40))
p h.to_a, key
```

With gcc this one stores under `"z1"`. With clang the key is read first, as in Ruby, and nothing holds it while the value builds: `SPINEL_GC_STRESS=2` aborts with "the mark reached a freed heap string".

A store whose value is not used never reaches `emit_call`: `emit_array_mutate_stmt` writes it as one C call, the receiver, the key and the value its sibling arguments. The Hash arm reads the three into temps in order, but only when the receiver or the key may allocate.

`index_set_stmt_order_shows` asks whether the order can show: the key or the value may give what the receiver reads another object, the value may give what the key reads another (`read_moved_by`), or two of the three run something. `emit_index_set_stmt_in_order` then runs the receiver and the key ahead of the statement into temps (`emit_args_before`), and the arm writes the call it always wrote, over those temps. The Hash arm takes its temps on the same question, roots a key the value can move its variable off, and runs what the value hoists after the receiver's and the key's temps where the value runs something.

Every other store keeps its single call and its C. Operands that store nothing and run no code of the program's (`subtree_stores_nothing`) cannot show their order however many of them run, and `read_moved_by` is `read_rebound_by` less what that takes for a rebinding and is none: a builtin over plain values, an ivar only a constructor assigns.

Measured with gcc and clang at `SPINEL_GC_STRESS` 0 to 2 over 560 programs: one store each, into an Array of Integers, Floats, Strings or anything and a Hash of each of three kinds; the receiver a local, an ivar, a global or a call; the index a literal, a variable, a call that prints, an assignment, or a call that replaces the receiver's variable; the value plain, a call that prints, one that assigns the index's variable, one that replaces the receiver's, or one built with a block. 210 of them keep master's C and are right on both trees. 350 change it: 217 that are wrong on master with gcc, 12 of them aborting at stress 2, and 49 that are wrong with clang are right; the other 133 are right on both, a receiver in an ivar or a global the class assigns elsewhere beside a call, or two operands that run something whose order did not happen to show. None that is right on master is wrong, refused or unbuildable.

Cost: `tools/cident.sh` against master: 6,499 identical, 6 differ: the new test, four tests (`boxed_reopen_self_call_block`, `index_write_widens_global_param_array`, `narrowed_element_local_pin`, `struct_custom_initialize_super`), each passing with gcc and clang at stress 0 to 2 as on master, and `benchmark/bm_stark_field.rb`, where two stores of a constructor, `@t[k][j] = Field.add(@t[k][j], 1)` and its `sub`, read their row ahead of the call: 1,110,032,583 to 1,110,129,683 instructions under callgrind. A Levenshtein loop's `m[i][j] = [m[i - 1][j] + 1, m[i][j - 1] + 1, m[i - 1][j - 1] + cost].min` keeps its C; with the row and the index read first it ran 340,104,552 to 408,996,280. optcarrot's C is the same; it compiles in 8,350,466,939 instructions for 8,349,046,980, the question asked of each of its statement stores.

Not here, the same on master:

- a store with a start and a length or a Range (`a[t(1), t(2)] = [t(9)]`), whose value is built first;
- a store into a boxed value (`t[t(1)][t(0)] = t(7)` on rows of a nested Array literal), which takes the value first;
- an Array of objects, whose value form binds the value before it reads the key: `cs[j] = (j += 1; Cell.new(9))` stores at 1;
- a Hash store whose value is used, `x = (h[k] = (k += 1; 5))`, which reads the key after the value;
- an operand that reads what an earlier one assigns: `a[i += 1] = i * 10` stores 0 with gcc, and so does a call's `pair(i += 1, i * 10)`.

Test: `test/index_set_stmt_operand_order.rb`. 57 of its 106 lines are wrong on master with gcc and one with clang, and it aborts at stress 2 with both.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: nothing
