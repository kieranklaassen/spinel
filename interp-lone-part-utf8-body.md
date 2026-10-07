<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
b = "a".b
puts "#{b}".encoding             # ASCII-8BIT, CRuby: UTF-8
puts "#{"\xff".b}".encoding      # ASCII-8BIT in both
```

An interpolation picks its encoding part by part, and starts from its first part's own encoding unless a literal leads. For an interpolation that is one part and nothing else, that made the answer the part's encoding, where CRuby answers UTF-8 unless the part holds a byte past ASCII: an ASCII-only binary String came back binary from `"#{b}"`. `emit_interp` now starts such an interpolation at UTF-8, as it starts one that a literal leads; the step then gives a part with a byte past ASCII its own encoding, as it did.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-UTF-8
+ASCII-8BIT
 ASCII-8BIT
```

Only an interpolation of one part changes, and in its generated C only the start value. A binary part alone is now scanned once for a byte past ASCII; a UTF-8 part costs a little less than it did. Test: `test/string_interp_lone_part_encoding.rb`.

Not here: `"#{b}#{b}"`, two parts and no literal, is UTF-8 in CRuby 3.3 and BINARY in CRuby 4.0. It answers BINARY here, as it did.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
