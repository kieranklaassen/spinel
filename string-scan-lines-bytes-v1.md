<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**Cost, first: a fix with a stated cost.** `scan` with a String pattern of two bytes or more costs up to 19.6% more where the pattern is not found (`s.scan("zz")` on a String of 176 bytes: 96 instructions a call with gcc, 91 and +19.4% with clang) and up to 12.9% more where it is found (99 a call; clang 94, +12.1%). `lines` with such a separator costs up to 7.9% more (found twice, 76 a call; clang 64, +6.9%). A miss walks nothing of the pattern. What it adds is the two byte lengths read from the headers and one `strlen` of what is left of the subject: `strstr` does not say where it stopped, and the `strlen` tells the String's end from a NUL byte inside it. Instructions a call by callgrind on master a2bd8900 with the commits beneath, on Strings with no NUL, a gcc build then a clang build.

By the pattern's length, on a subject of 2 bytes where it is not found and on one that holds it twice:

| | 2 bytes | 17 bytes | 224 bytes | 880 bytes |
|---|---|---|---|---|
| `s.scan(q)`, not found | +51 (+15.2%), +46 (+14.6%) | the same | +4 (+1.0%), +1 (+0.3%) | -50 (-11.4%), -49 (-11.9%) |
| `s.scan(q)`, found twice | +99 (+12.9%), +94 (+12.1%) | +99 (+10.6%), +94 (+9.9%) | +99 (+2.8%), +94 (+2.7%) | +99 (+0.8%), +94 (+0.8%) |
| `s.lines(q)`, not found | +36 (+6.9%), +18 (+3.6%) | the same | -11 (-1.9%), -27 (-4.9%) | -65 (-10.5%), -77 (-12.9%) |
| `s.lines(q)`, found twice | +76 (+7.9%), +64 (+6.9%) | +64 (+5.6%), +52 (+4.6%) | +11 (+0.3%), -1 (0.0%) | -89 (-0.7%), -101 (-0.8%) |

By the subject's length, a pattern that is not found:

| | 2 bytes | 176 bytes | 880 bytes |
|---|---|---|---|
| `s.scan("zz")` | +51 (+15.2%), +46 (+14.6%) | +96 (+19.6%), +91 (+19.4%) | +148 (+17.4%), +143 (+17.2%) |
| `s.scan("z")` | +12 (+3.7%), +11 (+3.6%) | -57 (-13.3%), -58 (-14.2%) | -199 (-30.6%), -200 (-31.8%) |
| `s.lines("zz")` | +36 (+6.9%), +18 (+3.6%) | +36 (+4.9%), +18 (+2.5%) | +36 (+2.8%), +18 (+1.4%) |

It gets cheaper as the pattern grows because master took the pattern's `strlen` at the top of every call and this reads the stored length. A pattern that is found pays the subject's `strlen` once a call, behind its last occurrence, and 13 to 15 instructions an occurrence: `scan("the")` with 8 occurrences in 172 bytes +189 (+8.3%), +172 (+7.3%). A pattern of one byte goes by `memchr`: found, scan is within 1.4% of master (-16, +2 a call) and lines is cheaper (-48, -49).

Where a NUL is met the search goes on by `sp_bytestr`, the byte loop master's own `include?`, `index` and unlimited `split` use. `"ab\0cd: ef: gh".scan(": ")` costs 932 instructions a call (clang 937) where the same String with "-" for the NUL costs 865 (870); master stopped at the NUL, found nothing and cost 336 (316). A pattern that holds a NUL is found too early by `strstr`, which reads it to its NUL, and is searched by `sp_bytestr` from that first hit: `scan("zq\0zq")` on a String that holds "zq" twenty times before the pattern costs 1,447 (1,438), where `scan("zq-zq")` on the same String costs 916 (909) and master, which read the pattern as "zq" and answered 21 matches, cost 5,448 (5,700); `lines("zq\0zq")` on that String 1,624 (1,568) against master's 5,611 (5,467).

```ruby
p "x\0b,b".scan("b").length              # CRuby 2. Here: 0
p "x,a\0b".scan("a\0b")[0].bytesize      # CRuby 3. Here: 1
p "a\0b;c".lines(";").length             # CRuby 2. Here: 1
p "\0ab".lines("b")                      # CRuby ["\u0000ab"]. Here: []
```

Two commits, each with its test.

