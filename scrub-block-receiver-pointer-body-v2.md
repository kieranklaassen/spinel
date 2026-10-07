<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
s = ("\xC3\xA9" * 10) + "\xFE\xFDz"
p s.scrub { |b| b.encoding.to_s }   # "ééééééééééUTF-8ASCII-8BITz", CRuby: "ééééééééééUTF-8UTF-8z"
bad = "ab\xFEcd=\xFDef" * 300
n = 0
400.times { |i| n += (bad + i.to_s).scrub { "?" }.bytesize }   # Segmentation fault
p n
```

`scrub` with a block (new with pull request 7753) cut each valid run and each invalid sequence with `sp_str_substr(receiver + pos, 0, n)`, which reads a String's header behind the pointer it is given and roots that pointer. After an invalid byte that a heap String's marker uses (0xFE, 0xFC, 0xFD, 0xF1, 0xFB, 0xFA, 0xF8) the block's parameter took its encoding from the receiver's own bytes, and a collection inside the call marked the pointer as a String and faulted in `sp_gc_mark`. `emit_op_string_scrub_block` now appends a valid run by its length and cuts the parameter from the receiver itself.

Pull request 7772 cured the ASCII-8BIT receiver, whose block is no longer called; a UTF-8 receiver still walks this loop, and both programs fail on master with it in.

```
spinel diff: crash
  ruby:    exit 0
  spinel:  exit -1 (SIGSEGV)
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1 @@
-"ééééééééééUTF-8UTF-8z"
-1081090
+"ééééééééééUTF-8ASCII-8BITz"
```

The block form gets cheaper, one allocation fewer a run: `s.scrub { "?" }` on a 23-byte String with two invalid bytes goes from 448.2M to 321.4M instructions over 200,000 calls (callgrind). Test: `test/scrub_block_receiver_pointer.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
