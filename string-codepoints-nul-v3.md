<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p "a\0b".codepoints            # CRuby [97, 0, 98]. Here: [97]
p "a\0b".each_codepoint.to_a   # CRuby [97, 0, 98]. Here: [97]
p "é".b.codepoints             # CRuby [195, 169].  Here: [233]
```

`codepoints` with a block walks the String to its recorded byte length (`sp_str_codepoints_all`). Without one, and `each_codepoint` without a block or with one on a receiver typed at run time, it walked an older loop (`sp_str_codepoints`) that stopped at the first NUL and decoded a binary String as UTF-8. One function serves them all now, shaped as `sp_str_bytes` is: a NUL is a character like any other, and a binary String's codepoints are its bytes. `sp_str_codepoints_all` is gone; the block form calls the one that is left.

Measured on master 06064727, CRuby 3.3.6, gcc and clang, plain and under `SPINEL_GC_STRESS=2`: 3,395 lines (37 ways of making the String, 11 of holding it, 35 uses of `codepoints` and `each_codepoint`). Right before and after 1,056; wrong made right 2,229; none of these right made wrong. 110 are wrong before and after, for other causes: `codepoints` with a block on a receiver known only at run time raises NoMethodError (56), and a String made by `delete_prefix`, or by `format` with a NUL in its template, already records a short length (54).

Cost by callgrind on the same two trees, 200,000 calls on a 21-byte String: without a block 186.55M instructions to 191.75M (+2.8%, the byte length and the binary mark read once a call); with a block 340.74M to 247.94M.

**Not here.** Three kinds of line are right on master and not here. Each is over a String master already holds wrongly, where the old stop at the first NUL answered right by accident, and each prints what `codepoints` with a block prints on master:
- A forced encoding is not kept: `"a\0".dup.force_encoding("UTF-16LE").codepoints` is `[97]` in CRuby and on master, `[97, 0]` here. Of 840 more lines over forced and rebuilt Strings, 22 are of this kind and 242 go from wrong to right.
- A binary String rebuilt by `chars.join` or `reverse` comes back as text: `s = "é\0".b.chars.join; p s.codepoints.pack("U*") == s` is false in CRuby and on master, true here.
- The same through `next`: `e = "é\0".b.reverse.each_codepoint; p [e.next, e.next]` raised StopIteration on master and prints `[0, 233]` here; CRuby prints `[0, 169]`.

An invalid sequence still answers where CRuby raises ArgumentError, as before: a cut-off one its bytes (`"\xE3\x81".codepoints`), `"\xC0\x80"` `[0]`, `"\xED\xA0\x80"` `[55296]`.

**Test.** `test/string_codepoints_nul.rb`, 10 lines; all 10 fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not generated here; the generated C changes only where `codepoints` or `each_codepoint` is given a block, in the name of the function called)
- [ ] Depends on: # (nothing)
