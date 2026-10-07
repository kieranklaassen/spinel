<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p "a\0b".codepoints            # CRuby [97, 0, 98]. Here: [97]
p "a\0b".each_codepoint.to_a   # CRuby [97, 0, 98]. Here: [97]
p "é".b.codepoints             # CRuby [195, 169].  Here: [233]
```

`codepoints` with a block walks the String to its recorded byte length (`sp_str_codepoints_all`). Without one, and `each_codepoint` without a block, it walked an older loop (`sp_str_codepoints`) that stopped at the first NUL and decoded a binary String as UTF-8. One function serves both now, shaped as `sp_str_bytes` is: a NUL is a character like any other, and a binary String's codepoints are its bytes. `sp_str_codepoints_all` is gone; the block form calls the one that is left.

Measured on master 185c4d66, CRuby 3.3.6, gcc and clang, plain and under `SPINEL_GC_STRESS=2`: 3,395 lines (37 ways of making the String, 11 of holding it, 35 uses of `codepoints` and `each_codepoint`). Right before and after 1,056; wrong made right 2,229; right made wrong 0. 110 are wrong before and after, for other causes: `codepoints` with a block on a receiver known only at run time raises NoMethodError (56), and a String made by `delete_prefix`, or by `format` with a NUL in its template, already records a short length (54).

Cost by callgrind on the same two trees (master 185c4d66, and this commit on it), 200,000 calls on a 21-byte String: without a block 186.55M instructions to 191.75M (+2.8%, the byte length and the binary mark read once a call); with a block 340.74M to 247.94M.

Not here: an invalid byte sequence (`"\xE3\x81".codepoints`) answers its bytes where CRuby raises ArgumentError, as before.

**Test.** `test/string_codepoints_nul.rb`, 10 lines; all 10 fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not generated here; the generated C changes only where `codepoints` or `each_codepoint` is given a block, in the name of the function called)
- [ ] Depends on: # (nothing)
