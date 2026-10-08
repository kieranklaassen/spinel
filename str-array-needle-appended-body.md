<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Fix with a cost in a program that holds an appended String: up to 5 instructions a call on a search of a String Array for a boxed argument (the table below). A program that holds none compiles to the same C.

```ruby
h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
w = ["ab", "cd", "ab"]
p w.include?(h["k"])
p w.index(h["k"])
p w.delete(h["k"])
p w
```

prints `false`, `nil`, `nil` and `["ab", "cd", "ab"]` (`spinel diff`: output-diff), with and without `--share-strings`. CRuby prints `true`, `0`, `"ab"` and `["cd"]`.

A String something appends to is held as its shared handle, and a boxed read of it carries the handle (`SP_BUILTIN_STRBUF`), not a plain boxed String. Four places that search a String Array for a boxed argument compared only a plain String (`SP_TAG_STR`), so the handle was never there. One commit a place, each with its test:

- `include?` and `member?` of a String Array;
- `index`, `find_index` and `rindex`;
- `delete`, with a block and without;
- `include?` of a boxed receiver that holds a String Array.

Each gains an arm for the handle, asked after the plain String and nil, that searches by the handle's text (`delete` asks out of line, `sp_StrArray_delete_handle`). A Hash with one element the program appends to holds every String it was built with as a handle, so the `"cd"` of `"p" => "cd"` beside it was missed the same way. An appended String that is empty is the empty String, not nil.

The arm is written only in a program whose boxes tagged as handles are handles, which the piece beneath answers once for the program (`g_strbuf_boxes`). A program that holds no handle, one whose box may hold a plain String under the handle's tag, and one with a `String#==` of its own keep master's C.

Cost in instructions a turn of two calls, gcc 13.3 / clang 18.1, in a program that holds a handle (`hh = {"k" => "x".dup, "n" => 1}; hh["k"] << "y"` above the loop); callgrind over 300,000 turns of `n += 1 if w.include?(h["n"]); n += 1 if w.include?(h["none"])` on `w = ["ab", "cd", "ef"]` with `h = {"k" => "cd", "m" => "zz", "n" => 5}` (the first row reads two of its Strings). Without the handle every row is 0 / 0.

| boxed arguments | `include?` | `index`, `rindex` | `delete` | `delete { }` | boxed `include?` |
|---|---|---|---|---|---|
| two plain Strings | 0 / 0 | 0 / -2 | 0 / -6 | -3 / -2 | +2 / +2 |
| an Integer, nil | +4 / +4 | +4 / +6 | +2 / +4 | +10 / +4 | +5 / +4 |

In the corpus the boxed `include?` commit changes the C of six programs beside the tests (four of the csv package's, `test/nested_table_boxed_by_reference.rb`, `test/set_string_member_frozen.rb`): one line each, the arm, and each prints what it printed. The other three commits change none. optcarrot's C is unchanged.

Not here: `delete` on a boxed String Array or a boxed Hash by an appended String deletes nothing and answers nil. That road is the runtime's `sp_poly_delete_key`, which cannot know what a box of the program holds.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: "A String Range's cover? and include? read a boxed appended String" (its answer for the program, whether a box tagged as a handle holds one, is asked by every arm here), and through it "The two ends of a String Range made on the spot are both kept, and made in order" and "A String Range that no name holds is kept until it is read"
