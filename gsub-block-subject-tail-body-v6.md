<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p "0123456789abcdef\xFEtail".b.gsub("\xFE".b) { "-" }.bytesize   # 926299461, CRuby: 21
p "ab=cd".b.sub("=") { |m| m.encoding.to_s }                     # "abASCII-8BITcd", CRuby: "abUTF-8cd"
```

`sub` and `gsub` with a block copied what follows a match through a pointer into the subject, by calls that read a String's header behind that pointer. After a match that ends on a byte a heap String's marker uses (0xFE here) the length came from the subject's own bytes, `4567` read as a number: the answer holds 926 MB of whatever follows the subject in memory. Other subjects lose their tail, a text String at its first NUL, and a loop of such calls faults. `emit_gsub_block_expr` now passes the lengths it already has. A String pattern is sought up to its first NUL while its end is counted by its bytes, so with a NUL in the pattern the match can end past the subject's end: `sub` copies no tail then, as on master (the second commit).

The block's parameter was cut through the same pointer. It is now cut from the String CRuby takes it from: the pattern for a String pattern (its bytes, its encoding), the subject for a Regexp.

What it costs. The parameter now has the pattern's encoding, and several String methods on master answer UTF-8 for a binary receiver (`strip`, `chomp`, `tr`, `split`, `downcase` and others). A pattern that came out of one is then read by the wrong encoding, where master, which cut the parameter from the subject, was right:

```ruby
pt = "\xC3\xA9".b.strip                                # binary in CRuby, UTF-8 here
p "ab\xC3\xA9cd".b.sub(pt) { |m| m.size.to_s }.bytes     # [97, 98, 50, 99, 100]; with this change [97, 98, 49, 99, 100]
```

Of 298 programs of this kind 75 go from right to wrong, each through a method that loses the binary mark on master, and 30 go from wrong to right. The same program with `pt.size` in place of `m.size` prints the wrong line on master already. Not in this change: the mark those methods lose. "A String cut from a binary String stays binary" and the three changes above it keep it for 26 of the 29 such methods found.

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

The block form gets cheaper, one allocation fewer a match: `s.gsub("=") { ":" }` on a 25-byte String goes from 459.0M to 324.4M instructions over 200,000 calls (callgrind). A call that finds no match moves by a few instructions: `sub` 4 more a call (194.4M to 195.2M), `gsub` 6 fewer (199.4M to 198.2M). Test: `test/gsub_block_subject_tail.rb`.

This stands on "A method that matches keeps its caller's match alive across a collection": with one allocation fewer a match, `test/gsub_sub_scan_last_match.rb` at `SPINEL_GC_STRESS=2` collects where that frame is not yet rooted.

Not here: the block form's answer on a binary subject is marked UTF-8 where CRuby marks it ASCII-8BIT, on master and here. `r = ("ab\xFE=" * 200).b.gsub("\xFE".b) { |m| "<" + m + ">" }` shows both: on master `r.bytesize` is 1,650,541,229 and printing `r.bytes` does not end; here `r` is the 1,200 bytes CRuby answers, with `r.encoding` UTF-8 and `r.valid_encoding?` false where CRuby says ASCII-8BIT and true. A String pattern finds no match after a NUL in the subject, and one that holds a NUL is cut at it: `"ab".sub("b\0") { "q" }` answers "aq" where CRuby finds no match.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
