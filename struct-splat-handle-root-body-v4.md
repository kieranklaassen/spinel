<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** "Shared String argument conversions stay rooted across calls" keeps the handle a literal or a bare read gets when an ordinary call binds it to a String changed in place. Two ways of handing a String over do not pass through that code and still lose the handle, in a plain run: a Struct's `new` given two or more such Strings, and an element of a splatted Array handed to a class's `new`. The cost is a rooted temp for each such String where its handle can be lost: 9 to 37 instructions a construction for a Struct built with gcc and 16 to 48 with clang, 14 to 43 and 12 to 50 for a splat (the table and its loop are below). A construction that makes one handle only, and a splat into a method that binds one such String, compile as they did.

```ruby
Entry = Struct.new(:a, :b)
w = +"w"
v = +"v"
e = Entry.new(w, v)
e.a << "z"
e.b << "z"
kept = []
3000.times { kept << Entry.new("alpha", "beta") }
p kept.count { |k| k.a != "alpha" || k.b != "beta" }   # 0 in Ruby; 2 on master, 2,995 at SPINEL_GC_STRESS=1
```

`e.a << "z"` makes the members Strings changed in place, so each holds its String through a handle, and the constructor wraps each literal in one: `sp_Entry_new(sp_String_new_shared("alpha"), sp_String_new_shared("beta"))`. Nothing holds the first handle while the second is allocated. The constructor itself roots its parameters before it allocates the object, so one handle made in the list is safe and is left as it was.

A class whose member is changed in place loses an element that comes out of a splat, and the default a short splat leaves to fill. There one handle is enough to lose: a class's `new` allocates the object before `initialize` takes the parameters.

```ruby
ra = ["r"]
qa = ["q"]
20_000.times { pairs << Pair.new("q", *ra) }   # 4 of them wrong on master built with gcc, none with clang; 19,998 at level 1 with either
20_000.times { tails << Tail.new(*qa) }        # def initialize(x, y = "r"): 1 wrong with gcc
```

Both now take the form the ordinary call has (`emit_rooted_conversion`): the temp's declaration and its root go ahead of the statement, and the handle is made and assigned where the value stands.

```c
sp_String * _t7 = NULL; SP_GC_ROOT(_t7);
sp_String * _t8 = NULL; SP_GC_ROOT(_t8);
... sp_Entry_new((_t7 = sp_String_new_shared("alpha")), (_t8 = sp_String_new_shared("beta")))
```

Where the temp is taken:

- A Struct's member (`emit_struct_new_call`) asks `arg_read_converts`, as an argument does, and is held only where two or more of the member values are made in the list by something that allocates: another converted literal or read, a spread Hash, a call that is not hoisted into a rooted temp of its own. `One.new("alpha")`, `Mixed.new("alpha", i)` and `Mixed.new("alpha", 7)` keep master's C, and so does a member beside a value that runs none of the program's code and makes nothing (`subtree_is_plain_value`, below).
- A splat's element (`emit_elem_param`) is held for a class's `new`, and for another callee only where a second value of the list is made in place. From the dispatch it is never held: the dispatch binds each argument to a rooted temp of its own. `mk(*qa)` and `mk2(7, *ra)`, methods with one such parameter, `U.new.set(*qa)`, `U.new.put(*qr)` and the same methods called on self keep master's C. A splat that fills two such parameters of a method called without a receiver is held, and was wrong: with `def mkp(x, y) = U.new.put(x, y)`, `mkp(*qr)` left 1 of 2,000 wrong in a plain run on master and 1,996 at level 1, and aborted at level 2; `mkp("q", *ra)` did the same built with gcc and was right built with clang, where it now pays.

A value that is a handle already, or nil, gets no temp.

What counts as a value that makes nothing (`subtree_is_plain_value`), at an argument's place and at a default's: a plain read by master's list (`subtree_is_pure_read`) and a global's read; a unary minus, `abs` or an operator on numbers; `size` or `length` of a String, an Array or a Hash, as two lists of the analyzer take them (`hash_new_capacity_pure`, `nn_pure_call`); `!` on a comparison, `&&`, `||`, and an `if` or `unless` with an else whose test and branches are such values. `Mixed.new("alpha", -i)`, `Mixed.new("alpha", s.size)`, `Mixed.new("alpha", (i > 3 || j > 9 ? 1 : 2))` and `def mkd(x, n = $k + 1)` keep master's C.

