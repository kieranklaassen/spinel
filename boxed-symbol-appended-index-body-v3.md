<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A boxed Symbol read by a boxed Float, or by a String the program appends to, answered the first character of its name:

```ruby
g = { "s" => :stone, "f" => 1.5 }
p g["s"][g["f"]]   # "s"; CRuby: "t"
```

`Symbol#[]` is `String#[]` on the Symbol's name. `sp_poly_index_poly` has an arm for a Symbol receiver with an Integer, an Integer Range, a Regexp and a nil index; an index of any other kind that no earlier arm takes fell to its last line, which reads offset 0. The arm a boxed String has for such an index (`sp_poly_str_aref_other`) now takes a Symbol's name too: a Float is cut (one past the Integer range is RangeError, in the runtime's wording), a Float Range slices, an appended String is searched for, and `true` or an Array is CRuby's TypeError.

Of 4,496 programs that read a boxed receiver by an index of every kind, 326 reach the new arm: 246 answered wrongly and are right here, 56 are right on both, and the other 24 have a NaN index (below). None that was right is lost.

No arm is added to a read that was right: each returns above the new line. What such a read can pay is the compiler's layout of `sp_poly_index_poly` with one more call in it, so the call is in a function of its own (`sp_poly_sym_aref_other`). By callgrind, instructions a loop pass on the pull request this stands on and here:

| read, receiver and index both boxed | gcc | clang |
|---|---|---|
| a Symbol by an Integer | 626, 617 | 647, 646 |
| a Symbol-keyed Hash missed by a Float key | 151, 142 | 167, 166 |
| those two in one loop | 769, 755 | 811, 809 |
| a Symbol-keyed Hash by a Symbol | 155, 144 | 140, 135 |
| an Array by an Integer | 198, 194 | 183, 185 |
| a String by an Integer | 426, 417 | 443, 440 |
| a String-keyed Hash by a String | 207, 195 | 219, 214 |
| a String by a Float | 470, 463 | 488, 486 |
| a Symbol by a Float (wrong before) | 590, 612 | 601, 640 |

With gcc no read that was right pays. With clang the Array read by an Integer pays two instructions and the others run one to five fewer.

Not here: with a NaN index a boxed Symbol answers nil where it answered "s", and with a Bignum index it still answers "s"; a boxed String answers the same two, and CRuby raises RangeError for both. A String index the program does not append to still answers nil (`g["s"][g["k"]]` with `"k" => "to"`; CRuby: "to"): an earlier arm takes it, and "A String index on a boxed Symbol answers its name's substring" is its cure.

No order with "A boxed Integer's [] reads a Float, nil or Bignum index", which adds its arm on the same line of `sp_poly_index_poly`: the tests are on receivers that exclude each other, and whichever lands later keeps every hunk.

No generated C changes: the function is in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: # (A boxed String's [] reads an appended String or a Float index)
