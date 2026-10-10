<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Fix with a cost in a program that holds an appended String: 1 to 8 instructions on a membership call of a String Range with a boxed argument (the table below). A program that holds none compiles to the same C, with `--share-strings` and without.

```ruby
h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("aa".."az")
p r.cover?(h["k"])
p r.include?(h["k"])
p r.member?(h["k"])
```

prints `false` three times (`spinel diff`: output-diff), with and without `--share-strings`. CRuby prints `true` three times.

A String something appends to is held as its shared handle, and a boxed read of it carries the handle (`SP_BUILTIN_STRBUF`), not a plain boxed String. `emit_range_call` wrote the membership of a typed String Range with a boxed argument as `_a.tag == SP_TAG_STR && sp_srange_cover(...)`, so the handle was no member. A Hash with one element the program appends to holds every String it was built with as a handle: with `"p" => "ab"` beside `"k"`, `r.cover?(h["p"])` was false too.

The handle is now asked after the plain String: `include?` walks to its text, `cover?` compares it by its bytes, out of line. A nil stored among handles is a box with no handle and is no member.

The arm is written only where a box tagged as a handle is known to hold one. `program_strbuf_boxes` answers that once for the program, before any C is written. Master's C stays, byte for byte, in a program that holds no handle, built with `--share-strings` or without; in one that stores, where a handle is wanted, the String of a method call on an object of the program's that is no read of a handle's slot through a receiver (the scan does not follow what such a call renders, so it does not say what that box holds); and in a program that has, or may have, a method of the call's name or a `<=>`, an `==` or a `succ` of its own, in any class: this call does not ask them, before or after.

"May have" is asked of two tables. A `def` in the builtin's class is in the class table. The rest is `an_prog_never_gives`, the analysis's walk of the program as written (src/analyze.c). It reads the program ahead of every rewrite and of the arm a test of the engine drops: no `def` and no Symbol of the name anywhere, and no site where a method is named, made, mixed in or loaded by something the text does not spell. So `alias <=> index`, `def lo.<=>`, a `String.define_method(:<=>) { }` under a `rescue`, a `send(name)`, an `eval` and a file the compiler did not read leave master's C. So does `class String; prepend Kernel; end`: Kernel's `<=>` answers nil for two Strings that differ, and no text of the program's holds it.

The names asked are the ones CRuby asks on these calls: the call's own on Range (`cover?`, `include?`, `member?`; `===` for the change above this one) and `<=>`, `==` and `succ` on String, seven in all; `eql?` is not one. The walk does not ask where a `def` lands, so a `def ==` in a class of the program's own leaves master's C too, and so does the Symbol `:==` written anywhere: the three calls answer `false` there, as on master. Of the 6,824 programs of test/, benchmark/ and the packages' tests the two tables answer "may" for 1,238, for 1,144 of them by a site. A package is the program's text to the walk: each of the nine tried (set, csv, uri, bigdecimal, pathname, stringio, json, strscan and Gem::Version) leaves master's C.

Cost in instructions a call, gcc 13.3 / clang 18.1, callgrind over 300,000 turns of `n += 1 if r.cover?(x)`, in a `while` loop and in a `300000.times` block, with `r = ("aa".."az")` and `x` read once from `["ab", 1]`. "With a handle" puts `hh = {"k" => "x".dup, "n" => 1}; hh["k"] << "y"` above the loop.

| boxed argument | no handle in the program | with a handle, `while` | with a handle, block |
|---|---|---|---|
| `cover?`, a String in a local | 0 / 0 | +4 / +2 | +5 / +2 |
| `cover?`, a String read from the Array each turn | 0 / 0 | +6 / +2 | +8 / +2 |
| `cover?`, an Integer | 0 / 0 | +6 / +4 | +6 / +4 |
| `include?`, a String (`"aa".."ad"`) | 0 / 0 | +3 / +1 | +4 / +1 |

Compiling such a call runs 31,100 to 32,000 more instructions, 2.2% over 1,000 of them, 2.3% over 2,000 (callgrind over `spinel -c --no-line-map`, the compiler alone, against master: 1,446,707,095 for 1,415,569,541 and 2,887,871,144 for 2,823,899,830): the arm, and in it 920 a call for the eight questions, each a lookup in a table the analysis built. A program without such a call does not ask: compiling optcarrot runs 8,283,902,539 instructions for 8,283,643,098, the walk for handles, and its C is the same.

`make cident` against master: the C of 6823 programs is identical and of 1 differs, this change's test. With `--share-strings` 6822 are identical, the same 1 differs, and both builds refuse 1, test/string_plain_mutator_result_kept.rb (named in test/share/known-failures.txt).

Not here: a program that has or may have a method named `cover?`, `include?`, `member?`, `<=>`, `==` or `succ` of its own, in any class and by any road, is left as master has it, and that takes in a program that mixes in a module, its own too, and one that requires a package: of the nine tried, set, csv, uri, bigdecimal and pathname by their own Ruby, which the walk reads as the program's text, and stringio, json, strscan and `Gem::Version` because the compiler does not prove it read every file; a String stored from a method call the scan does not follow (`{"k" => box.text}` beside an appended String, without `--share-strings`) still answers `false`, since that program keeps master's C, and so does one stored from a reader called without a receiver (`{"k" => name}` in a method of its class, with `--share-strings`); `cover?` of a plain String still compares up to its first NUL; a String Range the call does not see as typed (read out of an Array or a Hash, or a "Range or nil" local called with `&.`) and `r.method(:cover?).call(x)` still answer false for the handle; `===` and `case`/`when` of a String Range with a boxed value are their own change.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here before that, on this commit over master `4689b503c791` (Linux x86-64, gcc 13.3 and clang 18.1, CRuby 3.3.6): the build from nothing, the thirteen tests at five collector settings with both compilers, with and without `--share-strings`, `tools/gate.rb check`, `make gc-stress-test`, `make share-strings-test`, `make int-min-test`, `make cident` against master, and the figures above, call counts and compile counts alike.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: nothing (pull requests 8114 and 8168, which it stood on, are merged)
