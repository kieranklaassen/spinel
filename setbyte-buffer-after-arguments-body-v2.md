<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = +"abc"
t = s
s.setbyte(0, (s << ("x" * 4000); 0x41))
p s[0]
```

master prints `"a"`, in a plain run and at `SPINEL_GC_STRESS=1` and `2`; CRuby prints `"A"`. valgrind on master's binary reports two invalid reads and one invalid write in `sp_str_setbyte_cow`, the first `24 bytes inside a block of size 48 free'd` by `realloc`. `spinel diff` on master:

```
spinel diff: output-diff
  program: w1.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"A"
+"a"
```

With this commit `spinel diff` says `same` and valgrind reports 0 errors.

Stated cost: 15 instructions a call where the String comes through a reader and an argument is a method call: `o.b.setbyte(i & 63, byte(i))` goes from 92 to 107 compiled with gcc and from 92 to 106 with clang (callgrind), the handle being rooted while the arguments run. Every other call measured costs what it did: `s.setbyte(i & 63, 65)` 80 to 80 for a String under two names and 77 to 77 through a reader, `s.setbyte(i & 63, byte(i))` on a local 82 to 82, `o.b.setbyte(i & 63, v[i & 1])` 91 to 91.

For a String held by a handle (one under two names, or reached through a reader) `emit_scalar_call_arms` read the handle's buffer pointer and then ran the value and the index. An append inside either one grows the handle and frees that buffer, so the byte went into the freed block and the String kept its old byte. The index form, `s.setbyte((s << ("x" * 4000); 0), 0x41)`, did the same.

The arguments now run ahead of that read, as the shims run theirs (`sb_shim_args_first`), and the frozen check and the buffer's read follow them. This is CRuby's order as well: the index runs before the value (master ran the value first), and `s.setbyte(0, (s.freeze; 0x41))` raises FrozenError (master wrote the byte). Two arguments that are pure reads (`subtree_is_pure_read`: they run no code and allocate nothing) stay where they were, and the arm keeps the C it had for them.

The handle is read before the arguments and used after them, so it has to live through them. A local holds its handle unless an argument rebinds the local. A handle a reader answered is held only by its object, which nothing may hold: with `def fresh = Box.new(+"abcdef")`, `fresh.b.setbyte(0, (keep << churn.last; 0x41))` answers 65 on master and writes the byte into a buffer the collector has freed (valgrind at `SPINEL_GC_STRESS=2`: six errors in `sp_str_setbyte_cow`). Such a handle is now rooted while the arguments run, unless both are pure reads; valgrind then reports 0 errors.

No program of the corpus changes but the new test (`tools/cident.sh`: 6429 identical); optcarrot's generated C is byte-identical.

Not here: setbyte on an Array element or a Hash value whose argument appends to it still ends in a segfault (`a[0].setbyte(0, (a[0] << ("x" * 4000); 0x41))`), on master and here.

Test: `test/setbyte_argument_appends.rb`, in `GC_STRESS_TESTS` for its last lines (the handle nothing else holds); on master a plain run of it ends in a segfault, and 21 of its 29 lines differ or are missing. Also run: 801 generated programs (where the receiver lives, which argument moves the buffer and how, index and value forms, frozen receivers), with gcc and with clang, `SPINEL_GC_STRESS` unset, 1 and 2, without and with `--share-strings`. With gcc 299 of them print CRuby's answer in all six runs on master and 649 with this commit; with clang 278 and 628. None that is right on master is wrong with this commit. Two that crash on master with `--share-strings` now run on and print what master prints for them without the flag: `@b.clear` in the argument does not empty the String there, and the same line written as a statement before the call prints the same on master with the flag. And 120 programs whose receiver nothing else holds, or a local holds, with an argument that allocates, with gcc and clang at `SPINEL_GC_STRESS` unset, 1 and 2: all 120 print CRuby's answer in the six runs on master and with this commit.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
