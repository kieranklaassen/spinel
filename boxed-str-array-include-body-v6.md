<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Fix with a cost in a program that holds an appended String: up to 4 instructions a turn of two `include?` calls on a boxed String Array with a boxed argument (the table below). A program that holds none compiles to the same C, with `--share-strings` and without.

```ruby
h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
bw = [["ab", "cd"], 1][0]
p bw.include?(h["k"])
p bw.member?(h["k"])
```

prints `false` twice (`spinel diff`: output-diff), with and without `--share-strings`. CRuby prints `true` twice.

A String something appends to is held as its shared handle, and a boxed read of it carries the handle (`SP_BUILTIN_STRBUF`), not a plain boxed String. `include?` of a boxed receiver is a switch over what the box holds (`emit_poly_cases_n`), and its String Array case compared only a plain String (`SP_TAG_STR`), so the handle was never there. A Hash with one element the program appends to holds every String it was built with as a handle, so the `"cd"` of `"p" => "cd"` beside it was missed the same way.

"Boxed String needles compare by their contents in typed containers" mended this needle where the String Array is typed. This is the same needle where the Array is boxed too.

The case now asks the handle after the plain String and searches by its text. A handle whose String was emptied is the empty String; a nil stored among handles is a box with no handle and is not there.

The case is written that way only in a program whose boxes tagged as handles are handles, which the pull request beneath answers once for the program (`g_strbuf_boxes`). A program that holds no handle keeps master's C, and so does one where the pull request beneath does not say what a box tagged as a handle holds (it stores the String of a method call its scan does not follow). So does:

- a program that has, or may have, an `==` or a method of the call's name of its own, in any class: a `def` in String (the class table), a `def` or a Symbol of the name anywhere in the program, or a site where a method is named, made, mixed in or loaded by something the text does not spell (`an_prog_never_gives`, the walk the pull request beneath asks): `alias == equal?`, a rescued `String.define_method(:==) { }`, a `send(name)`, an `eval`, an `include` of a module;
- `member?` in a program that may have an `each` of its own, asked the same way. `member?` is Enumerable's in CRuby and walks by `each`, and the case asks neither: under `module Enumerable; def member?(x) = false; end` and under `class Array; def each; self; end; end` master's `false` is CRuby's answer;
- a program that requires a package, each of the nine tried: set, csv, uri, bigdecimal and pathname by their own Ruby, which the walk reads as the program's text, and stringio, json, strscan and `Gem::Version` because the compiler does not prove it read every file;
- `key?`, which an Array does not have in CRuby. It raises there, and under a `rescue` master's `false` is the rescued answer.

The switch is written wherever `include?` or `member?` has a boxed receiver and a boxed argument, so in a program that holds a handle the C of such a call changes whatever the receiver holds; a Set, a Hash or a Range does not run the case.

Cost in instructions a turn of two calls, by callgrind over 300,000 turns of `n += 1 if bw.include?(h["k"]); n += 1 if bw.include?(h["m"])` with `bw = [["ab", "cd", "ef"], 1][0]` and `h = {"k" => "cd", "m" => "zz", "n" => 5}`; the second row asks `h["n"]` and `h["none"]`. "With a handle" puts `hh = {"k" => "x".dup, "n" => 1}; hh["k"] << "y"` above the loop.

| boxed arguments | no handle in the program | with a handle, gcc 13.3 | with a handle, clang 18.1 |
|---|---|---|---|
| two plain Strings | 0 (the same C) | +3 | +2 |
| an Integer, nil | 0 (the same C) | +4 | +4 |

No corpus program's C changes beyond the test, with `--share-strings` or without. optcarrot's C is unchanged.

Not here: `delete` of a boxed String Array by an appended String still deletes nothing and answers nil, as on master. `key?` of a boxed String Array, which CRuby does not have (NoMethodError), is answered by this case on master, `true` for a plain String and `false` for an appended one, and that stays. A program where it is not said what a box tagged as a handle holds keeps master's `false`, and so does one that has or may have an `==`, a method of the call's name or (for `member?`) an `each` of its own, in any class and by any road, one that mixes in a module (its own too) and one that requires a package. An appended String read back from an attribute that first held an Integer (`ho.w = "a".dup; ho.w << "b"`) is still not found without `--share-strings`, as on master. `include?` and `member?` of a boxed String Range with a boxed appended String still answer false, as on master. A String that master holds otherwise than CRuby by a limit it documents is compared as master holds it, for the appended String now as for a plain one on master, also where master's `false` for the appended one happened to be CRuby's answer: a String the program transcoded out of UTF-8 (`"\u00E9".encode("ISO-8859-1")`, `"b".encode("UTF-16LE")`) is compared by the UTF-8 bytes master keeps for it (docs/limitations.md, "Mixed / non-UTF-8 encodings"), and that limit is not changed here. A walker the program gave Array, such as its own `select`, is still answered by the builtin on master, so an `include?` in a block it would not have run is now true where it was false: the walker is not changed here.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here before that, on this commit over master `da597297426d` with the pull request it depends on beneath it (Linux x86-64, gcc 13.3 and clang 18.1, CRuby 3.3.6): the build from nothing, the tests at five collector settings with both compilers, with and without `--share-strings`, `tools/gate.rb check`, `make gc-stress-test`, `make share-strings-test`, `make int-min-test`, `make share-verify-test`, `make cident` against the commit beneath, and the figures above.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: "A String Range's cover? and include? read a boxed appended String" (its answer for the program, whether a box tagged as a handle holds one, and its question of the class table are asked by the case here)
