<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = "a\xC3\xA9".b
puts s.dump               # "aé", CRuby: "a\xC3\xA9"
p s.dump.undump == s      # false, CRuby: true
p s.dump.undump.size      # 2, CRuby: 3
```

`dump` and `undump` answered a UTF-8 String whatever their receiver was, and `dump` wrote the bytes of a binary String as the `\u` escape of a character it does not hold. A binary String that went through them came back as text: it counts characters again and is no longer equal to itself.

`dump` now writes each byte past ASCII of a binary receiver as `\xHH` and answers a binary String for one. `undump` answers in its receiver's encoding, or UTF-8 when the dump holds a `\u` escape, as CRuby does. A UTF-8 receiver gets the bytes it got.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,3 @@
-"a\xC3\xA9"
-true
-3
+"aé"
+false
+2
```

The change is in `lib/sp_str.c` alone: no generated C changes. Test: `test/binary_string_dump_undump.rb`.

This stands on "A String cut from a binary String stays binary", whose helper copies the mark, and on the changes above it up to "Bytes appended to a text String make it binary". It also stands on "sub and gsub with a block copy the subject's tail by its own length": a dump of a binary String is binary now, and without that change the block of `s.dump.sub("=") { |m| m.encoding }` gets a binary `m` where CRuby's is UTF-8.

Not here: CRuby's `undump` raises RuntimeError for a dump that mixes `\x` and `\u` escapes past ASCII; here it answers UTF-8.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # ("Bytes appended to a text String make it binary" and "sub with a block copies no tail when the match ends past the subject")
