<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A String that nothing holds was lost while it was interned as a new Symbol, under the stress lane:

```ruby
p ("a" + "b").to_sym     # :ab in Ruby; :\xDB\xDB on master at SPINEL_GC_STRESS=2, exit 0
p :"q#{1 + 1}"           # :q2 in Ruby; the same poisoned bytes
p :ox.succ               # :oy in Ruby; the same
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

Cost, callgrind with gcc on d02a49fb7: 200,000 lookups of a name in the program's table take 11,062,647 instructions before and after; of a name already in the pool 232,348,995 and 231,957,637. A new name pays for the `malloc` and the `free`: 8,000 new names take 1,355,138,382 before and 1,356,466,825 after, 166 a name.

The function is in nearly every program: the generated C of 6,282 of the 6,404 corpus programs changes (the new test among them), by that line and nothing else. A program that makes no new Symbol at run time gets the changed text of that one function and nothing else, no declaration, table or call, and never reaches the changed branch: optcarrot calls `malloc` and `free` the same number of times before and after and runs no instruction of `sp_sym_intern_n` in either build. Its 67,729 instructions of difference (0.002%) are three functions that touch no Symbol, which gcc lays out differently when the unit's text changes: `sp_IntArray_set` 71,580 more, `sp_PolyPolyHash_get` 48,785 more, `sp_CPU_rw_op` 52,696 fewer.

Of 60 corpus tests that make a Symbol at run time, 20 fail at level 2 on master built with gcc; 11 of them pass here, and none that passed fails.

`test/symbol_intern_fresh_string_root.rb` interns Strings made in place through `to_sym` and an interpolated Symbol. On master (d02a49fb7, gcc and clang) it is right in a plain run and at level 1, and prints seven wrong lines at level 2 with exit 0. It is added to `GC_STRESS_TESTS`.

Not in this change: the walk of a Symbol Range, `(:ax..:az).to_a`. Its cursor String is held by nothing while each Symbol is made: it aborts at level 2, as on master.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written from ruby 3.3.6 with that flag: seven lines, the last two `true` and `0`)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it changed by the line above, which it never runs: 3,227,030,925 before, 3,227,098,642 after, checksum 59662 both times, on d02a49fb7)
- [ ] Depends on: # (nothing)
