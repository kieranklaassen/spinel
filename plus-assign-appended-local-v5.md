<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
out = +""
out << "a"
out += "b"     # refused: unsupported operator assignment
out << "c"
p out          # "abc" in CRuby
```

`out = out + "b"` compiled and was right; only the `+=` spelling was refused. A local that is appended to holds its String by a handle, and the operator write had an arm for a plain String only. It is the same for a String two names share: `t = s << "a"; t += "x"`.

The new arm does what CRuby does. String#+ answers a new String, so the local gets a handle of its own and the String its other names hold is not touched. The operand is run first and the receiver read after it, so an operand that appends to the receiver shows in the sum (`t += (s << "z"; "q")`). The operand converts as String#+ converts it: `to_str`, else TypeError. A nil receiver raises NoMethodError.

**Where it applies.** The arm reads the local's slot as a handle, so it applies only where every other write of the local is proven to leave there the handle of the String CRuby names (`strbuf_value_proven_handle`):

- nil
- a local or an instance variable that holds a handle, in parentheses or not, and `+` of one
- `u = v` where `u` is such a local, and `u => t`
- a call on such a local that answers its receiver: `replace`, `to_s`, `itself`, `force_encoding`
- a String no other name holds: a literal, an interpolation, `+` of either, `x.dup`, `a + b`, `a * n`
- an append chain on such a local or instance variable, or on a String no other name holds

A chain that ends in `prepend` (`t = (s << "a").prepend("p")`) is such a chain: master keeps its handle since aa264ac9c, and the proof asks what the chain emitter asks (`str_append_chain_links`).

Everywhere else the write is refused as on master, in the same words:

```ruby
$g = +"b"
t = $g << "a"     # answers $g's own String, which has no handle to give
t += "x"          # unsupported operator assignment, as on master
```

Not on the list: a parameter; a target of a multiple assignment, a `case/in` pattern, a rescue or a named capture; a conditional value; `&&=`; the result of a method that answers anything but its receiver; a reader's String; an element; a boxed value; and a String that has another name already (a global, a constant), which a new handle would part from that name. Three reject tests hold a first write that is not on it: an append to a global, to a constant and to a method's result.

Also refused, as before: the value of the write (`v = (t += "x")`, or the write as a method's last statement). `v` would have to be the same String as `t`, and nothing pairs the two there. `test/reject/string_appended_local_plus_assign_value.rb` holds it.

The other operator writes were run over the same shapes and are not changed: `*=`, `%=` and `<<=` are refused on a String local whether it is appended to or not; `||=` and `&&=` compile.

**Measured** against master 5c2dea51 with CRuby 3.3.6 as the reference, over 634 programs (replayed on master 4d56c157, on 52c5ccf7 and on dafa0d04: the same table, program for program):

| | programs |
|---|---|
| refused on master, right here | 159 |
| refused on master, refused here in the same words | 174 |
| refused on master, refused here for its operand | 1 |
| refused on master, the C does not build here | 2 |
| refused on master, a wrong line here | 2 |
| not refused on master, the same output here | 296 |

The one refused for its operand calls a method that does not exist, which is refused first. The two that do not build freeze a local a proc captures (`t.freeze`, a read); with the sum spelled out master does not build them either. The two with a wrong line are wrong in lines master does not refuse, and master prints the same with the refused lines spelled out:

- `u = +"a"; u << "\xff".b` leaves the handle's encoding UTF-8, with or without a `u += "z"` after it.
- A local that is assigned nil in one place and a String under a condition in another (`t = nil; t = s if c`) is not held by a handle, so `t = s << "a" << "b"` elsewhere gives it a copy and `s << "!"` does not show in `t`. Master compiles `t += "x"` on that local today.

No program that was right changes: of the 296 not refused on master, 238 are right and print the same. On dafa0d04 they are 241: master now runs the operand of `t = t + (s << "z"; "q")` before it reads `t`, in three programs, and they print the same here.

192 of the 634 are 12 kinds of first write (`t = BASE << "a" ...`, the base a local, an instance variable, a parameter, a global, a constant, a method's result, a Struct member, a reader) at 16 lengths from 1 to 70 links, each followed by `t += "x"; t << "y"`: 86 are refused on master and refused here in the same words, 50 are refused on master and right here, 56 are not refused on master and print the same.

One more route to a fault master has: a `<<` chain of 64 links or more under such a local. Master takes `t = s << "a" << ...` for a copy from 64 links and loses a link from 66, so `u = t; u += "x"; t << "!"` then prints 64, 65, 65 for the sizes of s, t and u at 64 links where CRuby prints 65, 65, 65. Master prints the same with the sum spelled out (`u = u + "x"`). Three programs, at 64, 65 and 66 links; at 2 and 63 links they are right. The chain is its own piece.

With `prepend` on the chain, on master 52c5ccf7: 31 shapes of first write (`t = (s << "a").prepend("p")`, two arguments, `concat`, the `prepend` in the middle of the chain or twice, as a statement, in a block, under a condition, 8 to 66 links, and the bases above), each with `t += "x"` and with the sum spelled out, 62 programs. Master refuses 23. 14 are right here. 7 are refused in the same words (the base a global, a constant, a method's result, a reader's String, a parameter, and two on an instance variable). 2 print a wrong line, the one master prints with the sum spelled out: an append after the `prepend` in the same chain is lost (`t = (s << "a").prepend("p") << "c"`, and `v = u.prepend("p") << "c"` without any chain). The other 39 print what they print on master.

A second route, measured by the second reading and not among the 634: the local takes its String from another local, and that local took it from a global, a constant or a method's result.

```ruby
$g = +"g"
u = $g
u << "d"
t = u
t << "1"
t += "x"
t << "2"
p($g, u, t)     # "gd1" "gd1" "gd1x2" in CRuby
```

Master refuses the `+=`; here it prints `"g"` `"gd1"` `"gd1x2"`. The wrong line is the global's, and `u = $g; u << "d"` computes it: master compiles those two statements today and prints `"g"` `"gd"` for them. With the sum spelled out (`t = t + "x"`) master prints the same three lines as here, in all 35 programs of the route (seven spellings in five places). It is left as it was: `t = u` gives `t` the String `u` names, which is right, and the parting is in `u`'s own write.

**Generated C.** `make cident REF=upstream/master` on dafa0d04: `6281 identical, 0 differ, 1 refusal changes` (the new test, which master refuses). `tools/refusals.sh` passes (460 records) with the four reject programs' eight records, and `make reject-test` passes. The test prints the same under `SPINEL_GC_STRESS=1` and `2`, with clang, and at `-O 1`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Strings, true and false)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
