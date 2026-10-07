<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A boxed Symbol read by a boxed index that is no Integer answered the first character of its name:

```ruby
g = { "s" => :stone, "f" => 1.5 }
p g["s"][g["f"]]   # "s"; CRuby: "t"
```

`Symbol#[]` is `String#[]` on the Symbol's name. `sp_poly_index_poly` reads a Symbol receiver by an Integer, an Integer Range and a Regexp; an index of any other kind that no earlier arm takes fell to its last line, which reads offset 0. The arm a boxed String has for such an index (`sp_poly_str_aref_other`) now takes a Symbol's name too: a Float is cut, a Float Range slices, an appended String is searched for, and `nil`, `true` or an Array is CRuby's TypeError.

Of 4,496 programs that read a boxed receiver by an index of every kind, 350 reach the new arm: 270 answered wrongly and are right here, 56 are right on both, and the other 24 have a NaN index (below). None that was right is lost.

Over the pull request it stands on, no read that was right pays alone: by callgrind a boxed Symbol read by an Integer runs 537 instructions a loop pass there and 537 here with gcc, 533 and 533 with clang, and a miss on a Symbol-keyed boxed Hash by a boxed Float key 146 and 144, 165 and 165. A loop of both reads counts 687 and 693 with gcc, 707 and 707 with clang.

Not here: with a NaN index a boxed Symbol answers nil where it answered "s", and with a Bignum index it still answers "s"; a boxed String answers the same two, and CRuby raises RangeError for both.

No order with "A boxed Integer's [] reads a Float, nil or Bignum index", which adds its arm on the same line of `sp_poly_index_poly`: the tests are on receivers that exclude each other, and whichever lands later keeps every hunk.

No generated C changes: the function is in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: # (A boxed String's [] reads an appended String, a Float or nil index)
