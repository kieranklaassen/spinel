<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**Cost.** A search for a String pattern of two bytes or more that is not found pays one `strlen` more: +21.2% at worst (`s.scan("zebra")` on 880 bytes, 41.71M instructions to 50.56M by callgrind), +7.1% to +8.5% on short Strings (`s.lines(": ") + s.scan(": ")` on 66 bytes, `s.scan("the") + s.scan("them")` on 176 bytes). A pattern that is found costs what it did, and a one-byte pattern is cheaper (`s.scan(",")` -3.0%, `s.lines(";")` -2.7%, one byte not found -29.4%). The other rows: `format` with 85 literal bytes in its template +3.1%; tr_s +0.8%; gsub with a Regexp and a Hash +0.9%; sub and gsub with a String pattern and a block +0.8%; `sum("")` -18.5%; gsub with a String pattern and a Hash -7.9%; the rest under 1%.

```ruby
p "PATH=/bin\0".chomp("\0").bytesize     # CRuby 9. Here: 10
p "a\0b".tr_s("a", "z").bytes            # CRuby [122, 0, 98]. Here: [122]
p ["a\0b", "c"].sum("").bytes            # CRuby [97, 0, 98, 99]. Here: [97, 99]
p "\0ab".chr.bytes                       # CRuby [0]. Here: []
p format("a\0b%s", "c").bytes            # CRuby [97, 0, 98, 99]. Here: [97]
p "x\0b,b".scan("b").length              # CRuby 2. Here: 0
p "a\0b".gsub(/[ab]/, { "a" => "1", "b" => "2" }).bytes   # CRuby [49, 0, 50]. Here: [49]
p "ab\0c".sub(/b/) { "zz" }.bytes        # CRuby [97, 122, 122, 0, 99]. Here: [97, 122, 122]
p "a\0b".sub("b") { "zz" }.bytes         # CRuby [97, 0, 122, 122]. Here: [97, 0, 98]
p "a\0b;c".lines(";").length             # CRuby 2. Here: 1
p "a,\0x".split(/,/).map(&:bytes)        # CRuby [[97], [0, 120]]. Here: [[97]]
p ARGF.read.bytes                        # stdin "a\0b\n": CRuby [97, 0, 98, 10]. Here: [97]
```

Each of these measured a String by `strlen`, searched it with `strstr`, or took a first byte of NUL for the empty String, where the String's header holds its byte length. Twelve commits, one a method, each with its test; each message names the function and the cause.

The String searches (scan, lines with a separator, sub and gsub with a String pattern, with a Hash or a block) share one `sp_str_find` in `lib/sp_str.h`. One byte is found by `memchr`. A longer pattern without a NUL is still found by `strstr`; only when `strstr` finds nothing is the rest searched by `sp_bytestr`, behind the NUL it stopped at. Such a pattern cannot lie across a NUL, so nothing is missed. A pattern that holds a NUL is found by `sp_bytestr`.

Measured on master 8684d54c, CRuby 3.3.6: 4,064 lines (508 calls that answer a String or an Array of them, on four Strings, each as a literal and held in a variable). Right before and after 3,250; wrong made right 542; right made wrong 0. 112 are wrong before and after: codepoints (16), delete_prefix (32) and split with a limit (32) past a NUL, each a fix of its own; `start_with?` over a NUL (12); and 20 that no short length causes (`pack("H*")`, `Symbol#inspect`, `tr_s("^a", ...)` over wide characters, `gsub("") { }` on a multibyte String, `bytesplice`). 160 do not build, or raise, before and after. Under `SPINEL_GC_STRESS=2`: 540 made right, none lost, 108 stop before and after. Of the 622 tests in `test/` that call these methods, 621 pass run plain; the other needs `--int-overflow=promote`.

**Not here.** `test/string_split_regexp_nul_field.rb` passes plain and under `SPINEL_GC_STRESS=1`; under `SPINEL_GC_STRESS=2` every Regexp split stops in the collector on master, before and after (`sp_re_split_limit` does not root its Array), so the test is not in `GC_STRESS_TESTS`.

**Tests.** Twelve files, 105 lines; every file fails on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (only the loop emitted for sub and gsub with a block changes)
- [ ] Depends on: # (nothing)
