<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
data = "id=caf\xC3\xA9;x=1\n".b     # what File.binread answers
name = data[/caf../]
p name.encoding                     # UTF-8, CRuby ASCII-8BIT
p name.size                         # 4, CRuby 5
p data.sub("=", ":").size           # 12, CRuby 13
data =~ /=(\w+)(..)/
p $2.size                           # 1, CRuby 2
```

sub and gsub, scan, a slice by a Regexp, partition, rpartition and split by a Regexp, and the Strings a match holds (`$~`, `$1`, `` $` ``, `$'`, `MatchData#[]`, pre_match, post_match, captures, a named group) answered UTF-8 Strings for a BINARY subject. Each String cut from the subject is now marked when the subject is: in `lib/sp_re.c` at the places that copy a span, and in `lib/sp_str.c` for sub, gsub and scan with a String pattern. `gsub("", x)` and `scan("")` step one byte for a marked subject.

sub and gsub write the replacement, so the result takes the encoding `+` gives the two: a character past ASCII written into ASCII-only bytes makes text, as in CRuby.

Test: `test/binary_string_pattern_answers.rb`; 34 of its 48 lines differ on master. split and rpartition by a Regexp stand in a test of their own, `test/binary_string_split_rpartition_regexp.rb`: master aborts in both at `SPINEL_GC_STRESS=2` for any String (the mark reaches a freed piece of their result), before and after this change. A String with no mark pays one test of the mark, 8 to 33 instructions a call. No generated C changes.

Stands on "upcase, reverse, succ and center read a binary String by bytes".

Left as on master:

- sub and gsub with a block are built inline by the compiler, and gsub with a Hash goes through `lib/sp_cold.c`: `"id=caf\xC3\xA9".b.sub("=") { ":" }.encoding` is UTF-8.
- partition and rpartition with no match answer text for the empty pieces: `"caf\xC3\xA9".b.partition("q").map(&:encoding)` is ASCII-8BIT, UTF-8, UTF-8.
- A replacement holding a character past ASCII, written into a subject that holds a byte past ASCII (`"caf\xC3\xA9".b.sub("f", "é")`), raises Encoding::CompatibilityError in CRuby and answers here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
