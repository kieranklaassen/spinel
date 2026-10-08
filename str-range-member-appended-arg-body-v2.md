<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Fix with a cost in a program that holds an appended String: 1 to 6 instructions on a membership call of a String Range with a boxed argument (the table below). A program that holds none compiles to the same C.

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

The arm is written only where a box tagged as a handle is known to hold one. `program_strbuf_boxes` answers that once for the program, before any C is written. Master's C stays, byte for byte, in a program that holds no handle; in one that stores a call on an object where a handle is wanted (a method's own String, `StringIO#string`, `StringScanner#rest`: master tags the plain String's bytes as a handle there, and the box does not say which it holds); and in one with its own `Range#cover?`, `#include?` or `#member?`, or its own `String#<=>`, `#==` or `#succ`, which this call does not ask, before or after.

Cost in instructions a call, gcc 13.3 / clang 18.1, callgrind over 300,000 turns of `n += 1 if r.cover?(x)` with `r = ("aa".."az")` and `x` read once from `["ab", 1]`. "With a handle" puts `hh = {"k" => "x".dup, "n" => 1}; hh["k"] << "y"` above the loop.

| boxed argument | no handle in the program | with a handle |
|---|---|---|
| `cover?`, a String in a local | 0 / 0 | +4 / +2 |
| `cover?`, a String read from the Array each turn | 0 / 0 | +6 / +2 |
| `cover?`, an Integer | 0 / 0 | +6 / +4 |
| `include?`, a String (`"aa".."ad"`) | 0 / 0 | +3 / +1 |

The walk looks at the call nodes stored as a handle: compiling optcarrot runs 8,338,283,807 instructions for 8,338,025,724, and its C is unchanged. In the corpus one program's C changes beside the new test, `test/codegen_settled_operand_types.rb`, which prints what it printed.

Not here: the program whose box may hold a plain String under the handle's tag crashes when it reads that box (gcc) or does not build (clang), as on master; `cover?` of a plain String still compares up to its first NUL; a String Range the call does not see as typed (read out of an Array or a Hash, or a "Range or nil" local called with `&.`) and `r.method(:cover?).call(x)` still answer false for the handle; `===` and `case`/`when` of a String Range with a boxed value, and `include?`, `index` and `delete` of a String Array, are their own changes.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: "The two ends of a String Range made on the spot are both kept, and made in order" and "A String Range that no name holds is kept until it is read" (a Range whose two ends are made where it is written loses an end while a boxed argument is made; master's false for every handle hid that, and with this arm alone such a call answers true for a String outside the Range)
