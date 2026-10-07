<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = "ab=cd".b
p s.sub("=") { "-" }.encoding.to_s    # "UTF-8", CRuby: "ASCII-8BIT"
b = "\xC3\xA9=".b
p b.gsub("=") { "-" }.size            # 2, CRuby: 3
```

`sub` and `gsub` with a block build their answer from the subject's bytes and the block's values. The subject's bytes go in by their length and bring no encoding, so the answer took its encoding from the block's values alone: a binary subject came back UTF-8 unless the block answered a binary String, and counted characters again.

The answer now starts in the subject's encoding, as CRuby's does. What the block answers is appended by the rule `<<` already follows, so a value past ASCII in UTF-8 still makes an ASCII-only binary answer text.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-"ASCII-8BIT"
-3
+"UTF-8"
+2
```

It costs one test of the subject's mark a call, 12 to 17 instructions: `s.gsub("=") { ":" }` on a 25-byte String goes from 328.6M to 331.9M instructions over 200,000 calls (callgrind, gcc), a `gsub` that finds no match from 198.2M to 201.2M, a `sub` that finds none from 195.2M to 197.6M. Test: `test/gsub_block_subject_encoding.rb`.

This stands on "sub with a block copies no tail when the match ends past the subject" and the piece beneath it, which made the subject's bytes go in by their length; and on "sub! and gsub! on a boxed String answer nil only when nothing matched": until then a boxed `gsub!` whose block wrote the bytes it found answered its receiver only because the answer's encoding was not the subject's.

Not here: a bang form on a receiver that is shared by reference keeps the receiver's own encoding, on master and here: after `x.sub!("=") { "é" }` such a binary `x` is still binary where CRuby makes it UTF-8. A binary subject with bytes past ASCII and a UTF-8 value with a character past ASCII raise Encoding::CompatibilityError in CRuby and answer here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # ("sub with a block copies no tail when the match ends past the subject" and "sub! and gsub! on a boxed String answer nil only when nothing matched")
