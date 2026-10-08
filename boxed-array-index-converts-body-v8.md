<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An empty boxed Array read by a boxed Rational raises where it answered nil, and a NaN or a Bignum index answers silently:

```ruby
g = { "e" => [], "a" => [10, "s", :z], "r" => Rational(3, 2), "nan" => 0.0 / 0.0, "big" => 2**70 }
p g["e"][g["r"]]     # no implicit conversion of Rational into Integer (TypeError); CRuby: nil
p g["a"][g["nan"]]   # nil; CRuby: float NaN out of range of integer (RangeError)
p g["a"][g["big"]]   # 10; CRuby: bignum too big to convert into 'long' (RangeError)
```

The fix costs reads that are right without it. By callgrind, against the commit this stands on: with gcc a boxed Array read by a boxed Float that fits a word runs 204 instructions a loop pass there and 208 here (205 and 204 with clang): that is the range test in front of the cast, which makes a NaN or 1e30 a RangeError where it is a silent nil. With clang four reads that are not this arm's pay one or two for how the function is laid out anew around it: a boxed String read by a boxed Integer runs 438 and 440, a boxed Integer's bit read by one 137 and 138, a boxed Bignum's 1,933 and 1,934, and a bit field read by a Range 143 and 144 (with gcc 427 and 427, 124 and 124, 1,928 and 1,928, 133 and 133).

The first line printed nil until the commit "A keyword splat sent to a method without keywords arrives as its last positional, and a boxed array index of another kind raises TypeError". Its arm in `sp_poly_index_poly` is right for a String, a Symbol, an Array or a Hash index, and for a Float that fits a word. It raises TypeError for every other kind too, and a Rational, a Complex and an object with `to_int` are kinds `Array#[]` converts. It casts a Float without a range test, which is undefined for a NaN, an infinity or 1e30: each answers nil. And it leaves a Bignum to the function's last line, which reads element 0.

The index is now converted as `Array#fill`'s offset is (`sp_array_fill_offset_arg`): what has `to_int` answers the element, a Float or a Bignum past a word is CRuby's RangeError, and `true` and `false` are named as CRuby names them. A Complex whose real part is past a word converts to a Bignum, so it is that RangeError too, where master raises TypeError; it is raised before the conversion, because `sp_complex_to_int` casts the real part with no range test and the cast is no offset. The one Bignum that fits a word, the smallest Integer, is an offset past every Array and answers nil, where master answers the first element. A Float that fits is still cut in line; the rest is out of line, so an Integer index pays nothing: a loop pass of `a[k]` with a boxed Integer `k` runs 194 instructions there and 194 here with gcc, 191 and 191 with clang, and an Integer-keyed boxed Hash read by one 143 and 143, 154 and 145. Of forty loops through the function no other costs more with either compiler.

Of 1,056 programs that read a boxed Array of every kind through an index of every kind, 327 are cured and none that was right is lost: 669 are right there and here, and the other 60 print the same wrong bytes on both.

Not here: a Float Range index is still a TypeError, where CRuby slices; a String Range's TypeError names Range where CRuby names String; an object whose `to_int` raises, answers no Integer that fits a word (a String, nil, a Float, a Bignum) or comes from `method_missing` is still the TypeError that names its class, where CRuby raises `to_int`'s own error, names what it gave, raises RangeError for the Bignum or answers the element; `Array#fill` reads its offset through the same cast, so `[1, 2, 3].fill(0, c)` with `c = Complex(1e30, 0)` in a boxed slot still fills from the first element, where CRuby raises RangeError; a bare global, instance variable or class variable whose index may run code of the program's that writes it is read after its index, and such a read is left as master has it: a Rational there still raises TypeError, a NaN or 1e30 still answers nil and a Bignum still reads element 0, because the nil can be CRuby's answer of the value before.

No generated C changes in this commit: the functions are in `lib/spinel_rt.h`, and the kept read is emitted by the commit this stands on.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on Linux (x86_64, gcc 13.3.0, ruby 3.3.6), on master 84f5b5020 with the commit this depends on (e708f3cf0) and this branch's commit (067f1037b): the build; `tools/gate.rb check`; the new test and the other commit's in eighteen cells each (gcc and clang; the default mode, `--int-overflow=promote` and `--share-strings`; `SPINEL_GC_STRESS` unset, 1 and 2); `tools/cident.sh` against master (the C of the two tests differs, by the kept read's name; the other 6,609 corpus programs, optcarrot among them, compile to the same C; so does every other program that compiles with `--int-overflow=promote` (6,601) and with `--share-strings` (6,600)); and the legs `share-strings-test` and `int-min-test` alone, which pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (not run under CRuby 4.0 here; ruby 3.3.6 with that flag prints `test/boxed_array_index_converts.rb.expected` but for 7 lines whose message quotes a name: 3.3 opens the quote with a backquote, 3.4 and later with an apostrophe, as the file has)
- [x] Values past 2^31 are marked `# spinel: int64` (`test/boxed_array_index_converts.rb` is)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: `tools/cident.sh` finds it byte-identical to master's at 84f5b5020)
- [ ] Depends on: # (the pull request "A boxed Integer's [] reads a Float, nil or Bignum index": this is one commit on top of it)
