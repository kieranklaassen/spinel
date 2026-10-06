<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`re.match?(str, pos)` begins at character `pos`, as `str.match?(re, pos)` and
`re.match(str, pos)` do. Spinel took `pos` for a byte offset:

```ruby
s = "éab"
p /a/.match?(s, 2), /b/.match?(s, 3), //.match?(s, 4)
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,3 @@
-false
-false
-false
+true
+true
+true
```

`sp_re_match_p_at` now bounds `pos` by the character length and converts it, as
`sp_re_matchdata_at` does. A 7-bit String takes no walk; one that holds multi-byte characters
pays the walk to `pos`, which `str.match?(re, pos)` pays already.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
