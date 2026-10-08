<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A boxed Integer read by a boxed index that is no Integer answered bit 0:

```ruby
g = { "n" => 5, "f" => 1.5, "t" => true }
p g["n"][g["f"]]   # 1; CRuby: 0
p g["n"][g["t"]]   # 1; CRuby: no implicit conversion of true into Integer (TypeError)
```

The fix costs reads that are right on master, with clang only, one to three instructions a loop pass by callgrind: a boxed Integer's bit field read by a Range runs 140 and 143, a boxed Symbol read by a boxed Integer 552 and 555, a boxed Array read by one 189 and 191, a curried Proc called by `[]` 472 and 474, a Proc called by `[]` 111 and 113, an Integer-keyed boxed Hash read by a boxed Integer 153 and 154 (missed: 140 and 141), a String-keyed one missed by it 148 and 149, and a boxed String read by one 437 and 438, by a Range 610 and 611. A boxed String or Symbol read by an Integer reaches the function's last line and so runs the new test itself; the others leave above it and pay for how clang then lays the function out. With gcc none of forty-five loops costs more, and these run 143 and 133, 529 and 525, 203 and 194, 504 and 501, 137 and 130, 149 and 143 (136 and 130), 136 and 128, 431 and 427, 634 and 623.

`sp_poly_index_poly` reads one bit of a boxed Integer by an Integer index, and a bit field by an Integer Range. An index of any other kind that no earlier arm takes fell to the last line, which reads offset 0. Now a Float is cut, a Rational or a Complex with no imaginary part is the Integer it converts to, and `nil`, `true`, `false` or an Array is CRuby's TypeError. An index past a word (a Bignum, or a Float, a Rational or a Complex that large) reads the receiver's sign above every bit and 0 below; a Bignum receiver takes a Bignum so, and for any other index that large raises CRuby's RangeError.

One kind of read keeps the answer it gave: a boxed global, instance variable or class variable whose index, no call itself, assigns that same variable, `$x[($x = v; k)]`, or runs code of the program's that may. Master reads such a variable after its index ran, a fault of its own with its own cause, so bit 0 of the value assigned can be CRuby's bit of the value before. That read is emitted as `sp_poly_index_poly_asis`, which keeps the last line as it was. No other generated C changes.

Of 1,028 programs that read a boxed value of every kind through an index of every kind, 283 are cured and none that was right is lost: 506 are right on master and here, and the other 239 print the same wrong bytes on both. Of 1,464 that read a global, an instance variable or a class variable whose index assigns it (in a sequence, through a method called there, in a call) or does not, 312 are cured and none is lost; the 732 whose index is such a sequence print what they print on master.

Not here:
- a Float Range, a Class, a Module or an Encoding index still reads bit 0 (CRuby: a bit field, or TypeError);
- an object of a user class still reads bit 0, where CRuby asks it `to_int` (the bridge that asks an object its `to_int` leaves out a class held by value, so its refusal is not CRuby's TypeError);
- a String Range raises a TypeError that names Range where CRuby's names String, and a MatchData raises TypeError where CRuby raises ArgumentError;
- a String or a Symbol index raises NoMethodError where CRuby raises TypeError, in another function;
- a typed Integer read by a boxed Bignum still reads bit 0, and by a boxed Float past a word still raises RangeError;
- in a program where a class defines `[]`, or that uses Set, a boxed Integer that fits a word is read on another path, where an index past a word still answers 0 or raises RangeError;
- an Integer of 2^62 and above is a word here and a Bignum in CRuby, which refuses a Float past a word: it answers 0, as before.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on Linux (x86_64, gcc 13.3.0, ruby 3.3.6), on master f6b2744b2 merged with this branch's commit (edf9b7506): the build; `tools/gate.rb check`; the new test in eighteen cells (gcc and clang; the default mode, `--int-overflow=promote` and `--share-strings`; `SPINEL_GC_STRESS` unset, 1 and 2); `tools/cident.sh` against master (the new test's C differs; the other 6,578 corpus programs, optcarrot among them, compile to the same C; so does every other program that compiles with `--int-overflow=promote` (6,570) and with `--share-strings` (6,553)); and the legs `share-strings-test` and `int-min-test` alone, which pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (not run under CRuby 4.0 here; ruby 3.3.6 with that flag prints `test/boxed_integer_index_not_integer.rb.expected` but for 2 lines whose message quotes a name: 3.3 opens the quote with a backquote, 3.4 and later with an apostrophe, as the file has)
- [x] Values past 2^31 are marked `# spinel: int64` (`test/boxed_integer_index_not_integer.rb` is)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: `tools/cident.sh` finds it byte-identical to master's at f6b2744b2)
- [ ] Depends on: # (nothing)
