<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p "0123456789abcdef\xFEtail".b.gsub("\xFE".b) { "-" }.bytesize   # 926299461, CRuby: 21
p "ab=cd".b.sub("=") { |m| m.encoding.to_s }                     # "abASCII-8BITcd", CRuby: "abUTF-8cd"
```

`sub` and `gsub` with a block copied what follows a match through a pointer into the subject, by calls that read a String's header behind that pointer. After a match that ends on a byte a heap String's marker uses (0xFE here) the length came from the subject's own bytes, `4567` read as a number: the answer holds 926 MB of whatever follows the subject in memory. Other subjects lose their tail, a text String at its first NUL, and a loop of such calls faults. `emit_gsub_block_expr` now passes the lengths it already has.

The block's parameter was cut through the same pointer. It is now cut from the String CRuby takes it from: the pattern for a String pattern (its bytes, its encoding), the subject for a Regexp.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-21
-"abUTF-8cd"
+926299461
+"abASCII-8BITcd"
```

The block form gets cheaper, one allocation fewer a match: `s.gsub("=") { ":" }` on a 25-byte String goes from 459.0M to 324.4M instructions over 200,000 calls (callgrind); a call that finds no match is unchanged. Test: `test/gsub_block_subject_tail.rb`.

This stands on "A method that matches keeps its caller's match alive across a collection": with one allocation fewer a match, `test/gsub_sub_scan_last_match.rb` at `SPINEL_GC_STRESS=2` collects where that frame is not yet rooted.

Not here: the block form's answer on a binary subject is UTF-8 where CRuby answers ASCII-8BIT, and that is the encoding of the answers master hung or faulted on, too. A String pattern finds no match after a NUL in the subject.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
