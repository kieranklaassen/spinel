<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** "Shared String argument conversions stay rooted across calls" keeps the handle a literal or a bare read gets when an ordinary call binds it to a String changed in place. Two ways of handing a String over do not pass through that code and still lose the handle, in a plain run: a Struct's `new` given two or more such Strings, and an element of a splatted Array handed to a class's `new`. The cost is a rooted temp for each such String where its handle can be lost: 10 to 37 instructions a construction for a Struct built with gcc and 20 to 46 with clang, 15 to 43 and 20 to 47 for a splat (the table is below). A construction that makes one handle only, and a splat into an ordinary method, compile as they did.

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

- A Struct's member (`emit_struct_new_call`) asks `arg_read_converts`, as an argument does, and is held only where two or more of the member values are made in the list by something that allocates: another converted literal or read, a spread Hash, a call that is not hoisted into a rooted temp of its own. `One.new("alpha")`, `Mixed.new("alpha", i)` and `Mixed.new("alpha", 7)` keep master's C.
- A splat's element (`emit_elem_param`) is held for a class's `new`, and for another callee only where a second value of the list is made in place. From the dispatch it is never held: the dispatch binds each argument to a rooted temp of its own. `mk(*qa)`, `mk2(7, *ra)`, `mkp(*qr)`, `U.new.set(*qa)`, `U.new.put(*qr)` and the same methods called on self keep master's C.

A value that is a handle already, or nil, gets no temp.

The cost, callgrind on master (74fa6d7c2), 200,000 constructions each, in instructions a construction:

| construction | gcc | clang | master's answer |
|---|---|---|---|
| `Entry.new("alpha", "beta")`, two members | 24 | 32 | wrong |
| `Three.new("a1", "b1", "c1")`, three members | 37 | 46 | wrong |
| `KwE.new(a: "alpha", b: "beta")`, by keyword | 28 | 38 | wrong |
| `Mixed.new("alpha", sz(i))`, a literal beside a call | 10 | 20 | right with this `sz`; see below |
| `Pair.new("q", *ra)`, one element | 24 | 20 | wrong |
| `Pair.new(*qr)`, two elements | 43 | 46 | wrong |
| `Tail.new(*qa)`, one element and the default | 41 | 47 | wrong |
| `Uno.new(*qa)`, one element | 15 | 21 | right in a plain run and at level 1, aborts at level 2 |
| `One.new("alpha")`, `Mixed.new("alpha", i)`, `Entry.new(w, v)`, `Pair.new("q", "r")` | 0 | 0 | right |
| `mk(*qa)`, `mk2(7, *ra)`, `mkp(*qr)`, `U.new.set(*qa)`, `U.new.put(*qr)` | 0 | 0 | right |

One row pays and can be right without it. In `Mixed.new("alpha", sz(i))` the literal's handle is lost only where `sz` allocates an object and the C compiler runs it after the handle is made. With `def sz(i) = ("k" * (i % 5 + 1)).size` master is right at every level, gcc and clang. With `def sz(i) = ["a" + i.to_s, "b" + i.to_s, "c"].size` master built with clang crashes in a plain run and aborts at level 2, and is right with this change. What a call allocates is not known where it is emitted, so the member is held beside any call that is not hoisted.

The generated C of the 6,597 other programs under `test/`, `benchmark/` and `packages/*/test/` is the same on master 74fa6d7c2 and here (three differ only in the path of the build's own directory, which they print); optcarrot's is byte-identical.

`test/string_handle_struct_splat_root.rb` counts the wrong objects through the three constructions, kept and looked at one construction later. On master (74fa6d7c2, gcc and clang) it prints a wrong line in a plain run with exit 0, ends in SIGSEGV at level 1, and aborts at level 2 and with the verifier; with this change it prints its `.expected` in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang. It is added to `GC_STRESS_TESTS`. With `--share-strings` master prints the wrong line with exit 0 in a plain run and at level 1 and aborts at level 2 and with the verifier; this change prints the `.expected` in the same seven lanes.

**Not in this change**, on master and here alike, with the same generated C:

- A String a call makes, handed to a Struct for such a member (`Entry.new(+"w", +"v")`): 2 of 3,000 wrong in a plain run, 2,995 at level 1, an abort at level 2.
- A literal after a splat, or a second splat, into a class's `new` (`K.new(0, *qa, "r")`, `Pair.new(*qa, *ra)`): 1 of 2,000 wrong in a plain run, all 2,000 at level 1, an abort at level 2. The same list into an ordinary method (`mkp(*qa, "r")`) is right.
- A literal beside two calls' Strings (`Three.new(lg("1"), lg("2"), "lit")`): 1 of 2,000 wrong in a plain run, all 2,000 at level 1, an abort at level 2.
- A splat into a rest parameter of a class's `new` (`Rs.new(*qr)`): right in a plain run and at level 1, an abort at level 2.
- A splat or a keyword splat into a Struct's `new` (`Entry.new(*args)`, `KwE.new(**h)`): a later `e.a << "z"` does not reach the String the caller holds, in a plain run.
- The order of effects, which this change leaves as master has it. `Entry.new(s, (s = "bb"; "x"), s)` prints `["bb", "x", "bb"]` for `["aa", "x", "bb"]`. Two defaults that have effects, filled from an empty splat, run in C's argument order built with gcc. A counter kept in a `catch` block that a `throw` leaves prints 33 for 35. Each prints the same wrong line on master and here in a plain run. At level 2 the `catch` program aborts on master, its handle held by nothing; here the handle is held and it prints the 33 of its plain run. The two-defaults program aborts at level 2 on both.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master 74fa6d7c2, built from nothing: the test in the seven collector lanes with gcc and clang, with and without `--share-strings`; `ruby tools/gate.rb check`; the generated C of the 6,597 programs, compared as above; optcarrot, checksum 59662; `make share-strings-test` and `make int-min-test`, both pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal` (five lines of `0` and the changed members); CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change. It depends on no other pull request: "A parenthesized sequence keeps its place when its tail converts an argument", which the declarations this change adds at two more places need, is in master.
