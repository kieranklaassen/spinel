<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = +"abc"
s.size
s.setbyte(0, 0xC3)
s.setbyte(1, 0xA9)
p s.size    # CRuby 2, master 3
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-2
+3
```

One answer that is right on master changes:

```ruby
s = +"éa"
p s.size             # 2
s.setbyte(2, 0xFF)
p s.size             # CRuby 2, master 2, this 3
```

The write leaves `s` invalid UTF-8. Master answers from the count it took before the write, and only while that count is in the length cache: with `GC.start` between the write and the second `size`, master prints 3 too. This prints 3 either way, the count master gives any invalid String, by its bytes. Of 800 programs of one setbyte and one read on valid text (`size`, `s[-1]`, `s[1]`, `s[-2, 2]`; master d1081446), 122 that are wrong on master print CRuby's answer here and 77 go the other way; in each of the 77 the write leaves the String invalid, and master with a `GC.start` after the write prints what this prints.

Stated cost: a setbyte that writes or replaces a byte past 7 bits in a text String goes from 70 to 111 instructions a call (80 to 123 for a String under two names); it now drops the String's cache entry, as the other in-place changes do. One 7-bit byte over another: 70 to 75 (80 to 87). A binary String: 68 to 70 (76 to 80). Callgrind, setbyte in a loop over a 1 KB String, master 8684d54c against this.

`sp_str_setbyte_cow` wrote the byte and kept the String's entry in the length cache (for a String held by a handle, the hint in its header too), so `size`, `length`, negative indexes and slices answered for the bytes that were there before.

setbyte now drops both (`sp_str_lcache_drop`) when the byte written or the byte it replaces is past 7 bits; one 7-bit byte over another changes no count. A binary String is left alone, its count being its bytes; `force_encoding` drops for it when it becomes text again.

Not here: an invalid String is counted by its bytes (`"\xE6\x97\xA5\xFF".size` is 4 on master, 2 in CRuby), so `s = +"日本"; s.size; s.setbyte(5, 0x41); p s.size` prints 6 here (2 on master, 4 in CRuby). Counting an invalid sequence as CRuby does would change the size of binary data that carries no tag, such as what `sub`, `split` or `strip` return for a `.b` String.

The generated C does not change: the change is in `lib/`. optcarrot: checksum 59662, 2,377,778,203 -> 2,377,811,080 Ir.

Test: `test/setbyte_counts_length_again.rb`; 16 of its 45 lines differ on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
