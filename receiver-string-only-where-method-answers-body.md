<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A refusal lifted under `--share-strings`, and no sharing rule added: the analysis learns that a receiver a call hands back is no String. Its answer only goes from "may be a String" to "is none", no route changes, and a program built without the flag keeps its C. A program the refusal stopped now answers what it answers without the flag.

```ruby
Pair = Struct.new(:a)
def pick(i) = [["a"], { 0 => "a" }][i]
y = pick(ARGV.size)
y[0] += "b"
p y
```

Under `--share-strings` this was refused: "the Strings this literal holds are shared with another name and changed in place, and a typed String container cannot hold the shared handle yet". Without the flag it prints `["ab"]`, as CRuby does, and with this change it does so under the flag too. No String is changed in place here: `y` is an Array or a Hash.

With a Struct in the program, `y[0] += "b"` is written out as `y[0]` and `y[0] = ...`, since a Struct's `[]=` may be its target, and `[]=` is a String mutator's name. On a boxed receiver that name counts where the receiver may be a String. `an_recv_may_be_string` read a variable's values by their form only as far as literals and conditionals, so what a call hands back was "may be one".

A call is read now where its form proves it (`poly_call_no_string`). An index into an Array literal is one of its elements. A call on self from the top level, or from a method defined there, is the value of the methods of that name: each one's last statement and each `return`. Everything else answers as before: a call that carries a block (a `break` in it is the call's value), a method with a rescue or an ensure clause, and a name the program reaches some other way, which `dyn_callable_index` already knows (a Symbol or a String argument spells it, an alias, a name it computes).

Compile time: the question is asked through the indexes `dyn_callable_index` already builds once a pass. A program of 400 such methods and 800 writes compiles in 0.4% more instructions under the flag, with the same C.

Test: `test/share_strings_op_write_boxed_call.rb`, which master refuses under `--share-strings`; it runs in `make test` and in `make share-strings-test`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
