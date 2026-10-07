<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**Cost, first: a fix with a stated cost.** sub with a String pattern of two bytes or more and a Hash that finds nothing costs 57 instructions a call more with clang and 51 with gcc, on a String of 2 bytes: +36.4% and +30.3% for `s.sub("zz", h)` as a statement, whose result nothing reads; +34.9% and +29.1% for `s.sub!("zz", h)` as a statement; +31.6% and +26.7% where the result's size is read. On 176 bytes it is 102 and 96 a call. gsub with a Hash that finds a pattern it has no key for costs 23.8% more with gcc and 12.2% with clang (`"azzc".gsub("zz", h)` with a default, 174 and 87 a call; with no default 165 and 76). A miss walks nothing of the pattern. What it adds is the two byte lengths read from the headers and a `strlen` of what is left of the subject, once for sub and twice for gsub, which counts its matches before it copies: `strstr` does not say where it stopped, and the `strlen` tells the String's end from a NUL byte inside it. Instructions a call by callgrind on master a2bd8900 with the commits beneath and the carried one, on Strings with no NUL, a gcc build then a clang build.

By the pattern's length, on a subject of 2 bytes where it is not found and on one that holds it twice (there the pattern is a key):

| | 2 bytes | 17 bytes | 224 bytes | 880 bytes |
|---|---|---|---|---|
| `s.sub(q, h)`, not found | +51 (+26.7%), +57 (+31.6%) | the same | the same | the same |
| `s.gsub(q, h)`, not found | +53 (+14.8%), +4 (+1.1%) | the same | +8 (+1.8%), -48 (-10.4%) | -46 (-9.3%), -98 (-19.1%) |
| `s.gsub(q, h)`, found twice | +106 (+10.7%), +31 (+3.2%) | +94 (+6.9%), +19 (+1.4%) | +41 (+0.6%), -34 (-0.5%) | -59 (-0.3%), -134 (-0.6%) |
| `s.sub(q, h)`, found | -65 (-11.1%), -72 (-12.2%) | -77 (-11.2%), -84 (-12.2%) | -181 (-8.6%), -188 (-8.9%) | -327 (-5.1%), -334 (-5.2%) |

By the subject's length, a pattern of 2 bytes that is not found:

| | 2 bytes | 176 bytes | 880 bytes |
|---|---|---|---|
| `s.sub("zz", h)` | +51 (+26.7%), +57 (+31.6%) | +96 (+28.0%), +102 (+30.7%) | +148 (+20.9%), +154 (+22.1%) |
| `s.gsub("zz", h)`, "zz" a key of `h` | -26 (-5.8%), -73 (-16.3%) | -26 (-4.0%), -73 (-11.3%) | -26 (-2.5%), -73 (-6.9%) |

A pattern that is found and is a key is looked up once where master asked `has_key` and then read it, which is why sub is cheaper found; one that is no key pays the lookup of the default where master stopped at `has_key`: `"azzc".sub("zz", h)` +8 (+1.7%), -14 (-2.9%). A pattern of one byte goes by `memchr` and is cheaper found: gsub -125 and -161 a call, sub -120 and -127. A pattern that holds a NUL is found too early by `strstr`, which reads it to its NUL, and is searched by `sp_bytestr` from that first hit: `gsub("zq\0zq", h)` on a String that holds "zq" twenty times before the pattern costs 2,660 instructions a call (clang 2,448) where the commits beneath, reading the pattern as "zq", cost 4,130 (3,979).

```ruby
p "a\0b".gsub(/[ab]/, { "a" => "1", "b" => "2" }).bytes   # CRuby [49, 0, 50]. Here: [49]
p "x\0b,b".gsub("b", { "b" => "1" }).bytes                # CRuby [120, 0, 49, 44, 49]. Here: [120, 0, 98, 44, 98]
h = Hash.new("?"); h["q"] = "1"
p "abq".gsub("b", h)                                      # CRuby "a?q". Here: "aq"
```

Two commits, each with its test, above the one commit of "gsub with a String and a Hash keeps its result while the match is set", which is carried here (see "Depends on").

The four functions behind gsub and sub with a Hash measured the subject and the replacement by `strlen`, so the answer ended at the first NUL byte of either; the pair for a String pattern also searched with `strstr`, and answered a String whose length was never set. They now read byte lengths, and the String pattern is found by `sp_str_find`. A Regexp's match that holds a NUL byte is looked up as a String of its own.

