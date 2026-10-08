<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
y = "zz".dup
z = "ab".dup
p y.sub!("q", z.sub("a", "b"))                     # "zz", CRuby: nil

x = "ab".dup
p x.gsub!("a") { y.sub!("q", "-") ? "b" : "a" }    # nil, CRuby: "ab"
```

A plain run, gcc and clang. Cost: a `sub!` or `gsub!` that has a call among its operands, or is not all that its statement runs, takes one instruction more a call at most (0.1% of the call, callgrind), and such a call with a block two to five (0.4% at most; fewer than before in two of the three loops measured with clang). A `sub!` or `gsub!` that is alone in its statement with literals or reads for operands, and every `sub` and `gsub`, compile to the C they did.

`sub!` and `gsub!` answer nil when no substitution was made. The text cannot say that, since a match may write the same bytes, so they read the runtime's flag `sp_re_sub_matched`. The flag is cleared ahead of the statement, before the call's operands run: a `sub` or `gsub` that the receiver, an argument, the pattern or a `to_str` conversion of one runs left its own answer there, and the first call above answered for `z.sub`'s match. So did one beside the call in the same statement: `"#{z.sub("a", "a")} #{y.sub!("q", "-").inspect}"` printed `ab "zz"`. A block form's loop sets the flag before the block runs, where a `sub!` or `gsub!` whose answer is read clears it: the second call lost its own match.

Such a call now enters the runtime through a wrapper that clears the flag after the operands have run (`sp_str_sub_own` and its kin, static inline in `spinel_rt.h`), and a block form answers from a C local of its loop, which the block cannot reach. The arm that emits the bang names the call, and the emitters of `sub` and `gsub` take the wrapper for that call alone, so it is reached inside the temporaries that hold the receiver of an instance, a class or a global variable too.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
+"zz"
 nil
-"ab"
```

The calls left as they were: one that is all its statement runs (`if x.sub!(a, b)`, `v = x.sub!(a, b)`, `p x.sub!(a, b)`) with a receiver, arguments and a block's body that are literals or plain reads of a String or a Regexp: a variable, a constant, a global, an element of an Array of Strings at an Integer index, a reader no method of the program stands over (a boxed pattern too, and a boxed replacement in a program that defines no `to_str`); nothing there can run a `sub` between the clear and the answer. The runtime library is unchanged byte for byte (every member of `libspinel_rt.a` and `libspinel_rt_mt.a`). Of the corpus the generated C of twelve programs changes (`tools/cident.sh`): the new test and eleven tests that read a bang's answer beside another operand, or whose bang has a call for its receiver, among its arguments or in its block. optcarrot's C is unchanged.

Test: `test/sub_bang_answers_by_its_own_match.rb`.

Not here: a Hash for the replacement reads the flag as before, in both directions: `y.sub!(z.sub("ab", "q"), { "q" => "r" })` answers y where CRuby answers nil, and `s.sub!("a", { "a" => "a" })` nil where CRuby answers s. And a receiver that is an Array's element, a block parameter bound to one (`xs.each { |e| p e.sub!("a", "a") }`), a Hash's value or a boxed value reads no flag at all: `a[0].sub!("a", "a")` answers nil for `"ab"`. And a `sub!` or `gsub!` that is the last expression of a block given to a method of the program's own that yields is lowered as a statement and answers its receiver: after `def w = yield`, `p(w { y.sub!("q", "r") })` prints `"zz"` where CRuby prints nil.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on the commit replayed on master `16bca08960d1` (its tree is that of this branch merged with it), gcc and clang: the new test at `SPINEL_GC_STRESS` unset, 1 and 2 (also with `--share-strings`); `tools/gate.rb check` with the commit staged; `tools/cident.sh` against master (twelve programs differ, as above; the eleven corpus tests among them answer as they do on master); `make share-strings-test`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: nothing
