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

For a String held by a handle (one under two names, or reached through a reader) `emit_scalar_call_arms` read the handle's buffer pointer and then ran the value and the index. An append inside either one grows the handle and frees that buffer, so the byte went into the freed block and the String kept its old byte. The index form, `s.setbyte((s << ("x" * 4000); 0), 0x41)`, did the same.

The value and the index now go to temporaries, in the order they ran before, and the buffer is read after both. Nothing else in the arm moves. A loop of `s.setbyte(i & 63, 65)` costs 80 instructions a call on master and 80 with this commit for a String under two names, 77 and 77 through a reader (callgrind, 1,000,000 and 2,000,000 calls). Eleven programs of the corpus change, each only in this arm's line, and pass; optcarrot's generated C is byte-identical.

Not here: the value still runs before the index (CRuby runs the index first), the frozen check still stands before the arguments, and a String that does not reach this arm (`@b.setbyte(...)` inside its class, an Array element, a Hash value) answers as on master.

Test: `test/setbyte_argument_appends.rb`; on master 13 of its 21 lines differ or are missing in a plain run. Also run: 801 generated programs (where the receiver lives, which argument moves the buffer and how, index and value forms, frozen receivers), with gcc and with clang, `SPINEL_GC_STRESS` unset, 1 and 2, without and with `--share-strings`. With gcc 302 of them print CRuby's answer in all six runs on master and 602 with this commit; with clang 281 and 581. None that is right on master is wrong with this commit.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
