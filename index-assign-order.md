<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Ruby runs `recv[key] = value` receiver, key, value, each once. A store whose value is not used did not:

```ruby
def t(n) = (puts n; n)
a = [0, 0, 0]
a[t(1)] = t(2)            # printed 2 then 1

c[i] = (i += 1; 50)       # stored at the index the value left behind
r[q[0]] = q.shift         # stored at the index the shift uncovered
v[0] = (v = [5, 5]; 6)    # stored into the new Array, not the one named
h[k] = (k += 1; 5)        # a Hash: went in under 1
```

The same through instance variables, globals and class variables: `@cells[@at] = bump` where bump advances `@at`, `@cells[0] = fresh` where fresh stores a new Array in `@cells`.

Such a store never reaches `emit_call`: `emit_stmt_inner` hands it to `emit_array_mutate_stmt`, whose `[]=` arms write one C call with the receiver, the key and the value as sibling arguments, which gcc evaluates right to left. The Hash arm reads its three operands into temps in order, but only when the receiver or the key may allocate.

The new `index_set_stmt_order_shows` asks whether the order can show: the key or the value may give what the receiver reads another object, the value may give what the key reads another (`read_moved_by`), or two of the three operands run something. `emit_index_set_stmt_in_order` then runs the receiver and the key, each that runs something or reads what a later operand can move, ahead of the statement into a temp (`emit_args_before`), and the arm writes the call it always wrote, over those temps. What the arm declines is taken back and the statement is written as the value form, as before. The Hash arm takes its temps on the same question (`index_set_read_moved`), on the line that asked about allocation.

The value form with its value dropped, which the push fix takes, would not do here: it reads a key built of an ivar read (`@cells[@at + 1]`) after the value, and it roots the receiver whether or not anything allocates.

Every other store keeps its single call and its C. Two things hold that where the push's rule would not:

- Operands that store nothing and run no code of the program's cannot show their order however many of them run. `subtree_stores_nothing` is a whitelist: reads, literals, arithmetic, a typed Array's element, a field, a function of Math's, the least or greatest of an Array literal of numbers. A Levenshtein loop's store is `m[i][j] = [m[i - 1][j] + 1, m[i][j - 1] + 1, m[i - 1][j - 1] + cost].min`; with its row read into a rooted temp the loop ran 761,878,771 to 795,474,794 instructions under callgrind. Its C is as it was.
- `read_moved_by` is `read_rebound_by` less what that takes for a rebinding and is none: a builtin over plain values assigns no variable (`subtree_may_run_proc`), nothing hands another Array to an ivar only a constructor assigns (`ivar_set_only_by_ctor`, from the push fix), and a global or a class variable is assigned where it shows or by code of the program's.

Of the 5,540 programs in `test/*.rb` and `benchmark/*.rb` on d9d996ce, the emitted C of 5,536 is byte-identical before and after. The four that change are three tests (`index_write_widens_global_param_array`, `narrowed_element_local_pin`, `struct_custom_initialize_super`) and `benchmark/bm_stark_field.rb`, where two stores of a constructor, `@t[k][j] = Field.add(@t[k][j], 1)` and its `sub`, read their row ahead of the call: 1,108,277,816 to 1,108,375,024 instructions under callgrind (+0.009%). All four print their `.expected` plain, under `SPINEL_GC_STRESS=1` and under `SPINEL_GC_SLAB=0 SPINEL_GC_STRESS=1`. No function over 1,000 lines grows: `emit_array_mutate_stmt_body` has one line changed and the lines it had.

`test/index_set_stmt_operand_order.rb` has each kind of Array the arm stores into and the Hash; the key and the receiver reassigned by the value in a local, an ivar, a global and a class variable, through a method of self's, another object's and a reader; and what can stand where a number would be and still run code (a method the program gives Array called on a literal, an `==` of the program's). 52 of its 97 lines are wrong before this change. Each rule of the checks, removed in turn, fails it (eighteen mutants).

Found with the operand order probe (#7225): `[]=` is its third largest family after `<<` and `push`.

Still on the old path, left for their own changes: a store with a start and a length or a Range, whose value is built first; a store into a boxed value (rows of a nested Array literal, a Hash that widened), which takes the value first; and an Array of objects, whose value form binds the value before it reads the key, so `cs[j] = (j += 1; Cell.new(9))` stores at 1.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
  OPTCARROT_LINE
- [x] Depends on: #7231
