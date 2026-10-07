<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**Cost, first.** A search for a String pattern of two bytes or more that ends on a miss pays one `strlen` of the subject and about 50 instructions that master does not pay: at worst +39.9%, 72 instructions a call, for `s.sub("zz", h)` on a String of 2 bytes (clang build; gcc +33.5%, 64). `strstr` does not say where it stopped, and the `strlen` tells the String's end from a NUL byte inside it. Instructions a call by callgrind on a String with no NUL, gcc build then clang build:

| pattern not found | 2 bytes | 176 bytes | 880 bytes |
|---|---|---|---|
| `s.sub("zz", h)` | +64 (+33.5%), +72 (+39.9%) | +109 (+31.8%), +117 (+35.2%) | +161 (+22.8%), +169 (+24.3%) |
| `s.scan("zz")` | +65 (+19.3%), +58 (+18.4%) | +110 (+22.5%), +103 (+22.0%) | +162 (+19.0%), +155 (+18.6%) |
| `s.gsub("zz", h)` | +39 (+8.8%), +28 (+6.2%) | +39 (+6.1%), +28 (+4.3%) | +39 (+3.7%), +28 (+2.6%) |
| `s.lines("zz")` | +44 (+8.4%), +34 (+6.8%) | +44 (+5.9%), +34 (+4.7%) | +44 (+3.4%), +34 (+2.7%) |

A pattern that is found pays it once a call, behind its last occurrence: `"name: value: tail".scan(": ")` +83 (+10.8%), +73 (+9.4%); `gsub("ro", h)` on 43 bytes +63 (+7.7%), +49 (+6.1%); `lines(": ")` on 66 bytes +58 (+4.8%), +64 (+5.4%); `sub("ro", h)` is cheaper (-3.3%, -2.3%). A pattern of one byte goes by `memchr` and is cheaper than master, found (-0.5% to -9.4%) and not found (-29% and -31% at 880 bytes), but for a miss on a String of 2 bytes (+22, +16 instructions). master's own `include?`, `index` and unlimited `split` already search by `sp_bytestr`, a byte loop that costs more than this.

```ruby
p "x\0b,b".scan("b").length              # CRuby 2. Here: 0
p "a\0b".gsub(/[ab]/, { "a" => "1", "b" => "2" }).bytes   # CRuby [49, 0, 50]. Here: [49]
p "a\0b;c".lines(";").length             # CRuby 2. Here: 1
```

scan with a String pattern, sub and gsub with a Hash, and lines with a separator measured by `strlen` and searched with `strstr`, which ends at the subject's first NUL byte. Three commits, one a method, each with its test. They share `sp_str_find` (`lib/sp_str.h`). One byte is found by `memchr`. A longer pattern with no NUL is found by `strstr` as before; only where that finds nothing and a NUL lies inside the String is the rest searched by `sp_bytestr`, and such a pattern cannot lie across a NUL, so nothing is missed. A pattern that holds a NUL is found by `sp_bytestr` from the start. Only `lib/` changes, so no program's generated C changes.

Measured on master 5390d300 above the commits beneath, CRuby 3.3.6: 4,064 lines (508 calls that answer a String or an Array of them, on four Strings, each as a literal and held in a variable). Right before and after 3,554; wrong made right 142; right made wrong 0. 224 are wrong before and after: sub and gsub with a block (112), codepoints (16), delete_prefix (32) and split with a limit (32) past a NUL, each a fix of its own; `start_with?` over a NUL (12); and 20 that no short length causes. 144 do not build, raise or stop, before and after. Under `SPINEL_GC_STRESS=2`: 142 made right, none lost.

**Not here.**

- `h = Hash.new("?"); h["q"] = "1"; "abq".gsub("b", h)` is "aq" where CRuby answers "a?q": a String pattern does not read the Hash's default, before and after. The next pull request.
- sub and gsub with a String pattern and a block still search with `strstr`: a pull request of their own.
- A String Range compares with `strcmp`, so a method that answered a short Array or String could give CRuby's answer by chance:

  ```ruby
  p ("ab\0".."abz").cover?("xab\0cab".scan("ab")[1])   # CRuby false. master false, this branch true
  p ("ab\0".."abz").cover?("ab")                       # CRuby false. master true, this branch true
  ```

  The first printed false only because scan answered one "ab", and `[1]` was nil. With both found it prints what master prints for the literal. In a sweep on master 8684d54c of 3,950 Strings made by methods that cut at a NUL and put to cover?, ===, `when`, max and minmax, 124 lines change this way here (scan 32, gsub with a Hash 32, lines and each_line 60). 108 are byte for byte the line master prints for the literal. In the other 16, all `each_line("\0").to_a`, one answer of a line is the literal's and the others stay right:

  ```ruby
  r = ("\0\0".."\0z")
  x = "\0ab".each_line("\0").to_a.first
  puts "#{r.cover?(x)} #{r === x}"   # CRuby false false. master false false, this branch true false
  y = ["\0"].first
  puts "#{r.cover?(y)} #{r === y}"   # CRuby false false. master true true, this branch true true
  ```

  The compare is fixed in a pull request of its own that depends on this one.
- `s.gsub("b", h)` in a program that reads `$~` can lose its result to the collector, before and after: `sp_str_gsub_str_str_hash` sets the match after it builds the result. Another pull request roots it ("gsub with a String and a Hash keeps its result while the match is set"), on the line beside one this changes; whichever is second keeps both lines.

**Tests.** Three files, 29 lines; 26 differ on master, and every file fails there.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [ ] Depends on: #____ ("tr_s, format, chomp and four more read a String to its byte length": the commits beneath)
