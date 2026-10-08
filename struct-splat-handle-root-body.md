<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** "Shared String argument conversions stay rooted across calls" keeps the handle a literal or a bare read gets when an ordinary call binds it to a String changed in place. Two ways of handing a String over do not pass through that code and still lose the handle, in a plain run: a Struct's `new`, and an element of a splatted Array. The cost is a rooted temp for each such String: 15 to 17 instructions a Struct member, 15 to 27 a splat's element (the table is below).

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

`e.a << "z"` makes the members Strings changed in place, so each holds its String through a handle, and the constructor wraps each literal in one: `sp_Entry_new(sp_String_new_shared("alpha"), sp_String_new_shared("beta"))`. Nothing holds the first handle while the second is allocated, nor either while `sp_Entry_new` allocates the object.

A class whose member is changed in place loses an element that comes out of a splat the same way, and the default a short splat leaves to fill:

```ruby
ra = ["r"]
qa = ["q"]
20_000.times { pairs << Pair.new("q", *ra) }   # 4 of them wrong on master with gcc, 19,996 at level 1
20_000.times { tails << Tail.new(*qa) }        # def initialize(x, y = "r"): 4 wrong, 19,996 at level 1
```

Both now take the form the ordinary call has (`emit_rooted_conversion`): the temp's declaration and its root go ahead of the statement, and the handle is made and assigned where the value stands.

```c
sp_String * _t7 = NULL; SP_GC_ROOT(_t7);
sp_String * _t8 = NULL; SP_GC_ROOT(_t8);
... sp_Entry_new((_t7 = sp_String_new_shared("alpha")), (_t8 = sp_String_new_shared("beta")))
```

The Struct's member asks `arg_read_converts`, as an argument does: a value that is a handle already, or nil, gets no temp.

The cost, callgrind on master (9922a2c74) with the pull request below beneath, 200,000 constructions each, in instructions a construction:

| construction | gcc | clang | master's answer |
|---|---|---|---|
| `Entry.new("alpha", "beta")`, two members | 30 | 34 | wrong |
| `Pair.new("q", *ra)`, one element | 27 | 15 | wrong |
| `Tail.new(*qa)`, one element and the default | 31 | 37 | wrong |
| `Entry.new(w, v)`, two handles | 0 | 0 | right |
| `Point.new(i, 2)`, two Integers | 0 | 0 | right |

No program under `test/`, `benchmark/` or `packages/*/test/` hands a String over in either way to a member changed in place: the generated C of all 6,531 is equal to that of the pull request below, optcarrot's among them.

`test/string_handle_struct_splat_root.rb` counts the wrong objects through the three constructions, kept and looked at one construction later. On master (9922a2c74, gcc and clang) it prints a wrong line in a plain run with exit 0, ends in SIGSEGV at level 1, and aborts at level 2 and with the verifier; with this change it prints its `.expected` in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang. It is added to `GC_STRESS_TESTS`. With `--share-strings` the test is refused, on master and here: the flag does not carry a Struct member changed in place yet. Its splat rows alone build under the flag, and their generated C is equal to master's.

**Not in this change**, on master and here alike: a String a call makes, handed to a Struct for such a member (`Entry.new(+"w", +"v")`), stops at `SPINEL_GC_STRESS=2`; and with a splat in the middle of the arguments (`K.new(0, *qa, "r")`) the objects still come out wrong at level 1.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit, one above the pull request it depends on, on master 9922a2c74, built from nothing: the test in the seven collector lanes with gcc and clang, on master and on this change; `ruby tools/gate.rb check`; the generated C of the 6,531 programs, equal to the commit below's for every one; optcarrot, checksum 59662; `make share-strings-test` and `make int-min-test`, both pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal` (five lines of `0` and the changed members); CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change. It depends on the pull request "A parenthesized sequence keeps its place when its tail converts an argument": this is one commit above it, and the declarations this change adds at two more places would move a parenthesized sequence ahead without it.
