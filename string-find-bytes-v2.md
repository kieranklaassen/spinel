<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**Cost, first: a fix with a stated cost.** A search for a String pattern of two bytes or more that ends on a miss costs up to 31.6% more: `s.sub("zz", h)` on a String of 2 bytes, 57 instructions a call (clang build; gcc +26.7%, 51). A miss walks nothing of the pattern. What it adds is the two byte lengths read from the headers and one `strlen` of what is left of the subject: `strstr` does not say where it stopped, and the `strlen` tells the String's end from a NUL byte inside it. So the cost grows with the subject and not with the pattern. Instructions a call by callgrind on Strings with no NUL, gcc build then clang build.

By the subject's length, a pattern of 2 bytes that is not found:

| | 2 bytes | 176 bytes | 880 bytes |
|---|---|---|---|
| `s.sub("zz", h)` | +51 (+26.7%), +57 (+31.6%) | +96 (+28.0%), +102 (+30.7%) | +148 (+20.9%), +154 (+22.1%) |
| `s.scan("zz")` | +51 (+15.2%), +46 (+14.6%) | +96 (+19.6%), +91 (+19.4%) | +148 (+17.4%), +143 (+17.2%) |
| `s.lines("zz")` | +36 (+6.9%), +18 (+3.6%) | +36 (+4.9%), +18 (+2.5%) | +36 (+2.8%), +18 (+1.4%) |
| `s.gsub("zz", h)`, "zz" a key of `h` | -25 (-5.6%), -74 (-16.5%) | -25 (-3.9%), -74 (-11.5%) | -25 (-2.4%), -74 (-7.0%) |

By the pattern's length, on a subject of 2 bytes where it is not found and on one that holds it twice:

| | 2 bytes | 17 bytes | 224 bytes | 880 bytes |
|---|---|---|---|---|
| `s.sub(q, h)`, not found | +51 (+26.7%), +57 (+31.6%) | the same | the same | the same |
| `s.scan(q)`, not found | +51 (+15.2%), +46 (+14.6%) | the same | +4 (+1.0%), -5 (-1.4%) | -50 (-11.4%), -55 (-13.2%) |
| `s.gsub(q, h)`, not found, no key | +54 (+15.0%), +3 (+0.9%) | the same | +9 (+2.0%), -43 (-9.4%) | -45 (-9.1%), -93 (-18.4%) |
| `s.lines(q)`, not found | +36 (+6.9%), +18 (+3.6%) | the same | -11 (-1.9%), -33 (-6.0%) | -65 (-10.5%), -83 (-13.8%) |
| `s.scan(q)`, found twice | +99 (+12.9%), +94 (+12.1%) | +99 (+10.6%), +94 (+9.9%) | +99 (+2.8%), +94 (+2.7%) | +99 (+0.8%), +94 (+0.8%) |
| `s.gsub(q, h)`, found twice | +103 (+10.4%), +25 (+2.6%) | +91 (+6.6%), +13 (+1.0%) | +38 (+0.6%), -40 (-0.6%) | -62 (-0.3%), -140 (-0.6%) |
| `s.lines(q)`, found twice | +76 (+7.9%), +64 (+6.9%) | +64 (+5.6%), +52 (+4.6%) | +11 (+0.3%), -1 (0.0%) | -89 (-0.7%), -101 (-0.8%) |
| `s.sub(q, h)`, found | -65 (-11.1%), -72 (-12.2%) | -77 (-11.2%), -84 (-12.2%) | -181 (-8.6%), -188 (-8.9%) | -327 (-5.1%), -334 (-5.2%) |

scan, lines and gsub get cheaper as the pattern grows because master took the pattern's `strlen` at the top of every call and this reads the stored length. A pattern that is found pays the subject's `strlen` once a call, behind its last occurrence, and 13 to 15 instructions an occurrence: `scan("the")` with 8 occurrences in 172 bytes +189 (+8.3%), +172 (+7.3%). gsub with a Hash looks the Hash up once where it was looked up twice. A pattern of one byte goes by `memchr` and is cheaper than master or within 0.2% of it, found (to -21.7%) and not found (-30.7% and -31.8% at 880 bytes), but for a miss on a String of 2 bytes (+12, +10 instructions).

