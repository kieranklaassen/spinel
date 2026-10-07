<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Symbol Range literal is walked by name. Every name past the first is a String of its own, made by `sp_str_succ`, and nothing held it while its Symbol was made, which allocates when the name is new:

```ruby
p (:ax..:az).to_a    # aborts at SPINEL_GC_STRESS=2, gcc and clang: "the mark reached a freed heap string"
```

`test/symbol_range_enum.rb` aborts the same way on master (5390d3002).

The cursor is now a root (`emit_range_expr`). `sp_sym_to_s` hands back a marked String on every arm, so the root may name the first cursor too; the end is a name of the table or of the pool and needs none.

A walk of 26 names costs 64 instructions more (callgrind, 100,000 walks of `(:qa..:qz).to_a`: 3,209,740,890 to 3,216,168,769), and a walk of one name 19 more (1,000,000 walks of `(:qa..:qa).to_a`: 202,987,031 to 221,987,035).

Not in this change: `Symbol#succ` and `#next`. `p :ox.succ` prints a Symbol of garbage at `SPINEL_GC_STRESS=2`, as on master: there the name is lost inside the Symbol table's own insert, not in a walk.

No new test: `test/symbol_range_enum.rb` is added to `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no new test)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on 5390d3002)
- [ ] Depends on: # (nothing)
