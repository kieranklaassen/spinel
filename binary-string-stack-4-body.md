<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
data = "caf\xC3\xA9".b              # what File.binread answers
p data.chars[3].encoding            # UTF-8, CRuby ASCII-8BIT
p data.chars.join.size              # 4, CRuby 5
p data.chars.join == data           # false, CRuby true
```

chars cuts a BINARY String into its bytes, and each piece was a UTF-8 String, so the pieces joined were a UTF-8 String again. `sp_str_chars` and `sp_str_chars_poly` already ask whether the receiver is marked, to cut by bytes; they now mark each piece as well. join carries the mark of its elements, so `chars.join`, `chars.map { }.join` and `chars.sort.join` answer a binary String.

Test: `test/binary_string_chars.rb`; 12 of its 18 lines differ on master. A String with no mark pays the branch on the flag the loop already holds, once a character: 38 instructions a call of chars on seven characters. No generated C changes.

Stands on "What a pattern cuts from a binary String stays binary", and on "Array#join picks its encoding before it allocates the result": at `SPINEL_GC_STRESS=2` `chars.join` joins an Array only the call holds, which master's join reads after it is freed.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