Where a NUL is met the search goes on by `sp_bytestr`, the byte loop master's own `include?`, `index` and unlimited `split` use. `"ab\0cd: ef: gh".scan(": ")` costs 931 instructions a call (clang 937) where the same String with "-" for the NUL costs 864 (870); master stopped at the NUL, found nothing and cost 336 (315). A pattern that holds a NUL is found too early by `strstr`, which reads it to its NUL, and is searched by `sp_bytestr` from that first hit: `scan("zq\0zq")` on a String that holds "zq" twenty times before the pattern costs 1,447 (1,438), where `scan("zq-zq")` on the same String costs 916 (908) and master, which read the pattern as "zq" and answered 21 matches, cost 5,448 (5,700).

```ruby
p "x\0b,b".scan("b").length              # CRuby 2. Here: 0
p "a\0b".gsub(/[ab]/, { "a" => "1", "b" => "2" }).bytes   # CRuby [49, 0, 50]. Here: [49]
p "a\0b;c".lines(";").length             # CRuby 2. Here: 1
h = Hash.new("?"); h["q"] = "1"
p "abq".gsub("b", h)                     # CRuby "a?q". Here: "aq"
```

scan with a String pattern, sub and gsub with a Hash, and lines with a separator measured by `strlen` and searched with `strstr`, which ends at the subject's first NUL byte. Four commits, each with its test. Three share `sp_str_find` (`lib/sp_str.h`). One byte is found by `memchr`. A longer pattern is sought by `strstr` as before; only where that finds nothing and a NUL lies inside the String is the rest searched by `sp_bytestr`, and a pattern with no NUL cannot lie across one, so nothing is missed. `strstr` reads the pattern to its first NUL too, so at a call's first hit the `strlen` of the pattern, which each function took at its top on master, says whether the pattern holds one; if it does, the search goes by `sp_bytestr`. The pattern is walked no more often than on master, and not at all by a call that finds nothing. Only `lib/` changes, so no program's generated C changes.

The second commit is the Hash's default. CRuby reads `hash[match]`, which answers the default for a pattern that is not a key; the pair behind sub and gsub with a String pattern asked `has_key` first and took "" on a miss, where the pair for a Regexp already reads the default. It stands beneath the commit that reads the Hash's Strings by bytes, so that a default behind a NUL is never one wrong answer turned into another.

Measured on master a3941433 above the commits beneath, CRuby 3.3.6: 4,064 lines (508 calls that answer a String or an Array of them, on four Strings, each as a literal and held in a variable). Right before and after 3,554; wrong made right 142; right made wrong 0. 224 are wrong before and after, each with the line it had: sub and gsub with a block (112), codepoints (16), delete_prefix (32) and split with a limit (32) past a NUL, each a fix of its own; `start_with?` over a NUL (12); and 20 that no short length causes. 144 do not build, raise or stop, before and after. Under `SPINEL_GC_STRESS=2`: 142 made right, none lost. Sub and gsub with a String pattern and a Hash, 6,080 lines (19 Hashes with and without a default, 5 subjects, 8 patterns; gsub, sub, `$~`, gsub! and sub! with their receivers, and the size of the Hash): 1,466 made right, 3,284 right before and after, none that is right changes, and 1,330 wrong before and after: 1,280 in the kinds of Hash that raise (below) and 50 answers of `gsub!("", h)` and `sub!("", h)`.

**Not here.**

