<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A String as the index of a boxed Symbol answered nil where CRuby answers the substring:

```ruby
def pick(n) = n > 0 ? {a: 1} : :stone
s = pick(0)
p s["ton"]   # nil; CRuby: "ton"
```

The fix costs a read that is right without it: a boxed Symbol read by a String its name does not hold. By callgrind, against the commit this stands on: it answered nil without looking at the name, 23 instructions a loop pass with gcc and 30 with clang; it now looks, 98 and 104 (105 and 112 when the index starts as the name does, 133 and 136 when it is longer than the name). The look goes through the name, so it grows with it: 371 and 378 for a name of 43 letters, 714 and 721 where every letter of the name is a false start (`"aac"` in thirty-one a's and a b). The same three misses on a boxed String cost 94, 314 and 1,124 there with gcc (99, 318 and 1,099 with clang) and one instruction more here with both: the String's arm is not touched, the compilers lay the function out anew around it.

`Symbol#[]` is `String#[]` on the Symbol's name. `sp_poly_get_str` answers the substring for a String and for a shared String, and answered nil for a Symbol with every other value that is no object. A Symbol now answers the substring its name holds, for a String the program appends to as well, with a copy of the index: CRuby's answer is a new String, never the index itself. An index that is not whole characters is nil though the name holds its bytes (`"\xC3"` into `:"héllo"`): CRuby's search refuses one.

The work is out of line, behind the test for a value that is no object which the function already makes, so a Hash's read meets no new test. An index the name does not hold is the read a value that is a Hash elsewhere makes, so it is answered before the search and the copy. A loop reading `h[:a]` and `g["a"]` from boxed Hashes runs 223 instructions a pass there and 226 here with gcc, 210 and 210 with clang; one String read of a String-keyed boxed Hash 138 and 138, 151 and 151; two of them 325 and 323, 302 and 300. The other reads through the two functions move by one to three instructions either way with the new layout: of forty loops, the Symbol's and the three String misses aside, two cost more with gcc (that loop of two Hash reads, 223 and 226, a boxed Struct read by a Symbol and by a String, 2,359 and 2,360) and six cost less; two cost more with clang (a boxed String read by a String it holds, 187 and 188, a Symbol-keyed boxed Hash missed by a String, 81 and 82) and four cost less.

Of 83 programs that reach the new arm, 43 are cured and 40 are right there and here. Of 992 more reads, a boxed Symbol of eight names, six of them with characters of two to four bytes, read by 31 Strings in four forms, 17 of the Strings not whole characters, 84 answered nil and print CRuby's line here; the other 908 are right there and here. None that was right is lost.

Not here: a Symbol index on the boxed Symbol (`s[:a]`) still answers nil, where CRuby raises TypeError; `a = [s[k], s[k]]; a[0] << "1"` prints `["ton", "ton"]`, as an Array of two boxed Strings does on master (CRuby: `["ton1", "ton"]`). A binary index with a byte past ASCII that the name holds (`s["é".b]`) is nil as it was, where CRuby raises Encoding::CompatibilityError; one the program appended to an empty String (`k = +""; k << "\xC3\xA9".b`), which master takes for UTF-8, answers the substring where CRuby raises the same error. A String, boxed or not, answers an index that is not whole characters when it holds the bytes (`"héllo"["\xC3"]` is `"\xC3"`; CRuby: nil), on master and here: the Symbol does not follow its name there. And a Symbol in a bare global, instance variable or class variable whose index is not proved to leave the variable as it is still answers nil, as on master, where CRuby may answer the substring.

One kind of read keeps its nil. Master reads a bare global, instance variable or class variable after its index ran; where the index assigns the variable, `$x[($x = v; k)]`, the Symbol read is the value assigned, and the nil it gave can be CRuby's answer of the value before. So such a read is emitted as `sp_poly_get_str_asis`, which answers a Symbol nil as before, and `sp_poly_index_poly_asis` does the same for a boxed String index. Which reads those are is decided by the test the pull request "A boxed Integer's [] reads a Float, nil or Bignum index" adds for the boxed read (`index_reads_assigned_slot`): every one whose index is not proved to leave the variable as it is. No other generated C changes: the functions are in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on Linux (x86_64, gcc 13.3.0, ruby 3.3.6), on master 84f5b5020 with the two commits this depends on (e708f3cf0, 067f1037b) and this branch's commit (87f197fc4): the build; `tools/gate.rb check`; the new test and the two other commits' in eighteen cells each (gcc and clang; the default mode, `--int-overflow=promote` and `--share-strings`; `SPINEL_GC_STRESS` unset, 1 and 2); `tools/cident.sh` against master (the C of the three tests differs, by the kept reads' names; the other 6,609 corpus programs, optcarrot among them, compile to the same C; so does every other program that compiles with `--int-overflow=promote` (6,601) and with `--share-strings` (6,600)); and the legs `share-strings-test` and `int-min-test` alone, which pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (not run under CRuby 4.0 here; ruby 3.3.6 with that flag prints `test/boxed_symbol_index_string.rb.expected` exactly)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: `tools/cident.sh` finds it byte-identical to master's at 84f5b5020)
- [ ] Depends on: # (the pull request "A boxed Array index converts the way Array#[] does", which depends on "A boxed Integer's [] reads a Float, nil or Bignum index": this is one commit on top of the two)
