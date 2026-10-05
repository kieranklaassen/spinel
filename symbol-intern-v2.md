<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A String that nothing holds is lost while it is interned as a new Symbol, under the stress lane:

```ruby
p ("a" + "b").to_sym     # :ab in Ruby
p (:ax..:az).to_a        # [:ax, :ay, :az]
```

Under `SPINEL_GC_STRESS=2` the first prints poisoned bytes on master and the second aborts ("the mark reached a freed heap string"). A plain run does not show it. Eighteen tests in `test/` fail level 2 for it.

`sp_sym_intern_n`, which the compiler writes into each program, allocates only for a name it has not seen, to keep its own copy:

```c
if(sp_ndyn<SP_DYN_SYMS_MAX){sp_dyn_syms[sp_ndyn]=sp_str_from_bytes(s,n);return (sp_sym)(N+sp_ndyn++);}
```

That allocation can collect `s`. The miss now goes through a function of its own that roots `s` for the copy:

```c
static SP_NOINLINE SP_COLD sp_sym sp_sym_intern_new(const char *s, size_t n){SP_GC_ROOT_STR(s);sp_dyn_syms[sp_ndyn]=sp_str_from_bytes(s,n);return (sp_sym)(N+sp_ndyn++);}
```

A name already known runs what it ran before. The root is kept out of `sp_sym_intern_n` on purpose: tried there, inside the miss branch, its cleanup cost every call, 8 instructions an intern through the reflection helpers.

Because the function is in every program, the generated C of 5,899 of the 6,012 programs in `test/`, `benchmark/`, `packages/*/test/` and optcarrot changes (5,679 of 5,791 tests, 63 of 64 benchmarks, all 156 package tests, optcarrot), each by these lines only (+2 −1). callgrind, instructions, both compilers built on d38099fb5:

| program | master | this branch |
|---|---|---|
| 2,000,000 `to_sym` of four names already known | 192,160,975 | 190,661,051 |
| 300,000 `to_h` of a boxed three-member Struct (900,000 interns of literal names) | 387,014,248 | 387,014,246 |
| 8,000 new Symbols | 1,353,528,021 | 1,353,676,110 |
| optcarrot, checksum 59662 | 2,376,393,853 | 2,376,516,826 |
| benchmark/bm_structaref.rb | 45,666,825 | 45,666,825 |
| benchmark/bm_wordfreq.rb | 4,207,971 | 4,207,971 |

A new Symbol pays 18.5 instructions once, beside about 169,000 for the scan of the table that found it missing. optcarrot interns only while it parses its options; of its +122,973 (0.0052%), 114,649 is in `sp_PolyPolyHash_get`, whose probe counts move with where the program's static data lands: the same pair of builds differed by +40,782 on 3c4334f8a and by +156,061 on a39f82c6b, so read it as about ±0.007%. No program in `benchmark/` interns at run time.

`test/symbol_intern_fresh_string_root.rb` interns Strings made in place through `to_sym`, an interpolated Symbol and a Symbol Range, and joins `GC_STRESS_TESTS`; on 3c4334f8a each of its eight lines fails level 2 alone, and on d38099fb5 the test still fails level 2 on master and passes at every level with this change, with gcc and clang. Eighteen tests in `test/*.rb` that fail level 2 on master (3c4334f8a and d38099fb5 alike) pass with this change: `array_fetch_recv_root`, `boxed_hash_face`, `bundle_sym`, `const_get_dynamic_name`, `dyn_send_splat_builtin`, `frozen_chilled_builtin_strings`, `interp_symbol`, `main_body_split`, `masgn_index_target_widening`, `poly_receiver_string_method`, `reopen_builtin_implicit_self`, `string_case_map_options`, `string_case_map_options_ascii_text`, `symbol_case_setbyte_chr_toc`, `symbol_inspect_nonascii`, `symbol_range_enum`, `symbol_string_methods` and `symbol_upcase_interpolation`. test/main_body_split.rb, already in the tree, prints a freed Symbol's name at SPINEL_GC_STRESS=2 on master (`:c37` as four bad bytes, exit 0) and prints its expected output with this change. On 3c4334f8a the 605 tests whose generated C calls the function all passed a plain run as before, and none that passed level 2 on master failed it with this change (`connect_nonblock_sockaddr_1arg` and `read_nonblock_eof_nil` come and go at level 2 on master itself).

The test's line in `GC_STRESS_TESTS` sits where the String Range inspect fix adds its own: the two conflict in that one Makefile hunk (keep both lines), so whichever lands second is rebased.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it changed by the function above; the numbers are in the table)
- [ ] Depends on: # (nothing)
