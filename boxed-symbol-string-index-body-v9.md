<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A String as the index of a boxed Symbol answers nil where CRuby answers the substring:

```ruby
def pick(n) = n > 0 ? {a: 1} : :stone
s = pick(0)
p s["ton"]   # nil; CRuby: "ton"
```

`Symbol#[]` is `String#[]` on the Symbol's name. `sp_poly_get_str` answers the substring for a String and for a shared String, and nil for a Symbol with every other value that is no object. `sp_poly_get_str_conv` is that function with one line changed: a Symbol answers the substring its name holds, with a copy of the index, for CRuby's answer is a new String, never the index itself. An index that is not whole characters is nil though the name holds its bytes (`"\xC3"` into `:"héllo"`), as CRuby's search refuses it.

`sp_poly_get_str` is as it was, and so is every caller of it but two: a read by a typed String that is proved to answer the same whichever of its receiver and its index runs first (`index_order_unproved`, which the pull request "A boxed Integer's [] reads a Rational, nil or Bignum index" gives), and `sp_poly_index_poly_conv`, which such a read by a boxed String takes. A bare global, instance variable or class variable can be read after its index ran; where the index may have assigned it, `$x[k.tap { $x = v }]`, the nil a Symbol gave can be CRuby's answer of the value before.

The cure costs a read that is right without it: a boxed Symbol read by a String its name does not hold. By callgrind, against the commit this stands on: it answered nil without looking at the name, 23 instructions a loop pass with gcc and 30 with clang; a proved read now looks, 98 and 104 (105 and 112 when the index starts as the name does, 133 and 136 when it is longer than the name). The look goes through the name, so it grows with it: 371 and 378 for a name of 43 letters, 714 and 721 where every letter of the name is a false start (`"aac"` in thirty-one a's and a b). The same three misses on a boxed String cost 94, 314 and 1,124 there with gcc (99, 318 and 1,099 with clang) and one instruction more here with both: the String's arm is the same lines, in a function the compilers lay out another way. Of the other forty-three loops of boxed reads six cost half an instruction a pass more with either compiler: a boxed Symbol-keyed Hash read by a Symbol and a String-keyed one read by a String 277 and 277 with gcc, 258 and 259 with clang; a boxed Struct read by a Symbol and by a String 2,415 and 2,415 with gcc, 2,356 and 2,359 with clang; a String-keyed boxed Hash read by a String 167 and 168 with gcc, 171 and 173 with clang; a boxed String read by a String 185 and 183 with gcc, 187 and 188 with clang; a Symbol-keyed boxed Hash (or a Symbol) missed by a String 62 and 60 with gcc, 81 and 82 with clang; a boxed Struct's member read by a boxed Integer 2,221 and 2,224 with gcc, 2,208 and 2,208 with clang. A read that is not proved runs what it ran: five loops of such reads count the same there and here with both.

A read that is not proved is the C of the commit this stands on. The generated C changes by the new name and nothing else: with `sp_poly_get_str_conv` mapped back to `sp_poly_get_str`, each of the 34 corpus programs whose C differs, the new test among them, is that commit's C byte for byte (87 lines). `sp_poly_get_str_conv` repeats the 38 lines of `sp_poly_get_str`, so a later change to that read belongs in both. Against master `lib/spinel_rt.h` only gains lines; the lines this commit changes are in the copy the first pull request adds.

Of 992 reads, a boxed Symbol of eight names, six of them with characters of two to four bytes, read by 31 Strings in four forms, 17 of the Strings not whole characters, each run on the commit this stands on and here, 84 answered nil and print CRuby's line here, 908 are right there and here. And of 955 reads under nineteen kinds of receiver, by forty-nine indexes that assign the receiver another Symbol or do not (a block run in line, a `case`, a `begin`, a sequence, a rescue, a loop) and twenty-four whose receiver assigns the index's variable, 44 build on neither and the other 911 print the line of the commit this stands on. None that was right is lost.

Not here, each as on master unless said:

- `a = [s[k], s[k]]; a[0] << "1"` prints `["ton", "ton"]`, as an Array of two boxed Strings does on master (CRuby: `["ton1", "ton"]`);
- a binary index with a byte past ASCII, into a name with any character past ASCII whether it holds that byte or not (`:"héllo"["é".b]`, `:"日本語"["é".b]`), is nil as it was, where CRuby raises Encoding::CompatibilityError; one the program appended to an empty String (`k = +""; k << "\xC3\xA9".b`), which master takes for UTF-8, answers the substring where CRuby raises the same error;
- a String, boxed or not, answers an index that is not whole characters when it holds the bytes (`"héllo"["\xC3"]` is `"\xC3"`; CRuby: nil), on master and here: the Symbol does not follow its name there;
- a read that is not proved (the list is the other pull request's: a receiver that is a Hash's element or a method's value; a bare global, instance variable or class variable whose index may assign it; an index that holds `nil`, `true` or `false`; a program that may load a file the compiler did not read or in which the analysis decided a test for this engine, that may have given a class a method the read asks, or that reopens a builtin exception class) still answers nil: `g["a"][g["k"]]`, `cur[k]`, `$x[(y << "1"; k)]`;
- the cured answer stored where master typed an Array for Integers: `xs = [0, 0]; xs[0] = s[k]` raises TypeError, where master stored the nil and printed `[nil, 0]` (CRuby: `["ton", 0]`). That is master's line for any boxed String stored there (`xs[0] = g["t"]` with `g` a Hash of a String and an Integer);
- a value that master hands on out of order: in `t = $w[begin; $w = v; "k"; end]` master reads `$w` after its index, so `t` holds what `v` holds, there and here, and where that is a Symbol `t["cd"]` answers its substring, where the nil could be CRuby's answer of the value before.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on Linux (x86_64, gcc 13.3.0, ruby 3.3.6), on master 55aa88e97 with the two commits this depends on (d749aedf8, 9318dc833) and this branch's commit (87f3d808a): the build; `tools/gate.rb check` and `tools/gate.rb check-range` over this commit (each exits 0 and warns that it found no Ruby 4.0, so the `.expected` files were not checked against CRuby by it); the new test and the two other commits' twelve in eighteen cells each (gcc and clang; the default mode, `--int-overflow=promote` and `--share-strings`; `SPINEL_GC_STRESS` unset, 1 and 2); `tools/cident.sh` against the commit this stands on (34 programs' C differs, the new test and 33 others, each by the new function's name at a proved read and nothing else; the other 6,847 corpus programs, optcarrot among them, compile to the same C. With `--share-strings` 30 differ so and the other 6,850 that compile are the same; with `--int-overflow=promote` 34 and 6,847); and the legs `share-strings-test` and `int-min-test` alone, which pass. The new test and the other twelve also print their `.expected` under `--int-overflow=wrap`, and with clang at `-O 0` under `wrap` and `promote`, the two lanes master runs on a push. Master has moved since: merged with 5705e9069 (master at 21:45 UTC on 10 October) the tree builds, and the tests, the two overflow lanes and the example above answer the same.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (not run under CRuby 4.0 here; ruby 3.3.6 with that flag prints `test/boxed_symbol_index_string.rb.expected` exactly)
- [x] Values past 2^31 are marked `# spinel: int64` (the new test has none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change, in the default mode, with `--int-overflow=promote` or with `--share-strings`: `tools/cident.sh` finds it byte-identical to the C of the commit this stands on)
- [x] Depends on: # (the pull request "A boxed Array converts an index that is no Integer as Array#[] does", which depends on "A boxed Integer's [] reads a Rational, nil or Bignum index": this is one commit on top of the two)
