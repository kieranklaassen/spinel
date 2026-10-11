<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Fix with a cost in a program that holds an appended String: such a String that is not in the Array is now searched for, where master answered without looking (+362 to +363 / +359 instructions a turn of two calls: master's own search, 171 / 168 a call), and a plain String, an Integer or nil pays up to 4 a turn of two calls (the table below). A program that holds none compiles to the same C, with `--share-strings` and without.

```ruby
h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
bw = [["ab", "cd"], 1][0]
p bw.include?(h["k"])
p bw.member?(h["k"])
```

prints `false` twice, with and without `--share-strings`. CRuby prints `true` twice.

A String something appends to is held as its shared handle, and a boxed read of it carries the handle (`SP_BUILTIN_STRBUF`), not a plain boxed String. `include?` of a boxed receiver is a switch over what the box holds (`emit_poly_cases_n`), and its String Array case compared only a plain String (`SP_TAG_STR`), so the handle was never there. A Hash with one element the program appends to holds every String it was built with as a handle, so the `"cd"` of `"p" => "cd"` beside it was missed the same way.

The case now asks the handle after the plain String and searches by its text. A handle whose String was emptied is the empty String; a nil stored among handles is a box with no handle and is not there. Receiver and argument stay in the root frame where either may allocate, and the case's own read allocates nothing, so an Array or a String that only the call holds (a method makes it, a container gives it up) is still there when the Array is searched.

The case is written that way only in a program whose boxes tagged as handles are handles, which the pull request beneath answers once for the program (`g_strbuf_boxes`). A program that holds no handle keeps master's C, and so does one where the pull request beneath does not say what a box tagged as a handle holds (without `--share-strings`, a program that stores the String of a method call its scan does not follow). So does:

- a program that has, or may have, an `==` or a method of the call's name of its own, in any class: a `def` in String (the class table), a `def` or a Symbol of the name anywhere in the program, or a site where a method is named, made, mixed in or loaded by something the text does not spell (`an_prog_never_gives`, the walk the pull request beneath asks): `alias == equal?`, a rescued `String.define_method(:==) { }`, a `send(name)`, an `eval`, an `include` of a module;
- `include?` and `member?` in a program that may have an `each` of its own, asked the same way. CRuby's `member?` is Enumerable's and walks by `each`; and CRuby walks by `each` as well to make what master holds as the receiver (a blockless `to_enum`, `entries`, `sort_by`) and to run the block around the call. The case asks none of that: under `class Array; def each; self; end; end` master's `false` is CRuby's answer for `bw.member?(x)`, for `bw.to_enum.include?(x)` and for `bw.entries.include?(x)`, and a call in a block that `each` does not run is not made;
- a program that requires set, csv, uri, bigdecimal, pathname, stringio, json or strscan, or uses `Gem::Version`;
- `key?`, which an Array does not have in CRuby. It raises there, and under a `rescue` master's `false` is the rescued answer.

The switch is written wherever `include?` or `member?` has a boxed receiver and a boxed argument, so in a program that holds a handle the C of such a call changes whatever the receiver holds.

Cost in instructions a turn of two calls, by callgrind over 300,000 turns of `n += 1 if bw.include?(X); n += 1 if bw.include?(Y)` in a `while` loop at the top level, with `bw = [["ab", "cd", "ef"], 1][0]` and `h = {"k" => "cd", "m" => "zz", "n" => 5}`. "With a handle" puts `hh = {"k" => "x".dup, "n" => 1}; hh["k"] << "y"` in the program, and each row was counted with those two lines above the Array's and below it; a figure is the least and the greatest of the two where they differ. A call's result is `pick(v, 0)` or `pick(v, 1)` of `def pick(v, i); v[i]; end` over `v = ["x".dup, 2]; v[0] << "y"`.

| the two boxed arguments | no handle in the program | with a handle, gcc 13.3 | with a handle, clang 18.1 |
|---|---|---|---|
| a plain String that is in the Array, twice | 0 (the same C) | +2 | +2 |
| a plain String that is not in the Array, twice | 0 (the same C) | +1 to +3 | +2 |
| two plain Strings, one in the Array and one not | 0 (the same C) | +1 to +3 | +2 |
| an Integer, nil | 0 (the same C) | +4 | +4 |
| a call's result that is an Integer, twice | - | +4 | +4 |
| an appended String that is not in the Array, twice | - | +362 | +359 |
| the same, the second call by `member?` | - | +363 | +359 |
| a call's result that is such a String, twice | - | +363 | +359 |

The last three rows are the price of looking: master answered `false` for an appended String without searching, and the search is master's own `sp_StrArray_include`, 171 / 168 instructions a call for a String that is not among three, which is what a plain String that is not there pays on master (the second row's calls, counted inside the function). Where the appended String is in the Array master printed the wrong line; the search then adds +500 / +494 found third and +352 / +350 found first. The plain rows are the layout of the case's two arms: gcc tests the answer after the two arms have joined, where master's line let it test in the arm, one jump more a call, and where a String is not found the figure moves by one with the order of the program's first lines; with the loop in a `300000.times` block the third row is +1 / 0, in a method +3 / +2. The Integer's row is the one test that tells a handle from a value that holds no String.

