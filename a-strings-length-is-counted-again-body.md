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

`sp_str_setbyte_cow` wrote the byte and kept the String's entry in the length cache (for a String held by a handle, the hint in its header too), so `size`, `length`, negative indexes and slices answered for the bytes that were there before.

setbyte now drops both (`sp_str_lcache_drop`) when the byte written or the byte it replaces is past 7 bits; one 7-bit byte over another changes no count. A binary String is left alone, its count being its bytes; `force_encoding` drops for it when it becomes text again.

A String that setbyte leaves invalid UTF-8 is then counted as any invalid String is, by its bytes (`"\xE6\x97\xA5\xFF".size` is 4 on master, 2 in CRuby); that count is not changed here.

Cost, instructions a call (callgrind, setbyte in a loop over a 1 KB String, master 8684d54c -> this; plain, and under two names): binary 68 -> 70, 76 -> 80; text, 7-bit bytes 70 -> 75, 80 -> 87; text, bytes past 7 bits 70 -> 111, 80 -> 123. The generated C does not change: the change is in `lib/`. optcarrot: checksum 59662, 2,377,778,203 -> 2,377,811,080 Ir.

Test: `test/setbyte_counts_length_again.rb`; 16 of its 45 lines differ on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
