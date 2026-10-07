<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p ("a\0b".."a\0c").cover?("a\0a")              # CRuby: false. Here: true
r = ("a\0b".."a\0c")
p ["a\0a", "a\0b", "a\0d"].map { |s| r === s }  # CRuby: [false, true, false]. Here: [true, true, true]
p ("a\0b".."a\0a").max                         # CRuby: nil. Here: "a\u0000a"
p ("a\0a"..."a\0c").max                        # CRuby: "a\u0000b". Here: "a\u0000a"
```

`sp_srange_cover` compares with `strcmp`, which stops at a NUL byte, so every String that shares an end's bytes up to one compares equal to that end. `===` and a `when` over a Range held in a value ride it. `sp_srange_max_v` has the same compare, and so has its walk for the greatest member of an excluded end.

The three now compare as `strcmp` did, and by the bytes alone past a NUL where `strcmp` finds no difference. A difference `strcmp` does find stands as it is, NUL being the least byte, so the common path is `strcmp` and a branch; the compare past a NUL is reached by a jump to a function with the same arguments. That is why two helpers are not static (they are declared in `lib/sp_range.h`): as static functions gcc splits their Range argument and keeps both ends across `strcmp`, seven instructions more a call. The walk of two binary ends can yield the excluded end itself; it is no member, and is never taken for the greatest. `lib/sp_cold.c` and the two prototypes only; the compiler is not touched.

It stands on #____ (the minimum of a String Range), whose compare past a NUL it shares: `minmax` needs both ends repaired. And the look past a NUL reads the recorded length, which `strcmp` never did, so a String made with a short one would compare short: `delete_prefix` (#____), `codepoints` (#____) and `split` with a limit (#____) are repaired beneath.

**Measured on master 06064727 above those, with gcc, each answer compared with CRuby 3.3.6.**
- 95,762 answers: 18 ways of making the subject by 12 pairs of ends by 5 ways of making the end, included and excluded; `cover?`, `===` and a `when` over the held Range for 19 subjects each, and `max` with `minmax`. 87,870 right before and after, 6,550 wrong made right, none in it right made wrong, the same counts plain and under `SPINEL_GC_STRESS=2`.
- 1,342 are wrong before and after: 756 with a subject or an end read out of a Hash that holds other kinds, 279 over two ends with the same bytes in different encodings, 307 a `max` CRuby refuses for its encodings or whose answer shows a lost binary mark in `inspect`.
- Cost by callgrind. One `cover?` and one `===` a turn, 1,000,000 turns: 166.35M instructions to 158.35M. A `case` over three held Ranges, 300,000 turns: 67.08M to 64.56M. `("a".."zz").max`, 200,000 turns: 22.34M to 22.14M. A subject `strcmp` takes to equal an end pays for the second look: `cover?` 83 instructions a call to 211, a turn of `("zz".."zz").max` 112 to 196.

**Not here.**
- Two Strings with the same bytes, one binary and one UTF-8, compare equal, as before: `("é".."é").cover?("é".b)` is true where CRuby says false.
- A subject read out of a slot that holds other kinds (`x = h["s"]`): `r === x` and `when r` answer false, and on some roads `r.cover?(x)` does, as before.
- Seven more makers record a short length over a NUL, and a String from one still compares short: `tr_s`, `gsub` with a Regexp and a block, `sub` with a String pattern and a block, `scan` with a String pattern, `Array#sum("")`, `String#chr`, `format` with a NUL in its template.
- `include?` and `member?` walk, and are not touched.

**Test.** `test/string_range_cover_nul.rb`, 28 lines; 12 differ on master. It prints the same under `SPINEL_GC_STRESS=1` and `2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [ ] Depends on: #____ (the minimum of a String Range), #____ (delete_prefix over a NUL), #____ (codepoints over a NUL), #____ (split with a limit over a NUL)
