<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A String that nothing holds was lost while it was interned as a new Symbol:

```ruby
pad = "k" * 20000
syms = []
200.times { |i| syms << (pad + i.to_s).to_sym }
lost = 0
syms.each_with_index { |s, i| lost += 1 unless s.to_s == pad + i.to_s }
p lost                   # 0 in Ruby; 1 on master in a plain run, gcc and clang
```

The seventh name reads back with 3,609 of its 20,000 `k`. With 8,000 names of 4,000 bytes the plain run ends in a segmentation fault. Under the stress lane two characters are enough:

```ruby
p ("a" + "b").to_sym     # :ab in Ruby; :\xDB\xDB on master at SPINEL_GC_STRESS=2, exit 0
p :"q#{1 + 1}"           # :q2 in Ruby; the same poisoned bytes
```

`sp_sym_intern_n`, which the compiler writes into each program, allocates only for a name it has not seen, to keep its own copy:

```c
if(sp_ndyn<SP_DYN_SYMS_MAX){sp_dyn_syms[sp_ndyn]=sp_str_from_bytes(s,n);return (sp_sym)(N+sp_ndyn++);}
```

`sp_str_from_bytes` allocates before it copies, and that allocation can collect `s`. The wrong name then stays in the pool. The bytes are now copied to a `malloc` buffer first:

```c
if(sp_ndyn<SP_DYN_SYMS_MAX){char *nb=(char*)malloc(n?n:1);if(!nb)sp_raise_cls("NoMemoryError","failed to allocate memory");memcpy(nb,s,n);sp_dyn_syms[sp_ndyn]=sp_str_from_bytes(nb,n);free(nb);return (sp_sym)(N+sp_ndyn++);}
```

One decision: `s` is not rooted instead. `sp_sym_intern` is called with bare C literals, which have no marker byte in front, and a root's mark reads that byte.

Cost, callgrind on 8dc552254, gcc and clang. 200,000 lookups of a name in the program's table take 50,167,036 instructions before and 50,167,063 after with gcc, 39,825,143 and 39,825,134 with clang; of a name already in the pool 61,070,998 and 60,471,814, and 57,130,057 and 57,131,537. A new name pays for the `malloc` and the `free`: 8,000 new names take 1,353,599,728 before and 1,354,928,207 after with gcc, 166 a name, and 1,392,673,230 and 1,393,922,345 with clang, 156 a name.

The function is in nearly every program: the generated C of 6,325 of the 6,447 programs under `test/`, `benchmark/` and `packages/*/test/` changes, by that line and nothing else. A program that makes no new Symbol at run time never reaches the changed branch. optcarrot is one: it runs 2,371,400,065 instructions before and 2,371,095,892 after, 304,173 fewer (0.013%), the functions of the unit laid out differently around the changed text.

Six tests already in `test/` print something else than their `.expected` at `SPINEL_GC_STRESS=2` on master and print it with this change: `frozen_chilled_builtin_strings`, `interp_symbol`, `symbol_string_methods`, `symbol_upcase_interpolation` and `bundle_sym` (each with exit 0 on master) and `const_get_dynamic_name` (exit 1).

`test/symbol_intern_fresh_string_root.rb` starts with the program above and then interns Strings made in place through `to_sym` and an interpolated Symbol. On master (8dc552254, gcc and clang) a plain run prints 1 for its first line, level 1 is right, and level 2 prints seven wrong lines with exit 0. It is added to `GC_STRESS_TESTS`.

Not in this change: the walk of a Symbol Range, `(:ax..:az).to_a`. Its cursor String is held by nothing while each Symbol is made: it aborts at level 2, as on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written from ruby 3.3.6 with that flag: eight lines, the first `0` and the last two `true` and `0`)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it changed by the line above, which it never runs: 2,371,400,065 before, 2,371,095,892 after, checksum 59662 both times, on 8dc552254)
- [ ] Depends on: # (nothing)
