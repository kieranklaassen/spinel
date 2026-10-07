<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A program that made more than 8,192 Symbols at run time got an existing Symbol back for every new name, and nothing raised:

```ruby
h = {}
20_000.times { |i| h[("k" + i.to_s).to_sym] = i }
p h.size                      # 20000 in Ruby; 8193 on master
```

The pool of Symbols made at run time was a fixed array of `SP_DYN_SYMS_MAX` entries, 8,192. Once it was full the generated `sp_sym_intern_n` ended in `return (sp_sym)0;`, the first Symbol of the program's table, for every new name. `to_sym`, `intern`, `:"k#{i}"`, `map(&:to_sym)`, `transform_keys(&:to_sym)` and `JSON.parse(text, symbolize_names: true)` all make their Symbols there.

The static array stays the pool's first block, so `-DSP_DYN_SYMS_MAX=<n>` still sizes what a program that interns little pays for. A full pool moves to a heap block twice the size (`sp_dyn_syms_grow`, cold and out of line), and the marker and the lookups walk a pointer to the block in use. A target that set a small `SP_DYN_SYMS_MAX` to cap the pool's memory now gets a pool that grows past it by `malloc`.

The block a full pool leaves is kept, not freed. A Thread reads a Symbol's name through the pool's address with no lock, and a loop keeps that address across its turns, so a freed block was read: two Threads that read `keep.length` while the main Thread made 17,000 Symbols counted wrong lengths. Every id a reader can hold was made before the move, so its entry in the old block is true. The heap blocks left behind sum to 131,072 bytes less than the one in use: 131,072 beside 262,144 at 16,385 Symbols, 8,257,536 beside 8,388,608 at a million.

One decision, yours to turn: if the pool should stay fixed, the one-line form of this change is a raise in place of `return (sp_sym)0;`. That is loud where master is silent, and the program above still does not run. This change makes it right.

Eleven ways to make a Symbol at run time, each with 8,000, 9,000 and 20,000 names: master is right in the 11 with 8,000 and wrong in all 22 past the limit (8,193 distinct Symbols, or 8,193 Hash entries); all 33 are right with this change.

Cost, callgrind with gcc on 26d456ec1. A program under the limit is given the same ids in the same order. 200,000 lookups of a name in the program's table take 11,059,789 instructions on master and 11,059,811 here; of a name already in the pool 232,344,974 and 231,953,628. 8,000 new names take 1,356,463,952 on the commit below and 1,356,480,578 here, 2 a name. The lookup is the linear walk it was: 20,000 new names take 6,438,751,834. A hash index over the pool would be a change of its own.

The generated C of every program that declares the pool changes, by the pool's lines and nothing else: 6,228 of the 6,350 corpus programs on 26d456ec1.

Not in this change, as on master: four Threads that each make new Symbols crash. The pool has no lock where a name is added.

`test/symbol_pool_grows.rb` makes 10,000 Symbols three ways and reads them back; on master (gcc and clang) it prints 8193 for 9000 in a plain run. `test/symbol_pool_grows_thread.rb` is the two reading Threads; it is right on master, and wrong in most runs where the old block is freed.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written from ruby 3.3.6 with that flag: counts, Symbols and two booleans)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it changed by the pool's lines: 3,227,032,526 on master, 3,227,163,914 here, checksum 59662 both times, on c994071d2)
- [ ] Depends on: # (the pull request "A String made in place is kept alive while it becomes a new Symbol": a new Symbol's name is copied before its String is allocated; this change is one commit above it and rewrites the same line)
