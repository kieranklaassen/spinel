<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
data = "caf\xC3\xA9  \n".b          # what File.binread answers
line = data.strip
p line.encoding                     # UTF-8, CRuby ASCII-8BIT
p line.size                         # 4, CRuby 5
p line == "caf\xC3\xA9"             # true, CRuby false
```

strip, lstrip, rstrip, chomp, chop, delete_prefix, delete_suffix, squeeze, delete, tr, tr_s, split, lines and each_line answered a UTF-8 String for a BINARY receiver, where dup, byteslice, a slice and `+` carry the mark. Each now marks what it allocated when its receiver is marked. chop and `split("")` step one byte for a marked receiver; they stepped a UTF-8 character (`"caf\xC3\xA9".b.chop` cut two bytes).

The decision is in tr, delete and squeeze, which decode characters (`"a\xC3\xC3\xA9".b.squeeze` kept both C3 bytes). They keep their one walk: where every set is plain ASCII, which names the same bytes read either way, a marked receiver is widened to Latin-1, walked and narrowed back. A second walk by bytes for each was the alternative. tr writes its second argument, so its result takes the encoding `+` gives the two.

Test: `test/binary_string_cut_keeps_tag.rb`; 48 of its 60 lines differ on master. A String with no mark pays one test of the mark, 13 to 25 instructions a call (callgrind, a million calls). No generated C changes.

Left as on master: a set holding a character past ASCII, given to a binary receiver that holds a byte past ASCII (`"caf\xC3\xA9".b.delete("é")`), raises Encoding::CompatibilityError in CRuby and answers here; `"a\0xxb".b.tr_s("x", "z")` stops at the NUL, as it does for text.

This is the first of five pull requests on binary Strings; the other four stack on it.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
