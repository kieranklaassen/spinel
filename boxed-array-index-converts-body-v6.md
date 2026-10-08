<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An empty boxed Array read by a boxed Rational raises where it answered nil, and a NaN or a Bignum index answers silently:

```ruby
g = { "e" => [], "a" => [10, "s", :z], "r" => Rational(3, 2), "nan" => 0.0 / 0.0, "big" => 2**70 }
p g["e"][g["r"]]     # no implicit conversion of Rational into Integer (TypeError); CRuby: nil
p g["a"][g["nan"]]   # nil; CRuby: float NaN out of range of integer (RangeError)
p g["a"][g["big"]]   # 10; CRuby: bignum too big to convert into 'long' (RangeError)
```

The fix costs two reads that are right on master, one with each compiler. With gcc a boxed Array read by a boxed Float that fits a word runs 219 instructions a loop pass there and 223 here (207 and 205 with clang): that is the range test in front of the cast, which makes a NaN or 1e30 a RangeError where it is a silent nil. With clang a boxed String read by a boxed Integer runs 437 and 438 (431 and 431 with gcc): that read is not this arm's, the function is laid out anew around it.

The first line printed nil until the commit "A keyword splat sent to a method without keywords arrives as its last positional, and a boxed array index of another kind raises TypeError". Its arm in `sp_poly_index_poly` is right for a String, a Symbol, an Array or a Hash index, and for a Float that fits a word. It raises TypeError for every other kind too, and a Rational, a Complex and an object with `to_int` are kinds `Array#[]` converts. It casts a Float without a range test, which is undefined for a NaN, an infinity or 1e30: each answers nil. And it leaves a Bignum to the function's last line, which reads element 0.

The index is now converted as `Array#fill`'s offset is (`sp_array_fill_offset_arg`): what has `to_int` answers the element, a Float or a Bignum past a word is CRuby's RangeError, and `true` and `false` are named as CRuby names them. A Complex whose real part is past a word converts to a Bignum, so it is that RangeError too, where master raises TypeError; it is raised before the conversion, because `sp_complex_to_int` casts the real part with no range test and the cast is no offset. The one Bignum that fits a word, the smallest Integer, is an offset past every Array and answers nil, where master answers the first element. A Float that fits is still cut in line; the rest is out of line, so an Integer index pays nothing: by callgrind a loop pass of `a[k]` with a boxed Integer `k` runs 203 instructions on master and 203 here with gcc, 189 and 188 with clang, and an Integer-keyed boxed Hash read by one 149 and 149, 153 and 147. Of forty loops through the function no other costs more with either compiler.

Of 1,056 programs that read a boxed Array of every kind through an index of every kind, 327 are cured and none that was right is lost: 651 are right on master and here, and the other 78 print the same wrong bytes on both.

Not here: a Float Range index is still a TypeError, where CRuby slices; a String Range's TypeError names Range where CRuby names String; an object whose `to_int` raises, answers no Integer that fits a word (a String, nil, a Float, a Bignum) or comes from `method_missing` is still the TypeError that names its class, where CRuby raises `to_int`'s own error, names what it gave, raises RangeError for the Bignum or answers the element; `Array#fill` reads its offset through the same cast, so `[1, 2, 3].fill(0, c)` with `c = Complex(1e30, 0)` in a boxed slot still fills from the first element, where CRuby raises RangeError.

No generated C changes: the functions are in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on Linux (x86_64, gcc 13.3.0, ruby 3.3.6), on master 16bca0896 merged with this branch's commit (c39c6e174): the build; `tools/gate.rb check`; the new test in eighteen cells (gcc and clang; the default mode, `--int-overflow=promote` and `--share-strings`; `SPINEL_GC_STRESS` unset, 1 and 2); `tools/cident.sh` against master (all 6,541 corpus programs, optcarrot among them, compile to the same C); and the legs `share-strings-test` and `int-min-test` alone, which pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (not run under CRuby 4.0 here; ruby 3.3.6 with that flag prints `test/boxed_array_index_converts.rb.expected` but for 7 lines whose message quotes a name: 3.3 opens the quote with a backquote, 3.4 and later with an apostrophe, as the file has)
- [x] Values past 2^31 are marked `# spinel: int64` (`test/boxed_array_index_converts.rb` is)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: `tools/cident.sh` finds it byte-identical to master's at 16bca0896)
- [ ] Depends on: # (nothing)
