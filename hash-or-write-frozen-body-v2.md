<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`h[k] ||= v` and `h[k] &&= v` wrote into a frozen Hash. Stated cost: each write they make now runs the frozen check `h[k] = v` runs, two to four instructions a write, on a Hash that is not frozen too. Where the guard skips, nothing is emitted; gcc's layout costs one instruction a turn in two rows of the table, clang's none. The table is below.

```ruby
h = { a: 1 }.freeze
h[:k] ||= 2
p h.size
```

```
spinel diff: exception-diff
  program: witness.rb
  ruby:    exit 1
  spinel:  exit 0
  exception (ruby):   FrozenError: can't modify frozen Hash: {a: 1}
  exception (spinel): (none)

--- stdout (ruby)
+++ stdout (spinel)
@@ -0,0 +1 @@
+2
```

That is master (8dc552254). `h[:k] = 2` raises FrozenError there. `h[:a] &&= 3` writes too, and so does the write used as a value, `x = (h[:k] ||= 2)`.

`h[k] = v` and `h[k] += v` emit the frozen check in front of the Hash's set. The or-write has a set of its own, in its statement form and in its value form, and neither has the check. Both have it now. It comes after the value, as in the op-assign form: Ruby runs the value before `[]=` raises. A write the guard skips raises nothing, as before: `h[:a] ||= 4` on the Hash above, or `h[:k] ||= 1` on a frozen `Hash.new(0)`, whose default answers the read.

Of 2,560 cases of an or-write into a Hash (eight kinds of Hash; a value of its kind or of another; the Hash in a local, an instance variable or a parameter; a key that is a literal, a local or a call; `||=` and `&&=` as a statement and as a value; the Hash frozen and not), 2,320 run. Master writes into the frozen Hash in 614 of them, and all 614 raise now. Every other case prints what it printed, in the default build and under `--share-strings`. The other 240 are in six programs master refuses, and they are refused the same.

The check runs only where the write happens. callgrind, 200,000 turns (Ir):

| | gcc 13, master | this | clang 18, master | this |
|---|---|---|---|---|
| `c[k] \|\|= 0; c[k] += 1`, 100 Integer keys | 125,250,829 | 125,251,229 | 115,607,883 | 115,408,284 |
| the same, 8 String keys | 56,870,927 | 57,070,943 | 62,878,526 | 62,878,558 |
| `h[i] \|\|= i`, every turn a write | 99,190,981 | 99,590,993 | 99,497,273 | 100,297,264 |
| `h[k] \|\|= i`, 8 String keys | 16,915,464 | 17,115,489 | 19,725,989 | 19,726,003 |
| `u[k] \|\|= []`, 8 String keys | 17,529,557 | 17,529,598 | 20,136,542 | 20,136,623 |

Not here: a frozen Hash reached as an Array's element, as another Hash's value or through a boxed receiver is written by all four forms (`=`, `+=`, `||=`, `&&=`), as on master.

`tools/cident.sh 8dc552254`: 6346 identical, 102 differ, 0 refusal changes. The 102 are the new test, the 96 corpus programs with an or-write into a Hash, in their own text or their package's, the four that print the compiler's revision, and optcarrot. Built by master and by this, the 96 print the same: their `.expected` in a plain run, and at `SPINEL_GC_STRESS=2` too but for ten that fail there on master and here alike (six under `packages/ffi`, two under `packages/fiddle`, `test/hash_iterator_boxed_callable.rb` and `test/hash_store_operand_gc_root.rb`). `make share-strings-test` passes, and `make scale-test` gives master's four ratios (1.71, 4.74, 6.13, 4.17).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it changed: 2,371,399,689 Ir on master, 2,371,116,088 with this; checksum 59662 on both)
- [ ] Depends on: #
