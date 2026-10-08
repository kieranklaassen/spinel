<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A C function called with a shared String handle beside another argument that allocates gets a freed String. It shows under `SPINEL_GC_STRESS=2`. The fix costs 19 to 34 instructions a call where it applies. A call that was right pays it where the other argument calls a method that is more than one plain read, a reader that a subclass overrides with such a method, a reader whose receiver is a call the lists do not know for a read (a Hash's value: `h[:a].get`), a conditional or an `||` of plain readers, or a reader on a boxed receiver that the lists cannot clear: a builtin class has a method of the name (`name`, `to_s`, `dup`), the program gives a builtin class one, or one of its classes has `method_missing`. `LibC.strcmp(s, a.pick)`, `LibC.strcmp(s, h[:a].get)`, `LibC.strcmp(s, k > 5 ? a.get : b.get)` and `LibC.strcmp(s, r[i].name)`, below.

```ruby
module LibC
  ffi_func :strncmp, [:str, :str, :int], :int
end
s = +"12"
t = s
t << "345"
p LibC.strncmp(s, t, s.size + 0)     # master at SPINEL_GC_STRESS=2: 170. CRuby's answer: 0
```

A String held as a handle goes to a `:str` argument as a copy when another operand of the call runs code, and that copy is held by nothing but the C call's argument list: the second copy's allocation collected the first. Two handles are not the only case. One handle beside a call that builds a String (`LibC.strncmp(s, joined(x, "345"), 5)`) answered -170 the same way, with clang so did a handle beside an Integer argument that allocates on its way, and so did the Strings handed to a variadic function (`LibC.printf("%s %s\n", s, joined(x, "345"))`).

`emit_call_cmethod_arms` (`src/codegen_call_class.c`) rooted the String arguments only where the call can run Ruby code. It now roots each String made where it stands in the call when another argument's evaluation allocates (`ffi_str_arg_beside_alloc`): in its temp where the call already takes the temp form, else in a slot the argument is assigned to in its own place (`ffi_arg_hold`). No argument moves, so the arguments run in the order they ran in, with gcc and with clang. Moving them to ordered temps would lose answers gcc gets right today where one argument changes another in place: `q = +"ab"; LibC.printf("%s %s %s\n", q, (q << "c"; "x" + "y"), "a" + "b")`, `LibC.strncmp(@s, (bump; "ab" + "c"), n.to_s.size + 2)` and `LibC.strncmp(ident(q), (q << "c"; "ab" + "c"), q.size + 0)` print CRuby's answers there.

An argument the operand order ran ahead of the call, a read of a value its owner holds (a typed Array's element, a plain reader, a Hash's value, a length: `operand_is_held_read`), a call whose method is one plain read for every class the receiver can be (an instance variable, a constant, a literal: `ffi_arg_plain_reader`; its receiver a plain read, or a chain of them through an element of an Array of one class's objects: `ffi_held_obj_read`; a module's reader is among them, and a boxed receiver's where no builtin class has a method of the name and the program gives none one: a box may hold a String, and with `def dup; @name; end` in the program's class `r[i].dup` still builds one for it) and a handle's read that hands C the live buffer are neither made here nor allocating. Those calls keep their C: two elements, two readers, two Hash values, a handle beside an element, a reader, a length, `a.get` with `def get; @name; end` or `q[i].get` on an Array of one class's objects, two locals. A program's own `Array#[]`, `#at` or `#first` keeps master's C too: master writes that call into a temp ahead of the statement, and the reader reads the temp.

Cost, by callgrind on master 9c7ea3ce, instructions a call over 1,000,000 calls, gcc and clang: `LibC.strcmp(s, u + v)` 26.8 and 30.8; `LibC.strcmp(s, joined(u, v))` 27.8 and 33.8; `LibC.strncmp(s, t, s.size)` 18.9 and 26.9. Those three were wrong under stress. `LibC.strcmp(s, a.pick)` with `def pick; @name.size > 2 ? @name : "zz"; end` was right, and pays 28 and 31 to 33: a user method counts as allocating everywhere in the emitter, and nothing says this one builds nothing. `LibC.strcmp(s, a.get)` on the base's object, where a subclass overrides `get` with a method that builds, pays 28.0 and 33.0. `LibC.strcmp(s, r[i].name)` on a boxed `r` whose two classes have `def name; @name; end` pays 27.0 and 33.0 with `r[i & 1]` in one loop, 31.5 and 34.0 with `r[i]` in an inner loop of two turns, and `LibC.strcmp(s, h[:a].get)` on a Hash of one class's objects 27.0 and 32.0: its value is a box, and no list knows that read. `LibC.strcmp(s, k > 5 ? a.get : b.get)`, the same with two `attr_reader`s and `LibC.strcmp(s, (a.get || b.get))` pay 27.0 and 33.0: the lists clear a reader, not a choice between two. All of these were right.

`tools/cident.sh` against that master: 6,511 identical, 2 differ, 0 refusal changes, 0 refused by both, of 6,513: this test and `test/ffi_str_borrow.rb`.

`test/ffi_str_borrow.rb` fails under stress on master for this cause; it joins `GC_STRESS_TESTS` with the new test.

Not in this change: a receiver that is an object held by value. `LibC.strcmp(s, mk("123").get)`, with `mk` answering such an object, is wrong at stress level 2 on master with both compilers and stays wrong with clang: the receiver sits in a struct temp no root knows.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head on linux-x86_64 before opening: the two tests with gcc and clang, with and without `--share-strings`, plain and under both GC stress modes; `ruby tools/gate.rb check`; `tools/cident.sh` against master 9c7ea3ce; `make gc-stress-test`; `make gate-props` (with `share-strings-test: pass`) and `make gate-bench`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the tests are marked not-cruby: ffi_func is Spinel's own)
- [x] Values past 2^31 are marked `# spinel: int64` (the tests have none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: nothing
