<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p ("a".."e").cover?("b".."c")    # CRuby true. Here: false
p ("a".."e").cover?("b"..."f")   # CRuby true: the argument's greatest member is "e". Here: false
p ("a"..).cover?("b".."c")       # CRuby true. Here: false
```

Range#cover? given a Range asks whether the argument's members all lie within the receiver. An Integer Range answers that (`sp_range_cover_rng`). A String Range had an arm for a String and one for a boxed value; a String Range as the argument fell to the arm that runs the argument and answers false.

`sp_srange_cover_rng` follows CRuby's `r_cover_range_p`: an open side of the argument needs that side of the receiver open; an empty argument holds nothing; the argument's begin lies within the receiver; then the two ends are compared, as whole Strings. Where the receiver includes its end and the argument excludes one past it, the argument's greatest member decides, which only the walk gives, as in CRuby. `===`, `include?` and `member?` ask about one member and are not touched.

The function sits in `lib/spinel_rt.h` beside its Integer twin, so no object of the runtime changes (each compared with the one beneath). No program pays for it but one that asks: the generated C of none of master's 41 tests that name `cover?` changes, with or without `--share-strings`.

**Why it depends on the ends being kept.** Alone on master it is right in a plain run and under `SPINEL_GC_STRESS=1`. Under `SPINEL_GC_STRESS=2` the four programs below whose ends are made on the spot (`((z + "a")..(z + "e")).cover?((z + "b")..(z + "c"))`) abort with gcc, and with clang four of their lines turn wrong: master loses such ends, and its answer `false` never read them. Above the two commits that keep them, nothing is lost at any level. The branch carries those two commits beneath this one.

**Measured on master 3d629868 against CRuby 3.3.6, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`, and with gcc under `--share-strings`; every figure is the same in all of them, against master and against the two commits beneath.** 46 programs, 12,700 lines: 12 receivers by 24 arguments (ends included and excluded, open on either side, empty, of two lengths, past the receiver's end) in 8 holders (two literals, either in a local, both, ends made at run time, parameters, an instance variable, a method's value) by 4 uses (printed, an `if`, negated, interpolated); then the receiver and the argument read out of a boxed slot, `===`, `include?`, `member?`, `==` and `eql?` over the same pairs, 18 other kinds of receiver and argument, and 10 pairs whose ends hold a NUL byte.

- 2,731 wrong lines are right. 9,415 are right before and after. No line that is right is wrong, and no program stops.
- 554 are wrong before and after, and each prints what it printed: 384 are `include?` and `member?` of a String Range open on one side given a Range, which answer false where CRuby raises TypeError; 85 are the argument read out of a boxed slot and 85 the receiver read out of one, which answer false.
- Replayed on master 9c7ea3ce, whose 62 commits touch no function of this change, every program prints what it printed on 3d629868 (gcc, the three levels).

**Test.** `test/string_range_cover_range.rb`: 11 of its 26 lines differ on master. It prints the same under `SPINEL_GC_STRESS=1` and `2`, under the verifier and with `--share-strings`, with gcc and with clang.

**Not here.** `cover?` of one String still compares as far as a NUL byte (`("a\0b".."a\0d").cover?("a\0e")` is true); the Range asked here is compared whole. A Float Range given a Float Range answers false too (`(1.0..10.0).cover?(2.0..3.0)`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not built here; the new arm is reached only by `cover?` of a String Range given a String Range)
- [ ] Depends on: #____ ("A String Range made on the spot keeps its ends, made in order, until it is read")
