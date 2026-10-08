<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`push` as a statement on a boxed String or Integer ran the receiver's `<<` where CRuby raises:

```ruby
v = [+"s", 5][0]
v.push("!")
p v   # "s"; CRuby: undefined method 'push' for an instance of String (NoMethodError)
```

`push` and `append` with one argument, as a statement on a boxed receiver, were emitted as `sp_poly_shl`. That is right for an Array and for a queue. A String and an Integer answer `<<` themselves, so `v.push("!")` ran the String's `<<` and `v.push(1)` shifted the Integer, with no NoMethodError; a Float, a Symbol, nil or a Hash raised it naming `<<`. The value form (`r = v.push("!")`) and `push` with another argument count already test the receiver at run time. The statement now does too, in `sp_poly_push_stmt`: an Array appends, a queue takes a push, anything else raises naming the method sent. `<<` is emitted as before.

A push statement on a boxed Array is cheaper than before: its Array arms stand in front, where through `sp_poly_shl` they stood behind the Proc, user class and yielder tests. By callgrind a loop pass of `row[0].push(1)` on an Integer Array runs 42 instructions on master and 29 here with gcc, 46 and 37 with clang; `<<` runs master's count. The arms are `sp_poly_shl`'s, repeated in `sp_poly_ary_append`: called from `sp_poly_shl` they made a loop pass of two `<<` statements dearer with gcc, 168 instructions for 158.

Only such statements change: 29 programs of the corpus, the new test among them, optcarrot not among them; with `--share-strings` it is the same change in fewer programs, as some of the 29 do not compile with the flag, on master or here.

Not here: `x&.push(6)` as a statement on a boxed nil raises NoMethodError, as on master, where CRuby does nothing; a class with `method_missing` and no `push` raises where CRuby runs `method_missing`, as on master.

The test prints the messages, in CRuby 4.0's wording (`'push'`).

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on Linux (x86_64, gcc 13.3.0, ruby 3.3.6), on master 9c7ea3ce0 merged with this branch's commit (cfe05e34a): the build; `tools/gate.rb check`; the new test in eighteen cells (gcc and clang; the default mode, `--int-overflow=promote` and `--share-strings`; `SPINEL_GC_STRESS` unset, 1 and 2); `tools/cident.sh` against master (29 of 6,514 corpus programs differ in the default mode, 29 with `--int-overflow=promote`, 22 with `--share-strings`; every other program that compiles, optcarrot among them, gives the same C); and the legs `share-strings-test` and `int-min-test` alone, which pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (not run under CRuby 4.0 here; ruby 3.3.6 with that flag prints `test/boxed_push_statement.rb.expected` but for 8 lines whose message quotes a name: 3.3 opens the quote with a backquote, 3.4 and later with an apostrophe, as the file has)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: `tools/cident.sh` finds it byte-identical to master's at 9c7ea3ce0)
- [ ] Depends on: # (nothing)
