<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A String that nothing holds was lost while it was interned as a new Symbol, under the stress lane:

```ruby
p ("a" + "b").to_sym     # :ab in Ruby; :\xDB\xDB on master at SPINEL_GC_STRESS=2, exit 0
p (:ax..:az).to_a        # [:ax, :ay, :az] in Ruby; master at level 2: "the mark reached a freed heap string"
```

`sp_sym_intern_n`, which the compiler writes into each program, allocates only for a name it has not seen, to keep its own copy:

```c
if(sp_ndyn<SP_DYN_SYMS_MAX){sp_dyn_syms[sp_ndyn]=sp_str_from_bytes(s,n);return (sp_sym)(N+sp_ndyn++);}
```

That allocation can collect `s`. The miss now goes through a function of its own that roots `s` for the copy:

```c
static SP_NOINLINE SP_COLD sp_sym sp_sym_intern_new(const char *s, size_t n){SP_GC_ROOT_STR(s);sp_dyn_syms[sp_ndyn]=sp_str_from_bytes(s,n);return (sp_sym)(N+sp_ndyn++);}
```

One decision: the root is kept out of `sp_sym_intern_n`. Tried there, inside the miss branch, its cleanup cost every call, 8 instructions an intern. As it is, a name already known runs what it ran before.

The function is in every program, so the generated C of nearly every program changes by these lines and nothing else.

`test/symbol_intern_fresh_string_root.rb` interns Strings made in place through `to_sym`, an interpolated Symbol and a Symbol Range. On master (dafa0d047, gcc and clang) it is right in a plain run and at level 1, and aborts at level 2. It is added to `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it changed by the function above: 2,375,661,925 before, 2,375,629,529 after, checksum 59662 both times, on dafa0d047)
- [ ] Depends on: # (nothing)
