<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p ("aaa"..."zz").min   # CRuby: "aaa". Here: nil
p ("9"..."11").min     # CRuby: nil. Here: "10"
p ("11"..."9").min     # CRuby: "11". Here: nil
p ("a"...).min         # CRuby: "a". Here: RangeError
```

`sp_srange_min_v` walked a range whose end is excluded and took its least member. CRuby's `range_min` never walks: with no block and no argument the minimum is the begin, or nil when the begin is past the end, or at it with the end excluded. The two ends now decide it, and the answer is the begin itself. An excluded end is compared as the walk compared its members (`sp_str_cmp_bytes`). An included end is compared as `strcmp` compared it, and by its bytes alone past a NUL when `strcmp` finds no difference: `("a\0b".."a\0a").min`, which answered the begin, is nil as in CRuby. No program's generated C changes.

**`to_h` of a boxed String Range is not changed.** `sp_poly_to_h_m` calls the same function to ask whether the Range has a member, and a member is decided by the walk, not by the ends: `("9"..."11")` has two members and no minimum, `("aaa"..."zz")` a minimum and no member. The walk stays, byte for byte, under a name of its own (`sp_srange_least_v`), and `to_h` calls that. Over 21 boxed Ranges (both kinds of end, open sides, empty Strings, a NUL in an end) `to_h` prints on this branch what it prints on master; with the minimum changed and that call left alone, three of them went from right to wrong (`[("9"..."11"), 1][0].to_h` raises TypeError and answered `{}`; `("11"..."9")` and `("aaa"..."zz")` answer `{}` and raised).

It stands on two others. The compare reads the two ends in place, so it needs both ends of a Range made on the spot kept (#____). And `"xa\0b".delete_prefix("x")` recorded a length of 1, so a Range with such an end compared short (#____).

On master a3941433 above both, against CRuby 3.3.6: of 6,264 generated lines (18 ways of making the begin, 15 pairs of contents, 5 ways of making the end, both kinds of end; the minimum's bytes with `frozen?` and `== r.first`, the minimum appended to, `minmax`) 965 go from wrong to right, 3,537 are right before and after, and none that is right changes, plain and under `SPINEL_GC_STRESS=2`. The 1,762 that stay wrong are an append to the answer, which does not show in the Range's begin, a begin read out of a Hash that holds other kinds, and `minmax` over a NUL, whose maximum still compares with `strcmp`.

**An endless Range with an excluded end raised and now answers its begin**, so what a program does next with that String is reached for the first time. Of 450 such lines (the value with `frozen?` and its encoding, `inspect`, `equal?`, an append to it and what the begin holds afterwards) 262 are right, 178 are wrong with nothing said, and 10 over a begin read out of a Hash that holds other kinds are as they were. Each of the 178 is, byte for byte, the line `r.first` prints in place of `r.min` beneath this change: an append to the answer does not reach the begin, a String grown by `<<` is not `equal?` to the read of it, a binary String made by `chars` or `reverse` has lost its binary mark. They are faults of the begin, reached here and not made here. The same holds where the end is given and the minimum was nil: `m = (b..."zz").min` with `b` holding an unfrozen "aaa", then `m << "x"` or `m.upcase!`, printed nil or crashed on master (`<<` left `m` nil and the program ran on, `upcase!` died of a segmentation fault, and with the Range written in place of `b` both raised a FrozenError over nil) and now edits a String that does not reach the begin, as `m = r.first` does beneath this change; `w = r.minmax; w[0] << "x"` raised that FrozenError and prints what it prints on master with the end included.

Cost by callgrind, instructions a call: `("a"..."zz").min` walked its 702 members, about 455,000, and compares the two ends now, under 400; `("a".."zz").min` +6; two ends `strcmp` finds equal, `("zz".."zz").min`, +87, both lengths being read then. `to_h` runs the code it ran.

**Not here.** `"a\0b".codepoints.pack("U*")` and `"x,a\0b".split(",", 2)[1]` record a length of 1 for three bytes, and a Range with such an end still compares short; each maker has its own fix (#____, #____). Two ends with the same bytes, one binary and one UTF-8: an included end takes them for equal, as before. The maximum and `cover?` still stop at a NUL. `to_h` of a boxed String Range is wrong on master in eight of the 21 and stays so.

**Test.** `test/string_range_min_excluded_end.rb`, 36 lines; master prints "10" for its first and stops at its sixth with the RangeError.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [ ] Depends on: #____ (both ends of a String Range made on the spot are kept), #____ (delete_prefix over a NUL)
