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

The three now compare as `strcmp` did, and by the bytes alone past a NUL where `strcmp` finds no difference. A difference `strcmp` does find stands as it is, NUL being the least byte, so the common path is `strcmp` and a branch; the compare past a NUL is reached by a jump to a function with the same arguments. That is why two helpers are not static: as static functions gcc splits their Range argument and keeps both ends across `strcmp`, seven instructions more a call. `lib/sp_cold.c` only; the compiler is not touched.

It stands on #NNNN (the minimum of a String Range), whose compare past a NUL it shares: `minmax` needs both ends repaired.

**Measured on master 4d56c157 above #NNNN, each answer compared with CRuby 3.3.6.**
- 82,632 answers: 16 ways of making the subject by 11 pairs of ends by 5 ways of making the end, included and excluded; `cover?`, `===` and a `when` over the held Range for 19 subjects each, and `max` with `minmax`. 75,288 right before and after, 6,119 wrong made right, none right made wrong, the same counts plain and under `SPINEL_GC_STRESS=2`.
- 1,225 are wrong before and after: 748 with a subject read out of a Hash that holds other kinds (`cover?` and `when` answer false there), 267 over two ends with the same bytes in different encodings, 210 a `max` whose answer shows a lost binary mark in `inspect`.
- Cost by callgrind. One `cover?` and one `===` a turn, 1,000,000 turns: 166.34M instructions to 158.34M. A `case` over three held Ranges, 300,000 turns: 67.08M to 64.56M. `("a".."zz").max`, 200,000 turns: 22.14M to 21.94M. A subject `strcmp` takes to equal an end pays for the second look: `cover?` 83 instructions a call to 211, a turn of `("zz".."zz").max` 111 to 195.

**Not here.**
- Two Strings with the same bytes, one binary and one UTF-8, compare equal, as before: `("é".."é").cover?("é".b)` is true where CRuby says false.
- `cover?` and `when` with a subject read out of a slot that holds other kinds.
- `include?` and `member?` walk, and are not touched.

**Test.** `test/string_range_cover_nul.rb`, 27 lines; 12 differ on master. It prints the same under `SPINEL_GC_STRESS=1` and `2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [x] Depends on: #NNNN
