<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A boxed Integer read by a boxed index that is no Integer answered bit 0:

```ruby
g = { "n" => 5, "f" => 1.5, "t" => true }
p g["n"][g["f"]]   # 1; CRuby: 0
p g["n"][g["t"]]   # 1; CRuby: no implicit conversion of true into Integer (TypeError)
```

The fix costs reads that are right on master, with clang only, one to three instructions a loop pass by callgrind: a boxed Integer's bit field read by a Range runs 140 and 143, a boxed Symbol read by a boxed Integer 552 and 555, a boxed Array read by one 189 and 191, a curried Proc called by `[]` 472 and 474, a Proc called by `[]` 111 and 113, an Integer-keyed boxed Hash read by a boxed Integer 153 and 154 (missed: 140 and 141), a String-keyed one missed by it 148 and 149, and a boxed String read by one 437 and 438, by a Range 610 and 611. A boxed String or Symbol read by an Integer reaches the function's last line and so runs the new test itself; the others leave above it and pay for how clang then lays the function out. With gcc none of forty-five loops costs more, and these run 143 and 133, 529 and 525, 203 and 194, 504 and 501, 137 and 130, 149 and 143 (136 and 130), 136 and 128, 431 and 427, 634 and 623. The compiler runs under 0.1% more instructions on a file of 1,000 or of 2,000 reads of a global, by a constant, by a sequence with a call in it, or by one that writes another global, and under 0.01% more on optcarrot.

`sp_poly_index_poly` reads one bit of a boxed Integer by an Integer index, and a bit field by an Integer Range. An index of any other kind that no earlier arm takes fell to the last line, which reads offset 0. Now a Float is cut, a Rational or a Complex with no imaginary part is the Integer it converts to, and `nil`, `true`, `false` or an Array is CRuby's TypeError. An index past a word (a Bignum, or a Float, a Rational or a Complex that large) reads the receiver's sign above every bit and 0 below; a Bignum receiver takes a Bignum so, and for any other index that large raises CRuby's RangeError.

One kind of read keeps the answer it gave. Master reads a bare global, instance variable or class variable after its index ran, a fault of its own with its own cause; where the index assigns the variable, `$x[($x = v; k)]`, the bit is read of the value assigned, and bit 0 of that can be CRuby's bit of the value before. So such a read is emitted as `sp_poly_index_poly_asis`, which keeps the last line as it was, unless its index is proved to leave the variable as it is. Proved are number, Symbol and String literals; reads of variables and of the program's constants; a plain write of a local, or of an instance or class variable of another name; a typed Array read by a typed Integer in a program with no `[]` of its own; and an operator of an Integer or a Float with a number or a boolean in a program with no operator, `coerce` or `method_missing` of its own (a def, an alias, `define_method`). Nothing else is. A write of a global is not, for another name can reach the variable (`alias $y $x`; `$-d` is `$DEBUG`). `nil`, `true` and `false` are not, for a `require` in a statement is replaced by one while its file runs ahead of the statement. A `[]` on a boxed value calls a Proc, and any other call can run a method, a block or a required file that writes the variable. No other generated C changes.

Of 1,028 programs that read a boxed value of every kind through an index of every kind, 283 are cured and none that was right is lost: 510 are right on master and here, and the other 235 print the same wrong bytes on both. Of 1,464 that read a global, an instance variable or a class variable whose index assigns it (in a sequence, through a method called there, in a call) or does not, 312 are cured and none is lost; the 732 whose index is such a sequence print what they print on master.

Not here:
- a bare global, instance variable or class variable that master reads after its index, where the index is not on that list, answers as on master. So bit 0 stays where such an index is a sequence that calls a method or writes a global, where it is `nil`, `true` or `false`, a constant by its path (`M::K`), or an operator on a boxed value: `$x[(s << 1; f)]`, `$x[nil]`;
- a `require` elsewhere in the statement of a read, `p [$x[f], require_relative("w")]`: master runs the file ahead of the whole statement, so where the file assigns `$x` the read is of the value the file left, there and here, and the bit read of it is now the index's, where it was bit 0;
- a value that an earlier read hands on out of order, with gcc: in `t = $w[($w = v; "k")]` master reads `$w` after its index, so `t` holds what `v` holds, there and here, and `t[k]` reads that value by the rules above, where it read bit 0 (a nil index raises TypeError);
- a Float Range, a Class, a Module or an Encoding index still reads bit 0 (CRuby: a bit field, or TypeError);
- an object of a user class still reads bit 0, where CRuby asks it `to_int` (the bridge that asks an object its `to_int` leaves out a class held by value, so its refusal is not CRuby's TypeError);
- a String Range raises a TypeError that names Range where CRuby's names String, and a MatchData raises TypeError where CRuby raises ArgumentError;
- a String or a Symbol index raises NoMethodError where CRuby raises TypeError, in another function;
- a typed Integer read by a boxed Bignum still reads bit 0, and by a boxed Float past a word still raises RangeError;
- in a program where a class defines `[]`, or that uses Set, a boxed Integer that fits a word is read on another path, where an index past a word still answers 0 or raises RangeError;
- an Integer of 2^62 and above is a word here and a Bignum in CRuby, which refuses a Float past a word: it takes the far rule (the receiver's sign above, 0 below), where master answered bit 0.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on Linux (x86_64, gcc 13.3.0, ruby 3.3.6), on master 84f5b5020 with this branch's one commit (f10938e5c): the build; `tools/gate.rb check`; the two new tests in eighteen cells each (gcc and clang; the default mode, `--int-overflow=promote` and `--share-strings`; `SPINEL_GC_STRESS` unset, 1 and 2); `tools/cident.sh` against master (the two new tests' C differs; the other 6,609 corpus programs, optcarrot among them, compile to the same C, and so does every other program that compiles with `--share-strings` (6,600); with `--int-overflow=promote` one more differs, optcarrot, in one line, a read that takes the kept copy, and the other 6,600 compile to the same C); and the legs `share-strings-test` and `int-min-test` alone, which pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (not run under CRuby 4.0 here; ruby 3.3.6 with that flag prints `test/boxed_integer_index_global_alias.rb.expected` as it is, and `test/boxed_integer_index_not_integer.rb.expected` but for 2 lines whose message quotes a name: 3.3 opens the quote with a backquote, 3.4 and later with an apostrophe, as the file has)
- [x] Values past 2^31 are marked `# spinel: int64` (`test/boxed_integer_index_not_integer.rb` is)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: `tools/cident.sh` finds it byte-identical to master's at 84f5b5020. Built with `--int-overflow=promote` one line of it differs, the read `@form[@step = (@step + 1) & 7]`, which takes the kept copy: checksum 59662, 11,747,192,807 instructions by callgrind against master's 11,820,804,386)
- [ ] Depends on: # (nothing)
