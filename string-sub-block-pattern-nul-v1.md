<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**Cost, first: a fix with a stated cost.** At worst +7.3%, 87 instructions a call: `s.gsub(q) { "!" }` with a pattern of 2 bytes held in a variable and found twice (clang build; gcc +3.4%, 41). A call whose last search finds nothing pays one `strlen` of what is left of the subject, and every gsub ends on such a search: for a literal pattern at worst +6.7%, 138 instructions a call, `s.sub("zz") { "!" }` on a String of 880 bytes (gcc build; clang +6.0%, 122). `strstr` does not say where it stopped, and the `strlen` tells the String's end from a NUL byte inside it. Instructions a call by callgrind on master a2bd8900 with the commits beneath, on a String with no NUL, a gcc build then a clang build:

| pattern not found | 2 bytes | 176 bytes | 880 bytes |
|---|---|---|---|
| `s.sub("zz") { "!" }` | +41 (+5.9%), +25 (+3.7%) | +86 (+6.4%), +70 (+5.3%) | +138 (+6.7%), +122 (+6.0%) |
| `s.gsub("zz") { "!" }` | +27 (+3.8%), +21 (+3.1%) | +72 (+5.3%), +66 (+5.0%) | +124 (+5.9%), +118 (+5.7%) |
| `s.gsub("z") { "!" }` | -5 (-0.7%), -5 (-0.7%) | -74 (-5.7%), -74 (-5.9%) | -216 (-11.5%), -216 (-11.6%) |

A pattern that is found: `"name: value: other: tail".gsub(": ") { "=" }` +42 (+2.5%), +45 (+2.6%); `gsub("the") { |m| m + m }` on 32 bytes +22 (+0.7%), +38 (+1.2%); `sub(": ") { "=" }` +13 (+1.1%), +8 (+0.7%); `"hello".gsub("") { "." }` +26 (+1.2%), +50 (+2.2%). A pattern of one byte goes by `memchr`: `gsub("=") { ":" }` on 25 bytes -33 (-1.8%), -25 (-1.3%); `sub(";") { "+" }` -4, -5.

A pattern that is not a literal pays one `strlen` of itself at the call's first hit, which says whether it holds a NUL; a call that finds nothing does not read it. For a literal the compiler knows. By the pattern's length, on a subject of 2 bytes where it is not found and on one that holds it twice:

| | 2 bytes | 17 bytes | 224 bytes | 880 bytes |
|---|---|---|---|---|
| `s.gsub(q) { "!" }`, not found | +37 (+5.2%), +29 (+4.2%) | the same | the same | the same |
| `s.sub(q) { "!" }`, not found | +32 (+4.6%), +23 (+3.4%) | the same | the same | the same |
| `s.gsub(q) { "!" }`, found twice | +41 (+3.4%), +87 (+7.3%) | +41 (+2.9%), +87 (+6.3%) | +88 (+2.3%), +132 (+3.4%) | +142 (+1.2%), +182 (+1.6%) |
| `s.sub(q) { "!" }`, found | +30 (+3.4%), +30 (+3.5%) | +30 (+2.4%), +30 (+2.4%) | +77 (+2.8%), +75 (+2.8%) | +131 (+1.9%), +125 (+1.8%) |
| a literal, not found | +27 (+3.8%), +21 (+3.1%) | the same | the same | the same |
| a literal, found twice | 0, +37 (+3.1%) | 0, +37 (+2.7%) | 0, +37 (+1.0%) | 0, +37 (+0.3%) |

The `gsub(": ")` above with its pattern read from an Array that also holds a Regexp: +90 (+5.1%), +115 (+6.4%).

Where a NUL is met the search goes on by `sp_str_find_rest`, the byte loop master's own `include?`, `index` and unlimited `split` use. `"ab\0cd: ef: gh".gsub(": ") { "!" }` costs 1,318 instructions a call (clang 1,325) where the same String with "-" for the NUL costs 1,212 (1,231). A pattern that holds a NUL is found too early by `strstr`, which reads it to its NUL: `gsub("zq\0zq") { "!" }` on a String that holds "zq" twenty times before the pattern costs 2,373 (2,301) with the pattern in a variable and 2,296 (2,198) as a literal, where `gsub("zq-zq") { "!" }` on the same String costs 1,609 (1,603); beneath this change, where the pattern was read as "zq" and replaced 21 times, 2,703 (2,708).

```ruby
p "a\0b".sub("b") { "zz" }.bytes      # CRuby [97, 0, 122, 122]. Here: [97, 0, 98]
p "a\0b".gsub("\0") { "::" }          # CRuby "a::b". Here: "::::::::"
p "ab\0b".gsub("b\0") { "!" }.bytes   # CRuby [97, 33, 98]. Here: [97, 33, 33]
```

