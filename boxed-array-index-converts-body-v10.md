<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A boxed Array read by a boxed index that is a Rational or a Complex raises TypeError, and by a Bignum reads element 0:

```ruby
a = [[10, "s", :z], Rational(3, 2), 2**70]
h = a[0]
p h[a[1]]   # no implicit conversion of Rational into Integer (TypeError); CRuby: "s"
p h[a[2]]   # 10; CRuby: bignum too big to convert into 'long' (RangeError)
```

The arm `sp_poly_index_poly` has for a boxed Array's index that is no Integer reads a Float and raises TypeError for every other kind, so a Rational and a Complex, which `Array#[]` converts, stop there; and it leaves a Bignum to the last line, which reads element 0.

`sp_poly_index_poly_conv` converts those as `Array#fill`'s offset is converted (`sp_array_fill_offset_arg`): a Rational or a Complex answers the element, a Bignum past a word is CRuby's RangeError, and `true` and `false` are named as CRuby names them. That is the function a read takes where it is proved to answer the same whichever of its receiver and its index runs first; the pull request this stands on adds it, and the proof. Those are the kinds it lists (`sp_poly_ary_index_other`); a Float is read by the two lines that read it before, and every other kind keeps the TypeError the arm gave it. A Complex whose real part is past a word converts to a Bignum, so it is that RangeError too, raised before the conversion: `sp_complex_to_int` casts the real part with no range test. The one Bignum that fits a word, the smallest Integer, is an offset past every Array and answers nil.

The listed kinds are read out of line, so an Integer or a Float index runs the lines it ran. By callgrind a loop pass of `a[k]` with a boxed Integer `k` runs 229 and 229 instructions on the commit this stands on and here with gcc, 216 and 216 with clang, and with a boxed Float `k` 245 and 243 and 235 and 229. Of fifty-eight loops of boxed reads none costs more with gcc and two run one instruction a pass more with clang, by how the function is laid out anew around the arm: a boxed Integer's bit field read by a boxed Integer Range 168 and 168 with gcc, 173 and 174 with clang; a boxed String read by a boxed Integer Range 611 and 611 with gcc, 602 and 603 with clang. Those are our loops; in review, on the earlier base, another loop of the plain read, `a[k]` with a boxed Integer `k`, moved by one instruction with clang (80 and 81) and not with gcc (95 and 95). The listed kinds' arm is out of line and no test is added on the path of an Integer or a Float index, so this is how the C compiler lays the function out around the arm.

`sp_poly_index_poly` keeps its arm, and so does every read that is not proved. A bare global, instance variable or class variable can be read after its index ran; where the index assigned it an Array, the element 0 a Bignum read there can be CRuby's answer of the value before (a Hash read by a Bignum is nil). Nor is a read proved in a program that reopens a builtin exception class (`any_exc_reopen`, asked by the pull request this stands on): CRuby runs an `initialize` such a class gives for the RangeError raised here, and a rescue can print what element 0 printed; a `raise` the program writes runs it, a raise by the runtime does not.

No generated C changes in this commit: the functions are in `lib/spinel_rt.h`, and the read that takes the new one is emitted by the pull request this stands on. Against master `lib/spinel_rt.h` only gains lines; the two lines this commit changes are in the copy that pull request adds.

Of 1,023 programs that read a boxed Array of every kind through an index of every kind, 222 name no read the new function takes and are the same program on both. Of the other 801, 150 are cured and none that was right is lost: 603 are right on the commit this stands on and here, and 48 print the same wrong bytes on both.

Not here, each as on master:

- a Float Range index is still a TypeError, where CRuby slices, and a String Range's TypeError names Range where CRuby's names String;
- an object of the program's that answers `to_int` is still the TypeError that names its class, where CRuby answers the element: no read is proved in a program with a def or a Symbol of that name;
- a read that is not proved (the list is the other pull request's: a receiver that is a Hash's element or a method's value; a bare global, instance variable or class variable whose index may assign it; an index that holds `nil`, `true` or `false`; a program that may load a file the compiler did not read or in which the analysis decided a test for this engine, that may have given a class a method the read asks, or that reopens a builtin exception class): a Rational there still raises TypeError and a Bignum still reads element 0;
- `Array#fill` reads its offset through the same cast, so `[1, 2, 3].fill(0, c)` with `c = Complex(1e30, 0)` in a boxed slot still fills from the first element, where CRuby raises RangeError;
- a value that master hands on out of order: in `t = $w[begin; $w = v; "k"; end]` master reads `$w` after its index, so `t` holds what `v` holds, there and here, and where that is an Array `t[k]` reads it by the rules above: a Bignum raises RangeError, where element 0 could be CRuby's answer of the value before, and a Rational or a Complex answers that Array's element, where master raised TypeError (CRuby reads the value before: for a Hash, nil).

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on Linux (x86_64, gcc 13.3.0, ruby 3.3.6), on master 55aa88e97 with the commit this depends on (d749aedf8) and this branch's commit (9318dc833): the build; `tools/gate.rb check` and `tools/gate.rb check-range` over this commit (each exits 0 and warns that it found no Ruby 4.0, so the `.expected` files were not checked against CRuby by it); the two new tests and the Integer commit's ten in eighteen cells each (gcc and clang; the default mode, `--int-overflow=promote` and `--share-strings`; `SPINEL_GC_STRESS` unset, 1 and 2); the compiler binary against the one built from the commit this stands on (this commit changes no file of `src/`, and the two binaries are the same bytes but for the build id and the revision stamps, so every program compiles to the same C in every mode and `tools/cident.sh` has nothing to compare); and the legs `share-strings-test` and `int-min-test` alone, which pass. With the pull request this depends on and the one that stands on it, the two new tests and the eleven of those two also print their `.expected` under `--int-overflow=wrap`, and with clang at `-O 0` under `wrap` and `promote`, the two lanes master runs on a push. Master has moved since: merged with 5705e9069 (master at 21:45 UTC on 10 October) the tree builds, and the tests, the two overflow lanes and the example above answer the same.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (not run under CRuby 4.0 here; ruby 3.3.6 with that flag prints `test/boxed_array_index_reopened_error.rb.expected` as it is, and `test/boxed_array_index_converts.rb.expected` but for 7 lines whose message quotes a name: 3.3 opens the quote with a backquote, 3.4 and later with an apostrophe, as the file has)
- [x] Values past 2^31 are marked `# spinel: int64` (both new tests are)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: this commit changes no file of `src/`, and the compiler it builds is the binary of the commit this stands on but for its build stamps, so optcarrot compiles to the same C)
- [x] Depends on: # (the pull request "A boxed Integer's [] reads a Rational, nil or Bignum index": this is one commit on top of it)
