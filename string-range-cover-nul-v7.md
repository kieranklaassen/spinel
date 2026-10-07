<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**Cost, first: a fix with a stated cost.** A subject that `strcmp` takes to equal an end pays for a second look: `r.cover?("b")` over `("b".."y")` 83 instructions a call to 211 (clang 80 to 208), a turn of `("zz".."zz").max` 112 to 196 (104 to 184). The greatest member of an excluded end whose begin holds a NUL is walked with the compare by bytes: `("a\0a"..."a\0z").max` 17,772 instructions a turn to 22,284, +25.4% (clang +26.9%), and master's answer there is the begin. Any other walk pays the question asked before it: `("ab"..."af").max` +1.3% (+1.6%), `("a"..."zz").max` -0.1% (0.0%). A subject inside the Range: one `cover?` and one `===` a turn 166.35M instructions to 158.35M for 1,000,000 turns (clang 160.31M to 159.31M); a `case` over three held Ranges, 300,000 turns, 67.08M to 64.56M (65.03M to 65.21M, +0.3%); `("a".."zz").max`, 200,000 turns, 22.35M to 22.15M (20.71M, unchanged). By callgrind on master 9274c732 with the commits beneath, a gcc build then a clang build.

```ruby
p ("a\0b".."a\0c").cover?("a\0a")              # CRuby: false. Here: true
r = ("a\0b".."a\0c")
p ["a\0a", "a\0b", "a\0d"].map { |s| r === s }  # CRuby: [false, true, false]. Here: [true, true, true]
p ("a\0b".."a\0a").max                         # CRuby: nil. Here: "a\u0000a"
p ("a\0a"..."a\0c").max                        # CRuby: "a\u0000b". Here: "a\u0000a"
```

`sp_srange_cover` compares with `strcmp`, which stops at a NUL byte, so every String that shares an end's bytes up to one compares equal to that end. `===` and a `when` over a Range held in a value ride it. `sp_srange_max_v` has the same compare, and so has its walk for the greatest member of an excluded end.

`cover?` and `max` now compare as `strcmp` did, and by the bytes alone past a NUL where `strcmp` finds no difference. A difference `strcmp` does find stands as it is, NUL being the least byte, so the common path is `strcmp` and a branch; the compare past a NUL is reached by a jump to a function with the same arguments. That is why two helpers are not static (they are declared in `lib/sp_range.h`): as static functions gcc splits their Range argument and keeps both ends across `strcmp`, seven instructions more a call.

The walk for the greatest member compares past a NUL only where it is CRuby's walk and a member can hold one: the begin holds a NUL, both ends are 7-bit and the begin has a letter or a digit, so `succ` steps letters and digits alone. That is asked once, before the walk. Every other walk is compared with `strcmp`, as before. `lib/sp_cold.c` and the two prototypes only; the compiler is not touched.

The look past a NUL reads the recorded length, which `strcmp` never did, so a String made with a short one compares short, and on master such a String could answer as CRuby does by luck. The makers are repaired beneath, each in a pull request of its own named under "Depends on". It shares the compare past a NUL with the minimum of a String Range: `minmax` needs both ends repaired. The test makes its Ranges on the spot and reads them under `SPINEL_GC_STRESS=2`, which needs the ends of a String Range kept.

**Measured on master 9274c732 with the commits beneath, each answer compared with CRuby 3.3.6.**
- 95,762 answers, with gcc and with clang: 18 ways of making the subject by 12 pairs of ends by 5 ways of making the end, included and excluded; `cover?`, `===` and a `when` over the held Range for 19 subjects each, and `max` with `minmax`. 87,870 right before and after, 6,550 wrong made right, none right made wrong, the same counts plain and under `SPINEL_GC_STRESS=2`. 1,342 are wrong before and after, each as it was: 756 with a subject or an end read out of a Hash that holds other kinds, 279 over two ends with the same bytes in different encodings, 307 a `max` CRuby refuses for its encodings or whose answer shows a lost binary mark in `inspect`.
- 13,336 lines of `max`, `min` and `minmax` over 3,364 pairs of 58 ends chosen around the walk (NUL bytes, 0x7f, bytes past it, letters, digits, binary Strings), both kinds of end, with gcc: 11,264 right before and after, 853 wrong made right, none right made wrong. 1,179 are wrong before and after, the three lines of 393 pairs with an excluded end whose walk is compared as it was (below). 40 pairs CRuby refuses for their encodings answer here, before and after.
- 43,450 lines with gcc: 3,950 Strings made by the methods repaired beneath, each put to `cover?`, `===`, `when`, `max`, `min` and `minmax`. 29,764 right before and after, 9,730 wrong made right, none right made wrong, and no line that was not printed is printed wrong. 2,402 are wrong before and after: 2,310 print what they printed, and 92 lines of `max` have the right bytes now, as UTF-8 where CRuby keeps the String binary. 1,554 do not build or do not reach their line, before and after.

**Not here.**
- `max` and `minmax` of an excluded end whose walk is not CRuby's: `succ` here steps a last byte of 0x7f to 0x80 and a multibyte tail by its codepoint, where CRuby carries. Such a walk is compared as it was: `("\0\x7f"..."\x01\0").max` stays CRuby's answer, `("\0a"..."\0d")` is repaired, and a walk in between is as right or wrong as on master.
- The walk of two binary ends can yield the excluded end itself: `("\xff\x7f".b..."\xff\x80".b).max` answers the end, as before, and `max(n)`, `max { }`, `max_by` and `last(n)` are not touched.
- Two Strings with the same bytes, one binary and one UTF-8, compare equal, as before: `("é".."é").cover?("é".b)` is true where CRuby says false.
- A subject read out of a slot that holds other kinds (`x = h["s"]`): `r === x` and `when r` answer false, as before.
- `include?` and `member?` walk, and are not touched.

**Test.** `test/string_range_cover_nul.rb`, 29 lines; 12 differ on master and on the commits beneath. It prints the same under `SPINEL_GC_STRESS=1` and `2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [ ] Depends on: #____ ("The minimum of a String Range with an excluded end is decided by its ends": the compare past a NUL, and with it "A String Range made on the spot keeps its ends, made in order, until it is read" and "String#delete_prefix and #delete_prefix! are byte-exact over a NUL"), and the makers: #____ ("tr_s, format, chomp and four more read a String to its byte length"), #____ ("scan and lines find a String pattern by bytes"), #____ ("gsub and sub with a Hash read their Strings by bytes, and the Hash's default"), #____ ("sub and gsub with a String pattern and a block find it by bytes", with the pull requests it names), #____ ("String#split with a limit measures the String and its separator by bytes"), #____ ("String#codepoints without a block walks the String to its byte length")
