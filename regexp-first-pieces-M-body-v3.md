<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`re.match?(str, pos)` begins at character `pos`, as `str.match?(re, pos)` and
`re.match(str, pos)` do. Spinel took `pos` for a byte offset:

```ruby
s = "éab"
p /a/.match?(s, 2), /b/.match?(s, 3), //.match?(s, 4)
# true, true, true; CRuby prints false, false, false
```

Past a multi-byte character the search began one byte early for each extra byte, and a `pos`
beyond the last character was let through up to the byte length.

`sp_re_match_p_at` now bounds `pos` by the character length and converts it, as
`sp_re_matchdata_at` does. A String of single bytes, and a binary one, count as they did.

Measured on master 52c5ccf74; a number taken on an earlier master says which. lib/sp_re.c, the
one file this changes, is the same bytes on every master named here.

- `test/regexp_match_p_pos_chars.rb` is right with `SPINEL_GC_STRESS` unset, 1 and 2. On master
  7 of its 34 lines differ.
- The generated C is the same by construction: the change is in lib/ (compared over the 6,084
  corpus programs on 2bd029b7e). Three corpus programs call the helper
  (`test/regexp_match_p_position.rb`, `test/typed_slot_conversion.rb` and the new test): the
  first is right on both, the second answers as on master, the new one is wrong on master.
- Multi-byte subjects: eight Strings (two-, three- and four-byte characters, a mix, a
  combining mark, 140 characters, one built at run time, and a 7-bit one) by twelve patterns
  (`\A`, `\G`, `\z`, `^`, `$`, `\b`, a look-behind, a class, the empty pattern) at every
  position from two before the start to two past the end: 2,696 answers, each as CRuby's at
  the three levels. On master 134 differ, none of them on the 7-bit String.
- 217 matrix programs that call `re.match?(s, pos)`, each built and run on both (on
  2bd029b7e): every one answers as on master (137 right on both). Their subjects are 7-bit.
- Cost, by kind of String (callgrind, 400,000 calls each). A 7-bit String takes no walk and
  pays the two new calls, 68 instructions a call (83.9M to 111.1M on a 42-byte one). A String
  that holds multi-byte characters pays the walk to `pos`: 1,329 a call on a 48-character
  Japanese one at position 30 (156.7M to 688.3M). The same loop written `str.match?(re, 30)`
  costs 711.5M on master, so the two forms now cost alike.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
