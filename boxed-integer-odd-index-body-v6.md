<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A boxed Integer read by a boxed index that is no Integer answered bit 0:

```ruby
g = { "n" => 5, "f" => 1.5, "t" => true }
p g["n"][g["f"]]   # 1; CRuby: 0
p g["n"][g["t"]]   # 1; CRuby: no implicit conversion of true into Integer (TypeError)
```

`sp_poly_index_poly` reads one bit of a boxed Integer by an Integer index, and a bit field by an Integer Range. An index of any other kind that no earlier arm takes fell to the last line, which reads offset 0. Such an index is now converted as `Integer#[]` converts it: a Float or a Rational is cut, and `nil`, `true` or an Array is CRuby's TypeError. An index past a word, a Bignum or a Float that large, reads the receiver's sign above every bit and 0 below; a Bignum receiver takes no such Float, CRuby's RangeError.

The fix costs reads that are right on master, with clang only, one to three instructions a loop pass by callgrind: a boxed Array read by a boxed Integer runs 189 and 191, an Integer-keyed boxed Hash read by one 153 and 154 (missed: 140 and 141), a boxed String read by one 437 and 438, and a boxed Integer's bit field read by a Range 140 and 143. With gcc each of them is cheaper here: 203 and 194, 149 and 143 (136 and 130), 431 and 427, 143 and 133. The new test is one line at the end of the function, below the Hash arms and the Integer index's own arm; it asks the receiver's tag and no more, and the conversion is out of line. What it costs is how each compiler then lays out the reads above that line. A boxed Integer's bit read by a boxed Integer runs 137 and 137 with clang, 126 and 124 with gcc; a miss on a Symbol-keyed boxed Hash by a boxed Float key 157 and 157, 150 and 135; a boxed Symbol read by an Integer 532 and 532, 537 and 537.

Of 1,028 programs that read a boxed value of every kind through an index of every kind, 283 are cured and none that was right is lost: 506 are right on master and here, and the other 239 print the same wrong bytes on both.

Not here: a Float Range index still reads bit 0, where CRuby reads a bit field; an object of a user class still reads bit 0, where CRuby asks it `to_int` (the bridge that asks an object its `to_int` leaves out a class held by value, so its refusal is not CRuby's TypeError); a String or a Symbol index raises NoMethodError where CRuby raises TypeError, in another function.

No generated C changes: the functions are in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on Linux (x86_64, gcc 13.3.0, ruby 3.3.6), on master 16bca0896 merged with this branch's commit (4b29b2a1e): the build; `tools/gate.rb check`; the new test in eighteen cells (gcc and clang; the default mode, `--int-overflow=promote` and `--share-strings`; `SPINEL_GC_STRESS` unset, 1 and 2); `tools/cident.sh` against master (all 6,541 corpus programs, optcarrot among them, compile to the same C); and the legs `share-strings-test` and `int-min-test` alone, which pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (not run under CRuby 4.0 here; ruby 3.3.6 with that flag prints `test/boxed_integer_index_not_integer.rb.expected` exactly)
- [x] Values past 2^31 are marked `# spinel: int64` (`test/boxed_integer_index_not_integer.rb` is)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: `tools/cident.sh` finds it byte-identical to master's at 16bca0896)
- [ ] Depends on: # (nothing)
