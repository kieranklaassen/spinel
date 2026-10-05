<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p [[1], [], [2]].inject([]) { |m, v| m + v }
# CRuby: [1, 2]. Here: [1, 0, 0, 0, 0, 0, 0, 0, 0, 2]

p [[1], [], [2]].inject(0) { |n, v| n + v.size }   # CRuby: 2. Here: 10
p [[1, 2], [], [2]].inject(&:|)                    # CRuby: [1, 2]. Here: [1, 2, 0]
p [[1], [9223372036854775808]].inject([]) { |m, v| m + v }
# CRuby: [1, 9223372036854775808]. Here: [1, 140550569328688, 0, 0, 0, 0, 0, 0, 0] (an address)
```

`inject` and `reduce` called on a literal whose rows are all Integer literals type the block's parameters as Integer Arrays and read each row out of the boxed table as an `sp_IntArray`, without a test (`comp_is_nested_int_array_literal`: three reads in `src/codegen_fold.c`, and the parameter types). `is_int_array_literal`, which says what such a row is, took an empty `[]` for one. An empty literal has no element to take a kind from and is built there as a poly array, so the fold read one struct through the other: a length of 8, and the poly array's storage as the elements. A row holding a literal past 64 bits is a poly array too, holding a Bignum, and was read the same way. The seed has no part in it.

A row is now an Integer Array literal only when it is built as one: one element at least, each an Integer literal that fits an `sp_int`. A table with any other row folds boxed, as a table with a Float or a String row does. One function changes, by two conditions.

**Measured against master 701529f0, each program compared with CRuby 3.3.6.** 10,360 generated programs, each a different one: a table of rows (Integer, Float, String, mixed, with nil, with a literal past 64 bits, negative) with an empty row nowhere, first, in the middle, last, twice, or alone; held as the literal, in a local, in a parameter, in a constant; folded 74 ways (`inject` and `reduce` with the seeds `[]`, `Array.new`, `[0].take(0)`, `[7]`, a local, none, `0`, `""`, `false`; `+`, `concat`, `|`, `&`, `-`, `<<`; `:+`, `&:|`, `&:&`, `&:-`; `each_with_object`, `sum([])`, `flat_map`, `flatten`, `map`, `each`).

| | master 701529f0 | this branch |
|---|---|---|
| 9,697 programs | | generated C identical to master's |
| 663 programs (the literal table with an empty or a Bignum row, under `inject` or `reduce`) | 70 as CRuby, 515 wrong and silent, 78 do not build | 647 as CRuby, 16 raise TypeError |

No program that answered as CRuby on master answers differently. The 16 are a Bignum row concatenated into an Integer Array seed (`[[1, 2], [9223372036854775808]].inject([7]) { |m, v| m.concat(v) }`): "cannot store Integer into an Array[Integer]: a typed array holds one kind of element", the error master already raises for the same fold when the table is in a local or the row holds a Float. On master they printed an address and zeros. Pushing the Bignum itself into such a seed (`{ |m, v| m << v[0] }`) raises the same; it is not among the generated programs.

Also fixed and not among the generated programs: `[[1], [], [2]].reduce(:concat)`, `inject(:concat)` and `inject([5], :concat)`, which printed the eight zeros on master.

**Generated C.** `tools/cident.sh` against 701529f0: `5924 identical, 2 differ, 0 refusal changes, 0 refused by both`. The two are the new tests. optcarrot's C does not change.

**Tests.** `test/fold_literal_table_empty_row.rb` (21 lines printed; 14 differ on master) and `test/fold_literal_table_bignum_row.rb` (4 lines; 3 differ on master). Both print the same under `SPINEL_GC_STRESS=1` and `2`.

The `.expected` files are what CRuby 4.0.7 prints with `--enable-frozen-string-literal`.

## `make gate` (on this branch merged with current master)

```
scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
scale-test: work at 4x the program is 4.74x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.10x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.22x (linear 4.00, limit 4.50)
Tests:     5849 pass,        0 fail,        0 error
gate: ALL GREEN
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (test/fold_literal_table_bignum_row.rb)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change, byte for byte; Optcarrot: OK, checksum: 59662)
- [ ] Depends on: # (nothing)