The loop `emit_gsub_block_expr` emits for a String pattern searched with `strstr`, which ends at the subject's first NUL byte and reads the pattern only to its own: a pattern that begins with a NUL was the empty pattern, and "b\0" was "b". A pattern that is a Regexp or a String only at run time took the same `strstr` when it was a String. The loop now searches the subject to its byte length. One byte is found by `memchr`. A longer pattern is sought by `strstr` as before; only where that finds nothing is what stands behind the NUL it ended at searched by `sp_str_find_rest`, and a pattern with no NUL cannot lie across one, so nothing is missed. A pattern that holds a NUL is searched by `sp_str_find_rest`. For a literal the compiler knows which it is, and the emitted loop carries no test of it. An empty pattern matches where it stands, as it did.

The search is written out in the emitted loop, not called as `sp_str_find`: with the call, gcc no longer inlines `sp_String_append_n` into the loop, and the `gsub(": ")` above costs 97 instructions a call more where this costs 42.

Measured on master a2bd8900 with the commits beneath, against CRuby 3.3.6.

- 5,760 lines of sub, gsub, sub! and gsub! with a String pattern and a block (12 subjects, 10 patterns, 4 blocks; the pattern a literal, the answer of a method, and read from an Array that also holds a Regexp), with gcc and with clang, plain and under `SPINEL_GC_STRESS=2` alike: right before and after 3,465; wrong made right 2,283; right made wrong 0. 12 are wrong before and after and print what they printed: `"é\0日b".gsub("") { }`, which steps over a byte (below). Against master itself 2,688 are made right and none is lost. Three lines that are right on master are wrong on the commits beneath and right again here, one program in each of the three ways of holding the pattern:

  ```ruby
  x = "a\0b".b
  t1 = +x; t1.sub!("b") { "" }; p t1.bytes     # CRuby [97, 0]. master [97, 0, 98]
  t2 = +x; t2.sub!("a") { "" }; p t2.bytes     # CRuby [0]. master []
  t3 = +x; t3.sub!("\0") { "" }; p t3.bytes    # CRuby []. master [], the commits beneath [98], this branch []
  ```

  `+x` is `x` itself, so each `sub!` works on what the one before left. master's `[]` came of the dropped tail; with the tail kept and the search not yet mended a "b" is left over.

- 4,064 lines (508 calls that answer a String or an Array of them, on four Strings, each as a literal and held in a variable): right before and after 3,738; wrong made right 70; right made wrong 0. 112 are wrong before and after, and each prints what it printed: codepoints (16), delete_prefix (32) and split with a limit (32) past a NUL, `start_with?` over a NUL (12), and 20 that no short length causes, two of them the `gsub("")` above. 144 do not build, raise or stop, before and after. Under `SPINEL_GC_STRESS=2`: 70 made right, none lost.

**Not here.**

- A block that changes its subject: `s = +"ab"; s.gsub("b") { s << "b"; "x" }` raises RuntimeError ("string modified") in CRuby and answers "ax" here, before and after.
- CRuby hands the block the pattern itself: after `pat = +"b"; "abc".gsub(pat) { |m| m << "x" }` pat is "bx", and a pattern so changed is what the next search looks for. Here the block gets a copy, before and after.
- The answer of sub and gsub with a block on a binary String is UTF-8 where CRuby answers ASCII-8BIT, and `"é".gsub("") { "." }` steps over a byte where CRuby steps over a character, before and after.
- A String Range compares with `strcmp`, so a call that answered a wrong String could give CRuby's answer by chance:

  ```ruby
  p ("a::b\0".."a::bz").cover?("a\0b".sub("\0") { "::" })   # CRuby false. master false, this branch true
  p ("a::b\0".."a::bz").cover?("a::b")                       # CRuby false. master true, this branch true
  ```

  The first printed false only because sub answered "::" on master and "::\0b" on the commits beneath. With "a::b" it prints what master prints for the literal. In a sweep on master a2bd8900 of 3,950 Strings made by methods that cut at a NUL, each put to cover?, ===, `when`, max, min and minmax (43,450 lines), 74 lines of cover?, === and `when` change this way here, and 386 wrong lines are made right. Each of the 74 is byte for byte the line master prints for the literal. The compare is "cover?, === and max of a String Range compare the whole String", a pull request of its own that depends on this one.

**Test.** `test/string_sub_block_pattern_nul.rb`, 18 lines; 14 differ on master and on the commits beneath.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #____ ("scan and lines find a String pattern by bytes": `sp_str_find_rest`), #____ ("sub and gsub with a block copy the subject's tail by its own length": the same loop; what stands before and behind a match found past a NUL is copied by its length there), #____ ("sub with a block copies no tail when the match ends past the subject": the commit beneath) and #____ ("A method that matches keeps its caller's match alive across a collection": the commit beneath those two on this branch)
