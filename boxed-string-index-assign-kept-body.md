## What this changes

```ruby
Pt = Struct.new(:m, :n)
h = { title: +"draft", n: 1 }
h[:title][0] = "D"
p h[:title]                       # "Draft" in CRuby, "draft" on master
```

`spinel diff` on master: output-diff, `"draft"` for `"Draft"`.

With a class in the program that defines `[]=`, an index assignment on a String that reaches the call boxed was dropped: the String kept its contents and nothing was raised, whether an object of the class was ever built or not. Since ae5b2edba (Struct member writes through poly receivers) a Struct is such a class, so the program above, right before that commit, prints "draft" now.

A boxed `[]=` beside such a class is a switch on the receiver's class, and its default stores through `sp_poly_set_poly`, which does nothing for a String. The emission for the same call in a program with no such class already changes the String and stores it where it was read from. `emit_poly_aset_string` writes that emission ahead of the switch, under a test that the receiver holds a String. The switch, its arms and its default are as they were; `emit_call_body` is not touched.

That emission reads its operands more than once, so the arm is written only where a list proves it right, and everywhere else the store stays as the switch has it:

- the key is an Integer, a start and a length, or a Range; on an element also a boxed key that holds an Integer;
- the value is a String or a boxed value that holds one;
- what is read a second time runs none of the program's code: a pure read, a String literal, a Range of Integers, an interpolation of Strings and numbers;
- nothing in the key or the value can change what the receiver names before the store reads it again.

Two commits: the arm, then a Range of Integers as a key beside an element or an instance variable. Cost by callgrind: 6 instructions a store for the test when the value can be a String, none when it cannot (an Integer into a boxed Array emits the same C).

Not here, the same on master with and without the class: a String key, a Regexp key, a boxed String in a global, a class variable or a method's answer; `s[0] = v` with an Integer in v, dropped where CRuby raises TypeError.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (two pull requests: "An index store outside a boxed String raises CRuby's error class", the runtime fix under the arm; and "A value that is no object stays off a first Struct's []= arm", without which a boxed String in a local still enters the Struct's arm when the Struct is the program's first class)
