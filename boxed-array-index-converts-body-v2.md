<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An empty boxed Array read by a boxed Rational raises where it answered nil, and a NaN or a Bignum index answers silently:

```ruby
g = { "e" => [], "a" => [10, "s", :z], "r" => Rational(3, 2), "nan" => 0.0 / 0.0, "big" => 2**70 }
p g["e"][g["r"]]     # no implicit conversion of Rational into Integer (TypeError); CRuby: nil
p g["a"][g["nan"]]   # nil; CRuby: float NaN out of range of integer (RangeError)
p g["a"][g["big"]]   # 10; CRuby: bignum too big to convert into 'long' (RangeError)
```

The fix costs one read that is right on master: a boxed Array read by a boxed Float that fits a word runs 207 instructions a loop pass there and 211 here with clang, 221 and 221 with gcc. That is the range test in front of the cast, which makes a NaN or 1e30 a RangeError where it is a silent nil.

The first line printed nil until the commit "A keyword splat sent to a method without keywords arrives as its last positional, and a boxed array index of another kind raises TypeError". Its arm in `sp_poly_index_poly` is right for a String, a Symbol, an Array or a Hash index, and for a Float that fits a word. It raises TypeError for every other kind too, and a Rational, a Complex and an object with `to_int` are kinds `Array#[]` converts. It casts a Float without a range test, which is undefined for a NaN, an infinity or 1e30: each answers nil. And it leaves a Bignum to the function's last line, which reads element 0.

The index is now converted as `Array#fill`'s offset is (`sp_array_fill_offset_arg`): what has `to_int` answers the element, a Float or a Bignum past a word is CRuby's RangeError, and `true` and `false` are named as CRuby names them. The one Bignum that fits a word, the smallest Integer, is an offset past every Array and answers nil, where master answers the first element. A Float that fits is still cut in line; the rest is out of line, so the reads beside it pay nothing: by callgrind a loop pass of `a[k]` with a boxed Integer `k` runs 203 instructions on master and 202 here with gcc, 191 and 189 with clang, and an Integer-keyed boxed Hash read by one 148 and 145, 158 and 152.

Of 1,056 programs that read a boxed Array of every kind through an index of every kind, 327 are cured and none that was right is lost: 651 are right on master and here, and the other 78 print the same wrong bytes on both.

Not here: a Float Range index is still a TypeError, where CRuby slices; a String Range's TypeError names Range where CRuby names String.

No generated C changes: the functions are in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
