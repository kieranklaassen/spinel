<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

The compiler frees and reuses its own tables while its memos point into them. A memo that outlives what it points at reads freed memory and the compile finishes all the same: the bytes are usually still there, the C comes out the same, and no test fails. So I built the compiler with `-fsanitize=address,undefined` and compiled the corpus with it. On 0d370b71:

```
san-check: src/analyze_desugar.c:901: null pointer passed as argument 2, which is declared to never be null (6 programs, first test/builtin_reopen_array_hash_poly.rb)
san-check: src/analyze_desugar.c:13484: null pointer passed as argument 2, which is declared to never be null (6 programs, first test/builtin_reopen_array_hash_poly.rb)
san-check: src/spinel_parse.c:433: negation of -9223372036854775808 cannot be represented in type 'long long int'; cast to an unsigned type to negate this value to itself (5 programs, first test/bigint_literal.rb)
san-check: src/node_table.c:142: signed integer overflow: -1 * -9223372036854775808 cannot be represented in type 'long long int' (5 programs, first test/bigint_literal.rb)
san-check: src/node_table.c:140: signed integer overflow: 9223372036854775800 + 8 cannot be represented in type 'long long int' (5 programs, first test/bigint_literal.rb)
san-check: src/sp_macro.c:1676: null pointer passed as argument 1, which is declared to never be null (3 programs, first test/singleton_dsm_local.rb)
san-check: src/analyze_infer.c:379: heap-use-after-free in hv_find (test/hash_new_block_frame.rb)
san-check: 5679 programs, 15 with a report
```

Three commits, the two fixes and then the lane that found them.

**The hash value table keeps its own copy of a slot's name.** `hv_value_class` types the read of a hash whose values are all one class from a table of slots built once per fixpoint round, and a slot's name was the node's own string. In the same round `desugar_block_capture_wrap` renames a block's captured parameters (`subtree_rename_local`, whose `nt_node_set_str` frees the old name), and the next `infer_type`, from `desugar_str_range_methods`, compares the freed bytes in `hv_find`. It happens compiling `test/hash_new_block_frame.rb`. Once the allocator has handed those bytes to another string, the lookup can match the slot of another variable or miss its own. A slot now holds a copy of the name, freed when the table is next built: what a plain build read while the bytes lasted. The table is built no more often than before, so the four scale-test ratios are master's (1.74, 4.82, 6.31, 4.25). Rebuilding the table whenever `nt->version` had moved cures the read too and takes the emission's ratio to 6.94, since every node the emission adds moves the version.

**The compiler compiles the corpus without undefined C of its own.** Four things, in 14 programs. `-9223372036854775808` written in a program: `pm_int_value` negated the bound as a long long and `parse_ll` gathered the digits signed, one past `LLONG_MAX` before the sign was applied; both wrapped to the right answer. A class or module with an empty body: three passes of `src/analyze_desugar.c` `memcpy` from the NULL array `nt_arr` answers for it. A program in which no macro node is tracked: `qsort` of a NULL table. 

Neither changes any generated C: `make cident REF=58f467d5` reports `5682 identical, 0 differ, 0 refusal changes` (run on Linux x86-64).

**`make san-check`.** `build/spinel-san` is the compiler again under both sanitizers, its objects in `build/csrc-san` beside `build/csrc-work`. `tools/san_check.sh` compiles every program of `test/`, `benchmark/`, `packages/*/test` and optcarrot with it and prints one line a site with the number of programs that reach it (`-v` for the first report of each in full). A program the compiler refuses is not a finding. On this branch:

```
san-check: 5682 programs, 0 with a report
```

It is not a gate leg and not built by default: the build is four minutes here on three cores and the pass five (Linux x86-64, gcc 13.3). If you would rather have it in `gate-props`, it is one line.

No function over 1,000 lines grows (`hv_build` and `hv_find` gain one line each). No test is added: the programs that reach these sites are already in `test/`, and it is `make san-check` that fails on them without the fixes.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
  OPTCARROT_LINE
- [ ] Depends on: #