The second commit is the Hash's default. CRuby reads `hash[match]`, which answers the default for a pattern that is not a key; the pair for a String pattern asked `has_key` first and took "" on a miss, where the pair for a Regexp already reads the default. It stands above the first: while a pattern that begins with a NUL byte was read as the empty pattern it matched at every character, and the default would have been put at each. `"ab".gsub("\0", h)` answers "ab", as it did.

Only `lib/` changes, so no program's generated C changes.

Measured on master a2bd8900 with the commits beneath, against CRuby 3.3.6.

- 6,080 lines of sub and gsub with a String pattern and a Hash (19 Hashes with and without a default, 5 subjects, 8 patterns; gsub, sub, `$~`, gsub! and sub! with their receivers, and the size of the Hash): right before and after 3,284; wrong made right 1,466; right made wrong 0. 1,330 are wrong before and after: 1,280 in the kinds of Hash that raise (below), each printing what it printed, and 50 answers of `gsub!("", h)` and `sub!("", h)` (below), of which 10 printed the String cut at its NUL and print nil now, as for any other String. Under `SPINEL_GC_STRESS=2` 330 of the 760 programs stop on the commits beneath, where gsub's result is not kept; with the first commit here none does: 3,010 lines made right, none lost, and 50 lines print what the plain run prints, the same `gsub!("", h)` answers.
- 4,064 lines (508 calls that answer a String or an Array of them, on four Strings, each as a literal and held in a variable): right before and after 3,632; wrong made right 64; right made wrong 0. 224 are wrong before and after, and each prints what it printed: sub and gsub with a block (112), codepoints (16), delete_prefix (32) and split with a limit (32) past a NUL, `start_with?` over a NUL (12), and 20 that no short length causes. 144 do not build, raise or stop, before and after. Under `SPINEL_GC_STRESS=2`: 64 made right, none lost.

**Not here.**

- `Hash.new("?")` that no String key is stored into, a Hash made with a block and a Hash with Symbol keys raise TypeError ("no implicit conversion of Hash into String") at run time, before and after.
- `gsub!("", h)` and `sub!("", h)` answer nil where `h` has no key "" and no default, before and after; CRuby answers the String, an empty pattern being found.
- sub and gsub with a String pattern and a block still search with `strstr`, and lose the subject's tail past a NUL: two pull requests of their own. Through the second, one wrong answer changes into another:

  ```ruby
  p "a\0b".sub(/b/) { |q| q.upcase }.sub("a") { "A" }.gsub("\0", "\0" => "N").bytes
  # CRuby [65, 78, 66]. master [78, 65, 78], this branch [65]
  ```

  The second sub hands gsub "A", before and after. For "A" this branch's [65] is CRuby's answer; master read the pattern "\0" as the empty one.
- A String Range compares with `strcmp`, so a method that answered a short String could give CRuby's answer by chance:

  ```ruby
  p ("aNb\0".."aNbz").cover?("a\0b".gsub(/\0/, "\0" => "N"))   # CRuby false. master false, this branch true
  p ("aNb\0".."aNbz").cover?("aNb")                            # CRuby false. master true, this branch true
  ```

  The first printed false only because gsub answered "a". With the String whole it prints what master prints for the literal. In a sweep on master a2bd8900 of 3,950 Strings made by methods that cut at a NUL, each put to cover?, ===, `when`, max, min and minmax (43,450 lines), 36 lines of cover?, === and `when` change this way here, all of gsub with a Regexp and a Hash, and 8 lines of max, min and minmax print a wrong line where the commits beneath printed none, the walk from the short String having run out of time or memory. Each of the 44 is byte for byte the line master prints for the literal. The compare is "cover?, === and max of a String Range compare the whole String", a pull request of its own that depends on this one.
- Two gsub calls with a String pattern chained on one Hash whose values are Integers can crash in a plain run, before and after: each call is handed a Hash of the values' Strings, made as an argument that nothing keeps while the other call runs (`("ac" * 40).gsub("c", h).gsub("a", h)` with `h = { "b" => 7 }`, 200,000 rounds). With a default and a short subject the same loop runs: `"ac".gsub("c", h).gsub("a", h)` with `h = Hash.new(0); h["b"] = 7` answers "" in each of 200,000 rounds on master, the default not being read; here it answers CRuby's "00" in each with clang and in all but one with gcc, that one lost to the same unkept Hash.

**Tests.** Two files, 30 lines; 24 differ on the commits beneath, and each file fails there.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [ ] Depends on: #____ ("scan and lines find a String pattern by bytes": `sp_str_find`) and #____ ("gsub with a String and a Hash keeps its result while the match is set": the root across the call that sets `$~`, on the line beneath one this changes; its commit is the first on this branch)
