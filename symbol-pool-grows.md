<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A program that made more than 8,192 Symbols at run time got an existing Symbol back for every new name, and nothing raised:

```ruby
h = {}
20_000.times { |i| h[("k" + i.to_s).to_sym] = i }
p h.size                      # 20000 in Ruby; 8193 on master
```

The pool of Symbols made at run time was a fixed array of `SP_DYN_SYMS_MAX` entries, 8,192. Once it was full the generated `sp_sym_intern_n` ended in `return (sp_sym)0;`, the first Symbol of the program's table, for every new name. `to_sym`, `intern`, `:"k#{i}"`, `map(&:to_sym)`, `transform_keys(&:to_sym)` and `JSON.parse(text, symbolize_names: true)` all make their Symbols there.

The static array stays the pool's first block, so `-DSP_DYN_SYMS_MAX=<n>` still sizes what a program that interns little pays for. A full pool moves to a heap block twice the size (`sp_dyn_syms_grow`, cold and out of line), and the marker and the lookups walk a pointer to the block in use.

One decision, yours to turn: if the pool should stay fixed, the one-line form of this change is a raise in place of `return (sp_sym)0;`. That is loud where master is silent, and the program above still does not run. This change makes it right.

Eleven ways to make a Symbol at run time, each with 8,000, 9,000 and 20,000 names: master is right in the 11 with 8,000 and wrong in all 22 past the limit (8,193 distinct Symbols, or 8,193 Hash entries); all 33 are right with this change.

Cost, callgrind on 26d456ec1. A program under the limit is given the same ids in the same order. 200,000 lookups of a name in the program's table take 11,059,789 instructions on master and 11,059,811 here; of a name already in the pool 232,344,974 and 231,953,628. 8,000 new names take 6,772,332,099 on the commit below and 6,772,356,720 here, 3 a name. The lookup is the linear walk it was: 20,000 names take 40 billion instructions, about four seconds. A hash index over the pool would be a change of its own.

The generated C of 6,228 of the 6,350 corpus programs changes, by the pool's lines and nothing else.

`test/symbol_pool_grows.rb` makes 10,000 Symbols three ways and reads them back. On master (26d456ec1, gcc and clang) it prints 8193 for 9000 in a plain run.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written from ruby 3.3.6 with that flag: counts, two Symbols and two booleans)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it changed by the pool's lines: 2,377,782,284 on master, 2,377,807,369 here, 0.001% more, checksum 59662 both times, on 26d456ec1)
- [ ] Depends on: #PR56 (a new Symbol's name is copied before its String is allocated; this change is one commit above it and rewrites the same line)
