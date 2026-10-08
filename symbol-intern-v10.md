<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A String that nothing holds was lost while it was interned as a new Symbol:

```ruby
words = []
300.times { |i| words << "w#{i}" * 200 }
key = words.join("_").to_sym
p key.to_s == words.join("_")       # true in Ruby; false
p key == words.join("_").to_sym     # true; false
p key.size                          # 218299
```

Master (548d4196d) prints `false`, `false` and `218299` in a plain run, gcc and clang: 215,736 bytes of the name read back as NUL. With many names a plain run loses one of them:

```ruby
pad = "k" * 20000
syms = []
200.times { |i| syms << (pad + i.to_s).to_sym }
lost = 0
syms.each_with_index { |s, i| lost += 1 unless s.to_s == pad + i.to_s }
p lost                   # 0 in Ruby; 1 on master in a plain run, gcc and clang
```

Under the stress lane two characters are enough:

```ruby
p ("a" + "b").to_sym     # :ab in Ruby; :\xDB\xDB on master at SPINEL_GC_STRESS=2, exit 0
p :"q#{1 + 1}"           # :q2 in Ruby; the same poisoned bytes
```

`sp_sym_intern_n`, which the compiler writes into each program, allocates only for a name it has not seen, to keep its own copy:

```c
if(sp_ndyn<SP_DYN_SYMS_MAX){sp_dyn_syms[sp_ndyn]=sp_str_from_bytes(s,n);return (sp_sym)(N+sp_ndyn++);}
```

`sp_str_from_bytes` allocates before it copies, and that allocation can collect `s`. The wrong name then stays in the pool. The copy is now allocated by `sp_str_alloc_nogc`, the runtime's allocator for a pointer that cannot be rooted, which does not collect:

```c
if(sp_ndyn<SP_DYN_SYMS_MAX){char *_d=sp_str_alloc_nogc(n);if(n)memcpy(_d,s,n);sp_dyn_syms[sp_ndyn]=_d;return (sp_sym)(N+sp_ndyn++);}
```

One decision: `s` is not rooted instead. `sp_sym_intern` is called with bare C literals, which have no marker byte in front, and a root's mark reads that byte.

Cost, callgrind on 548d4196d, gcc and clang. 200,000 lookups of a name in the program's table take 11,062,602 instructions before and after with gcc and 11,021,775 with clang; of a name already in the pool 232,348,950 before and 232,148,700 after, and 244,512,539 and 244,512,189. A new name costs no more than it did: 8,000 new names take 1,356,873,798 before and 1,356,747,945 after with gcc, and 1,395,899,776 and 1,395,765,909 with clang; 2,000 names of 4,000 bytes 603,508,180 and 603,494,345, and 606,554,896 and 606,539,050.

The function is in nearly every program: on master 9c7ea3ce0 the generated C of 6,390 of the 6,512 programs under `test/`, `benchmark/` and `packages/*/test/` changes, by that line. A program that makes no new Symbol at run time never reaches the changed branch. optcarrot is one: its run never calls `sp_sym_intern_n`. It takes 2,367,016,156 instructions before and 2,367,025,147 after, 8,991 more of 2.4 billion, in `sp_PolyPolyHash_get` and `sp_gc_wb`, which the change does not touch; two runs of one binary differ by about a thousand.

Six tests already in `test/` print something else than their `.expected` at `SPINEL_GC_STRESS=2` on master and print it with this change: `frozen_chilled_builtin_strings`, `interp_symbol`, `symbol_string_methods`, `symbol_upcase_interpolation` and `bundle_sym` (each with exit 0 on master) and `const_get_dynamic_name` (exit 1).

The walk of a Symbol Range, `(:ax..:az).to_a`, makes each Symbol from a cursor String that nothing else holds. It aborted at level 2 on master and is right with this change, since making the Symbol no longer collects.

`test/symbol_intern_fresh_string_root.rb` starts with the first program above, then counts the names lost of many, then interns Strings made in place through `to_sym` and an interpolated Symbol, and ends with the Range's walk. On master (548d4196d, gcc and clang) a plain run prints `false` and `false` for its first two lines, level 1 is right, and level 2 prints seven wrong lines and aborts at the walk. With this change it prints its `.expected` in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang, and the same with `--share-strings`. It is added to `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master 9c7ea3ce0, built from nothing: the test in the seven collector lanes with gcc and clang, with and without `--share-strings` (master is wrong in a plain run and with `SPINEL_GC_MINOR=0` and `=1`, and aborts at `SPINEL_GC_STRESS=2`; this change is right in every one); `ruby tools/gate.rb check`; the generated C of the 6,512 programs, changed in 6,390 by the one line; optcarrot, checksum 59662; `make share-strings-test` and `make int-min-test`, both pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal` (twelve lines, the first two `true` and the last `[:ax, :ay, :az]`); CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C changed by the line above, which it never runs: 2,367,016,156 instructions before and 2,367,025,147 after, checksum 59662 both times. It depends on no other pull request.
