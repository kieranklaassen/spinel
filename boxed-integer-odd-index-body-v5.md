<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A boxed Integer read by a boxed index that is no Integer answered bit 0:

```ruby
g = { "n" => 5, "f" => 1.5, "t" => true }
p g["n"][g["f"]]   # 1; CRuby: 0
p g["n"][g["t"]]   # 1; CRuby: no implicit conversion of true into Integer (TypeError)
```

`sp_poly_index_poly` reads one bit of a boxed Integer by an Integer index, and a bit field by an Integer Range. An index of any other kind that no earlier arm takes fell to the last line, which reads offset 0. Such an index is now converted as `Integer#[]` converts it: a Float is cut, an object answers `to_int`, and `nil`, `true` or an Array is CRuby's TypeError. An index past a word, a Bignum or a Float that large, reads the receiver's sign above every bit and 0 below; a Bignum receiver takes no such Float, CRuby's RangeError.

The new arm stands on the function's last line, below the Hash arms: a Hash's read never passes it, and a read that does reach that line costs what it did. By callgrind a miss on a Symbol-keyed boxed Hash by a boxed Float key runs 150 instructions a loop pass on master and 148 here with gcc, 168 and 167 with clang; a boxed Symbol read by an Integer runs 537 and 537, 533 and 533; a loop of both reads 691 and 689, 710 and 709.

Of 1,028 programs that read a boxed value of every kind through an index of every kind, 314 are cured and none that was right is lost: 504 are right on master and here, and the other 210 print the same wrong bytes on both.

Not here: a Float Range index still reads bit 0, where CRuby reads a bit field; a String or a Symbol index raises NoMethodError where CRuby raises TypeError, in another function.

No order with "A boxed String's [] reads an appended String or a Float index" and "A boxed Symbol's [] reads a Float or appended String index", which add their arms on the same line of `sp_poly_index_poly`: the three tests are on receivers that exclude each other, and whichever lands later keeps every hunk.

No generated C changes: the functions are in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