- `Hash.new("?")` that no String key is stored into, a Hash made with a block and a Hash with Symbol keys raise TypeError ("no implicit conversion of Hash into String") at run time, before and after. `gsub!("", h)` and `sub!("", h)` leave the String as it was and answer nil, before and after. On a String that holds a NUL master answered the String cut at the NUL.
- sub and gsub with a String pattern and a block still search with `strstr`, and lose the subject's tail past a NUL: two pull requests of their own. Through the second, one wrong answer changes into another:

  ```ruby
  p "a\0b".sub(/b/) { |q| q.upcase }.sub("a") { "A" }.gsub("\0", "\0" => "N").bytes
  # CRuby [65, 78, 66]. master [78, 65, 78], this branch [65]
  ```

  The second sub hands gsub "A", before and after. For "A" this branch's [65] is CRuby's answer; master read the pattern "\0" as the empty one.
- CRuby raises RuntimeError when a scan's block changes its subject; here the block runs over the matches found at the start, before and after. With the matches behind a NUL found, there are more of them:

  ```ruby
  s = +"ab\0ab\0ab"; a = []; s.scan("ab") { |m| a << m; s.clear }; p a   # master ["ab"], this branch ["ab", "ab", "ab"]
  s = +"abxabxab";   a = []; s.scan("ab") { |m| a << m; s.clear }; p a   # master ["ab", "ab", "ab"]
  ```
- A String Range compares with `strcmp`, so a method that answered a short Array or String could give CRuby's answer by chance:

  ```ruby
  p ("ab\0".."abz").cover?("xab\0cab".scan("ab")[1])   # CRuby false. master false, this branch true
  p ("ab\0".."abz").cover?("ab")                       # CRuby false. master true, this branch true
  ```

  The first printed false only because scan answered one "ab", and `[1]` was nil. With both found it prints what master prints for the literal. In a sweep on master 5390d300 of 3,950 Strings made by methods that cut at a NUL and put to cover?, ===, `when`, max and minmax, 124 lines change this way here (scan 32, gsub with a Hash 32, lines and each_line 60). 108 are byte for byte the line master prints for the literal. In the other 16, all `each_line("\0").to_a`, one answer of a line is the literal's and the others stay right:

  ```ruby
  r = ("\0\0".."\0z")
  x = "\0ab".each_line("\0").to_a.first
  puts "#{r.cover?(x)} #{r === x}"   # CRuby false false. master false false, this branch true false
  y = ["\0"].first
  puts "#{r.cover?(y)} #{r === y}"   # CRuby false false. master true true, this branch true true
  ```

  The compare is fixed in a pull request of its own that depends on this one.
- `s.gsub("b", h)` in a program that reads `$~` can lose its result to the collector, before and after: `sp_str_gsub_str_str_hash` sets the match after it builds the result. All 760 programs of the Hash sweep read `$~`, and under `SPINEL_GC_STRESS=2` 330 of them stop this way before and after, though not the same 330: 60 with a NUL in the subject stop that ran, the match behind the NUL being found now, and 60 with a NUL in the pattern, which master read as the empty one, run that stopped. Another pull request roots it ("gsub with a String and a Hash keeps its result while the match is set"), on the line beneath one this adds; whichever is second keeps both lines. With that line added to this branch none of the 760 stops, and level 2 prints what the plain run prints.
- Two gsub calls with a String pattern chained on one Hash whose values are Integers can crash in a plain run, before and after. For such a Hash each call is handed a Hash of the values' Strings, made as an argument that nothing keeps while the other call runs:

  ```ruby
  h = { "b" => 7 }
  i = 0
  while i < 200000
    ("ac" * 40).gsub("c", h).gsub("a", h)
    i += 1
  end   # segmentation fault on master and on this branch
  ```

  With a default it is what is left of an answer this makes right. 200,000 rounds of `"ac".gsub("c", h).gsub("a", h)` with `h = Hash.new(0); h["b"] = 7` answer "" in every round on master, the default not being read, and CRuby's "00" in all but one here.

**Tests.** Four files, 49 lines; 40 differ on master, and every file fails there.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [ ] Depends on: #____ ("tr_s, format, chomp and four more read a String to its byte length": the commits beneath)