No corpus program's C changes beyond the two tests, with `--share-strings` or without, and the change adds no refusal in either setting. optcarrot's C is unchanged.

Not here: `delete` of a boxed String Array by an appended String still deletes nothing and answers nil, as on master. `key?` of a boxed String Array, which CRuby does not have (NoMethodError), is answered by this case on master, `true` for a plain String and `false` for an appended one, and that stays. A program where it is not said what a box tagged as a handle holds keeps master's `false`, and so does one that has or may have an `==` or a method of the call's name of its own, in any class and by any road, and one that mixes in a module (its own too). `include?` in a program that has or may have an `each` of its own keeps master's `false` as well, also where CRuby's `include?` would not walk by it (a plain `bw.include?(x)` outside any block): that is the price of asking `each` for both names. An appended String read back from an attribute that first held an Integer (`ho.w = 1; ho.w = "a".dup; ho.w << "b"`) is still not found without `--share-strings`, as on master. `include?` and `member?` of a boxed String Range with a boxed appended String still answer false, as on master. A String the program transcoded out of UTF-8 is compared by the UTF-8 bytes master keeps for it, for the appended String now as for a plain one on master, also where master's `false` happened to be CRuby's answer (docs/limitations.md, "Mixed / non-UTF-8 encodings"); this change leaves that limit as it is. A method the program gave a builtin class and master answers by the builtin (its own `select`, `map` or `find_all` of Array, its own `<<` of String) is still answered by the builtin, so an `include?` of an Array it would not have made, of a String it would not have built, or in a block it would not have run is now true where it was false: that method is left as it is. A block in the argument that master runs ahead of the whole call (`x.then { }`, `loop { }`, `catch { }`, `instance_eval { }`) and that gives the receiver another Array is asked of that new Array, where CRuby asks the one it replaced (with a local variable as the receiver, and without `--share-strings` with a Struct member as well): that is master's order, and a typed String shows it on master as well; an appended String, for which master's `false` was CRuby's answer by chance, is now asked in that order too.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

On Linux x86-64 (gcc 13.3 and clang 18.1, CRuby 3.3.6), before that, on this commit with the pull request it depends on beneath it (the expected files were made with CRuby 3.3.6, so the first box is open for the gate): the build from nothing, the eight tests at five collector settings with both compilers, with and without `--share-strings`, and under the two `--int-overflow` modes, `ruby tools/gate.rb check-range HEAD^1 HEAD`, `make gc-stress-test`, `make share-strings-test`, `make int-min-test`, `make cident` against the commit beneath and the figures above. No make leg runs a test with `--share-strings` at `SPINEL_GC_STRESS=2`, so the eight were run by hand at that level with the flag and without it, with `SPINEL_GC_VERIFY` 0 and 1 and both compilers. `make share-verify-test` ends as it does on master without this commit: one failure (test/share/share_strings_net_http_zlib.rb) and two new diagnostics (test/share/share_strings_exception_dispatch.rb).

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (compared with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: "A String Range's cover? and include? read a boxed appended String" (its answer for the program, whether a box tagged as a handle holds one, and its question of the class table are asked by this case)