An index, an operator, a reader or one of those calls counts only while it is provably the builtin's (`plain_name_is_builtin`): the program has no `def` and no `attr` of that name anywhere, in any class, and none of the ways to define a method that leave no `def` behind (an `alias`, `alias_method`, `define_method`, a delegator, a `send` with a computed name, an `eval` of a class). Otherwise the value may run the program's code, which may allocate, and the member is held as beside any call:

```ruby
class Float
  def -@ = ["a" + to_s, "b"].size.to_f
end
MixF = Struct.new(:a, :x)                  # a is changed in place
kept << MixF.new("alpha", -f)              # master built with clang: SIGSEGV in a plain run
```

Master's list of plain reads takes `f + 1.0`, `f > 1.0` and `ar[0]` for reads by the types alone, so the same holds for a `+`, a `>` or a `[]` of the program's own. Seventeen such programs (a `def`, an `alias`, `alias_method`, `define_method`, a prepended module; on Float, Integer, Array and String) stop on master built with clang and are right here, gcc and clang, at levels 0, 1 and 2. A program that has a method of that name in any class, or one of those words, pays the cost below at such a list, where master may have been right: `Mixed.new("alpha", -i)` beside an `alias` elsewhere in the program costs 10 | 15.

The cost, callgrind on master (84f5b5020), in instructions a construction. The loop is `200_000.times { |i| k = X; n += 1 if k }` at the top level; in another loop or another program the figures move by up to about ten instructions with where the construction stands and what else the program defines (the first row alone in its program: 30 | 32), and between two runs of one executable by one or two. A range holds the counts of two measurements.

| construction | gcc | clang | master's answer |
|---|---|---|---|
| `Entry.new("alpha", "beta")`, two members | 22 to 30 | 32 to 39 | wrong |
| `Three.new("a1", "b1", "c1")`, three members | 37 | 48 | wrong |
| `KwE.new(a: "alpha", b: "beta")`, by keyword | 29 | 39 to 40 | wrong |
| `Mixed.new("alpha", sz(i))`, a literal beside a call | 9 to 10 | 19 to 21 | right with this `sz`; see below |
| `Mixed.new("alpha", s.bytesize)`, a literal beside a builtin's call | 11 | 16 | right; see below |
| `Pair.new("q", *ra)`, one element | 24 to 25 | 20 | wrong |
| `Pair.new(*qr)`, two elements | 41 to 43 | 45 to 48 | wrong |
| `Tail.new(*qa)`, one element and the default | 39 | 45 | wrong |
| `Uno.new(*qa)`, one element | 14 to 16 | 21 | right in a plain run and at level 1, aborts at level 2 |
| `mkp(*qr)`, two such parameters of `def mkp(x, y)` | 31 to 35 | 43 to 50 | wrong |
| `mkp("q", *ra)`, the same method | 22 | 12 to 13 | wrong built with gcc, right with clang |
| `One.new("alpha")`, `Mixed.new("alpha", i)`, `Mixed.new("alpha", -i)`, `Mixed.new("alpha", s.size)`, `Mixed.new("alpha", (i > 3 ? 1 : 2))`, `Entry.new(w, v)`, `Pair.new("q", "r")` | 0 | 0 | right |
| `mk(*qa)`, `mk2(7, *ra)` (one such parameter), `U.new.set(*qa)`, `U.new.put(*qr)` | 0 | 0 | right |

One class pays and can be right without it: a literal beside a value a call makes. In `Mixed.new("alpha", sz(i))` the literal's handle is lost only where `sz` allocates an object and the C compiler runs it after the handle is made. With `def sz(i) = ("k" * (i % 5 + 1)).size` master is right at every level, gcc and clang. With `def sz(i) = ["a" + i.to_s, "b" + i.to_s, "c"].size` master built with clang crashes in a plain run and aborts at level 2, and is right with this change. What a call allocates is not known where it is emitted, so the member is held beside any call that is not hoisted, a builtin's among them. Master is right on these and each pays as `s.bytesize` does: `s.bytesize`, `ia.sum`, `i.succ`, `f.to_i`, `s.ord`, `s.count("l")`, `[i, 2].max`, `i.to_s.size`, a method that hands its argument back, and a conditional whose test is a call (`i.odd? ? i : j`). Cutting them needs a list of the builtins that allocate nothing, which the compiler does not keep for them; what it does keep is used: its list of plain reads, and the analyzer's two lists for `size`, `length` and `abs`.

