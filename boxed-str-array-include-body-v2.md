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

The case is written that way only in a program whose boxes tagged as handles are handles, which the pull request beneath answers once for the program (`g_strbuf_boxes`), and that has no `String#==` of its own. A program that holds no handle, one whose box may hold a plain String under the handle's tag, and one with its own `String#==` keep master's C. The switch is written wherever `include?`, `member?` or `key?` has a boxed receiver and a boxed argument, so in a program that holds a handle the C of such a call changes whatever the receiver holds; a Set, a Hash or a Range does not run the case.

Cost in instructions a turn of two calls, by callgrind over 300,000 turns of `n += 1 if bw.include?(h["k"]); n += 1 if bw.include?(h["m"])` with `bw = [["ab", "cd", "ef"], 1][0]` and `h = {"k" => "cd", "m" => "zz", "n" => 5}`; the second row asks `h["n"]` and `h["none"]`. "With a handle" puts `hh = {"k" => "x".dup, "n" => 1}; hh["k"] << "y"` above the loop.

| boxed arguments | no handle in the program | with a handle, gcc 13.3 | with a handle, clang 18.1 |
|---|---|---|---|
| two plain Strings | 0 (the same C) | +3 | +2 |
| an Integer, nil | 0 (the same C) | +4 | +4 |

In the corpus the C of seven programs changes beside the test (four of the csv package's tests, `test/nested_table_boxed_by_reference.rb`, `test/set_string_member_frozen.rb` and `test/share_strings_boxed_hash_key.rb`): one line each, the case, and each prints its `.expected` with gcc and clang. optcarrot's C is unchanged.

Not here: `delete` of a boxed String Array by an appended String still deletes nothing and answers nil, as on master. `key?` of a boxed String Array, which CRuby does not have (NoMethodError), is answered by this case on master, `true` for a plain String; here it is `true` for an appended String as well. A program whose box may hold a plain String under the handle's tag keeps master's `false`.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here before that (Linux x86-64, gcc 13.3 and clang 18.1, CRuby 3.3.6). On this commit over master `74fa6d7c2457` with the two pull requests it depends on beneath it: the build from nothing, the test at five collector settings with both compilers, with and without `--share-strings`, and `tools/gate.rb check`. On the same commit over master `2810a235d119`: the same, `make share-strings-test` and `make cident` against its parent. The cost table is of the same commit over master `0e8befeb3691`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: "A String Range's cover? and include? read a boxed appended String" (its answer for the program, whether a box tagged as a handle holds one, is asked by the case here), and through it "A String Range made on the spot keeps its ends, made in order, until it is read"