scan with a String pattern measured the pattern by `strlen` and searched with `strstr`, which ends at the subject's first NUL byte. It now reads byte lengths and searches with `sp_str_find` (`lib/sp_str.h`). One byte is found by `memchr`. A longer pattern is sought by `strstr` as before; only where that finds nothing and a NUL lies inside the String is the rest searched by `sp_bytestr`, and a pattern with no NUL cannot lie across one, so nothing is missed. `strstr` reads the pattern to its first NUL too, so at a call's first hit the `strlen` of the pattern, which the function took at its top on master, says whether the pattern holds one; if it does, the search goes by `sp_bytestr`. The pattern is walked no more often than on master, and not at all by a call that finds nothing.

lines with a separator took a String that begins with a NUL byte for the empty one, measured the String and the separator by `strlen` and searched with `strstr`. It reads byte lengths, and the separator is found by `sp_str_find`. `each_line` with a separator rides it.

Only `lib/` changes, so no program's generated C changes.

Measured on master a2bd8900 with the commits beneath, against CRuby 3.3.6.

- 1,320 lines of scan with a String pattern and of lines and each_line with a separator (10 Strings, 12 patterns; the Array, its length and its members' bytes, scan with a block and its value, a call inside a method, `chomp: true`), with gcc and with clang, plain and under `SPINEL_GC_STRESS=2` alike: right before and after 669; wrong made right 651; right made wrong 0; none wrong after.
- 4,064 lines (508 calls that answer a String or an Array of them, on four Strings, each as a literal and held in a variable): right before and after 3,554; wrong made right 78; right made wrong 0. 288 are wrong before and after, and each prints what it printed: 64 that sub and gsub with a Hash cut at a NUL, the pull request above this one, and the 224 the pull request beneath lists. 144 do not build, raise or stop, before and after. Under `SPINEL_GC_STRESS=2`: 78 made right, none lost.

**Not here.**

- sub and gsub with a String pattern and a Hash still measure by `strlen` and search with `strstr`: a pull request of its own that depends on this one for `sp_str_find`. So do sub and gsub with a block.
- CRuby raises RuntimeError when a scan's block changes its subject; here the block runs over the matches found at the start, before and after. With the matches behind a NUL found, there are more of them:

  ```ruby
  s = +"ab\0ab\0ab"; a = []; s.scan("ab") { |m| a << m; s.clear }; p a   # master ["ab"], this branch ["ab", "ab", "ab"]
  s = +"abxabxab";   a = []; s.scan("ab") { |m| a << m; s.clear }; p a   # master ["ab", "ab", "ab"]
  ```
- CRuby raises Encoding::CompatibilityError for a separator that is not the String's encoding; here the bytes are searched, before and after, so one wrong line changes into another: `"\xffab\0\xfeab".b.lines("é")` is ["\xFFab"] on master and the whole String as one line here.
- A String Range compares with `strcmp`, so a method that answered a short Array could give CRuby's answer by chance:

  ```ruby
  p ("ab\0".."abz").cover?("xab\0cab".scan("ab")[1])   # CRuby false. master false, this branch true
  p ("ab\0".."abz").cover?("ab")                       # CRuby false. master true, this branch true
  ```

  The first printed false only because scan answered one "ab", and `[1]` was nil. With both found it prints what master prints for the literal. In a sweep on master a2bd8900 of 3,950 Strings made by methods that cut at a NUL, each put to cover?, ===, `when`, max, min and minmax (43,450 lines), 92 lines of cover?, === and `when` change this way here (scan 32, lines and each_line 60), and 8 lines of max, min and minmax print a wrong line where the commits beneath printed none: in 4 the walk from the short String ran out of time or memory, in 4 it raised RangeError. 84 of the 100 are byte for byte the line master prints for the literal. In the other 16, all `each_line("\0").to_a`, one answer of a line is the literal's and the others stay right:

  ```ruby
  r = ("\0\0".."\0z")
  x = "\0ab".each_line("\0").to_a.first
  puts "#{r.cover?(x)} #{r === x}"   # CRuby false false. master false false, this branch true false
  y = "\0"
  puts "#{r.cover?(y)} #{r === y}"   # CRuby false false. master true true, this branch true true
  ```

  The compare is "cover?, === and max of a String Range compare the whole String", a pull request of its own that depends on this one.

**Tests.** Two files, 19 lines; 16 differ on the commits beneath, and each file fails there.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [ ] Depends on: #____ ("tr_s, format, chomp and four more read a String to its byte length": the commits beneath)