The generated C of the 6,608 other programs under `test/`, `benchmark/` and `packages/*/test/` is the same on master 84f5b5020 and here (three differ only in the path of the build's own directory, which they print); optcarrot's is byte-identical.

`test/string_handle_struct_splat_root.rb` counts the wrong objects through the three constructions, kept and looked at one construction later, then through a literal beside a Float's own `-@` (clang is where that one shows: gcc builds the list in the other order), and through a default that reads a global and adds to it, which runs nothing. On master (84f5b5020) it prints a wrong line in a plain run with exit 0 built with gcc and ends in SIGSEGV built with clang, ends in SIGSEGV at level 1, and aborts at level 2 and with the verifier; with this change it prints its `.expected` in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang. It is added to `GC_STRESS_TESTS`. With `--share-strings` master prints the wrong line with exit 0 in a plain run and at level 1 built with gcc (built with clang it ends in SIGSEGV in the plain run) and aborts at level 2 and with the verifier; this change prints the `.expected` in the same seven lanes.

**Not in this change**, on master and here alike, with the same generated C:

- A String a call makes, handed to a Struct for such a member (`Entry.new(+"w", +"v")`): 2 of 3,000 wrong in a plain run, 2,995 at level 1, an abort at level 2.
- A literal after a splat, or a second splat, into a class's `new` (`K.new(0, *qa, "r")`, `Pair.new(*qa, *ra)`): 1 of 2,000 wrong in a plain run, all 2,000 at level 1, an abort at level 2. A number after the splat (`Pn.new(*qa, -i)`) is right in a plain run and at level 1 and aborts at level 2. The same list into an ordinary method is right where one parameter is bound to such a String. With two it loses a handle too: with `def mkp(x, y) = U.new.put(x, y)`, `mkp(*qa, "r")` is right in a plain run, wrong in 1,999 of 2,000 at level 1 and aborts at level 2, and `mkp(*qa, *ra)` is wrong in 1, in 1,997, and aborts.
- A literal beside two calls' Strings (`Three.new(lg("1"), lg("2"), "lit")`): 1 of 2,000 wrong in a plain run, all 2,000 at level 1, an abort at level 2.
- A splat into a rest parameter of a class's `new` (`Rs.new(*qr)`): right in a plain run and at level 1, an abort at level 2.
- A splat or a keyword splat into a Struct's `new` (`Entry.new(*args)`, `KwE.new(**h)`): a later `e.a << "z"` does not reach the String the caller holds, in a plain run.
- The order of effects, which this change leaves as master has it. With a Struct of three members, the first changed in place, `Three.new(s, (s = "bb"; "x"), s)` prints `["bb", "x", "bb"]` for `["aa", "x", "bb"]`. Two defaults that have effects, filled from an empty splat, run in C's argument order built with gcc. A counter kept in a `catch` block that a `throw` leaves prints 33 for 35. Each prints the same wrong line on master and here in a plain run. At level 2 the `catch` program aborts on master, its handle held by nothing; here the handle is held and it prints the 33 of its plain run. The two-defaults program aborts at level 2 on both.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master 84f5b5020, built from nothing: the test in the seven collector lanes with gcc and clang, with and without `--share-strings`; `ruby tools/gate.rb check`; the generated C of the 6,608 programs, compared as above; optcarrot, checksum 59662; `make share-strings-test` and `make int-min-test`, both pass; the cost table and the programs named above, gcc and clang, at levels 0, 1 and 2; the compiler's own instructions over the test, 470,391,096 on master and 470,736,205 here.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal` (seven lines of `0` and the two lines of changed members); CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change. It depends on no other pull request: "A parenthesized sequence keeps its place when its tail converts an argument", which the declarations this change adds at two more places need, is in master.
