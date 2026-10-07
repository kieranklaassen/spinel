<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
s = ([40, 0, 0, 0] + [65] * 8 + [0xFE] + [99, 100]).pack("C*")
p s.sub(/\xFE/n) { "-" }.bytesize                                # 53           CRuby: 15
p "0123456789abcdef\xFEtail".b.gsub("\xFE".b) { "-" }.bytesize   # 926299461    CRuby: 21
p "ab\xFEcd=ef".b.sub("\xFE".b) { "-" }.bytes                    # [97, 98, 45] CRuby: [97, 98, 45, 99, 100, 61, 101, 102]
p "a\0bXc\0d".sub(/X/) { "-" }                                   # "a\u0000b-c" CRuby: "a\u0000b-c\u0000d"
```

`sub` and `gsub` with a block copied what follows a match through a pointer into the subject, by calls that read a String's header behind the pointer. Where the match ends on a byte a heap String's marker uses (0xFE, 0xFC, 0xFD, 0xF1, 0xFB, 0xFA, 0xF8) the length came from the subject's own bytes: in the first line 38 of the 53 bytes are whatever the heap holds past the subject, in the second it is 926 MB of it, and a loop over such Strings faults in a plain run; a shorter subject loses its tail. Anywhere else the length was strlen's and stopped at a NUL. `emit_gsub_block_expr` now passes the lengths it already has (`sp_String_append_n`) and cuts the block's parameter from the subject itself.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,4 +1,4 @@
-15
-21
-[97, 98, 45, 99, 100, 61, 101, 102]
-"a\u0000b-c\u0000d"
+53
+926299461
+[97, 98, 45]
+"a\u0000b-c"
```

Test: `test/gsub_block_subject_tail.rb`; 27 of its 38 lines differ on master. Checked on 743 generated programs built with gcc and with clang and run at `SPINEL_GC_STRESS` unset, 1 and 2: 46 wrong answers and 7 crashes become CRuby's answer, 100 more get the right bytes (their encoding is the one left below), and none that is right on master changes. The block form gets cheaper, one allocation fewer a match: `s.gsub("=") { ":" }` on a 25-byte String goes from 454.5M to 324.1M instructions over 200,000 calls (callgrind). optcarrot's generated C is unchanged.

Left as on master: the answer of the block form on a binary String is UTF-8 where CRuby answers ASCII-8BIT, and a String pattern finds no match after a NUL in the subject.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
