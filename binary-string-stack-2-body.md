<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
data = "caf\xC3\xA9 Bar".b          # what File.binread answers
p data.upcase.bytes[3, 2]           # [195, 137], CRuby [195, 169]
p data.reverse.bytes[4, 2]          # [195, 169], CRuby [169, 195]
p data.center(13).size              # 12, CRuby 13
p "\xE9\xFFz".b.upcase.bytes        # [195, 137, 197, 184, 90], CRuby [233, 255, 90]
```

A BINARY String has one-byte characters and no letter past ASCII. upcase, downcase, swapcase, capitalize, reverse, succ, center, ljust and rjust read its bytes as UTF-8 and answered a UTF-8 String, so the data was rewritten: the second byte of a sequence changed case, and a lone byte past ASCII came back as a two-byte character.

For a marked receiver the four case methods map A to Z and a to z and copy every other byte, reverse turns bytes, and succ takes the ASCII path (`"\xFF".b.succ` is `"\x01\x00"`). All of them, with center, ljust and rjust, mark what they answer. A pad is written into the result, so the result takes the encoding `+` gives the two.

Test: `test/binary_string_case_and_shape.rb`; 32 of its 45 lines differ on master. A String with no mark pays one test of the mark, 13 to 21 instructions a call (capitalize, which tests three times, 39). No generated C changes.

Stands on "A String cut from a binary String stays binary".

Left as on master: a pad holding a character past ASCII, given to a binary receiver that holds a byte past ASCII (`"caf\xC3\xA9".b.ljust(8, "é")`), raises Encoding::CompatibilityError in CRuby and answers here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
