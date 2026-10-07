<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A refusal with a cost, which is yours to weigh: 26 of the 696 programs measured are right on master and refused here. In each a local that holds a String handle is rebound by a pattern to a String that a variable, a field or an element holds, and neither String is changed or compared afterwards.

```ruby
class Page
  attr_reader :text
  def initialize
    @text = +"k"
  end
end
k = Page.new
line = +"zz"
s = k.text << "a"
case line
in String => s
  s << "!"
end
p line     # "zz!" in CRuby, "zz" on master
```

`in String => s` binds s to the subject itself. s holds the reader's String by a handle, and `emit_pattern_bind_handle` gives such a local the subject's own handle when the subject is a variable that holds one, and a fresh handle over the subject's text otherwise. Under `--share-strings` the share facts join the local with the subject, so a variable subject has the handle. Without the flag nothing joins them: `line` is a plain String, s takes a copy, and the append is lost with nothing said. The same binding onto a local that is appended to in place and holds no shared handle (`t = +""; t << "a"`) does not build: the subject's `const char *` goes into an `sp_String *` slot.

What was chosen: CONTRIBUTING asks that a route that silently copies a String be refused at compile time and that no per-route sharing rule be added. So without `--share-strings` the binding is refused by name where the local holds a handle or is appended to in place, and the subject names a String someone else holds: a variable, a reader's field (an `attr_reader`, a Struct member), an Array's or a Hash's element (`[]`, `at`, `first`, `last`, `fetch`).

```
a String variable a pattern binds to its subject is mutated in place, or names a String that is (a String is not yet shared by reference through a pattern's binding). Assign the subject to the variable instead.
```

The assignment the message names is right on master: `s = line` joins the two (`promote_local_alias_pairs`). A variable that holds the handle still hands it over, any other subject (a call's value, an interpolation, a `dup`) is still taken for a new String, and under `--share-strings` nothing changes: the generated C is the same, and the two reject tests compile and run right there (`test/share/reject.list`).

Not here, each wrong on master and the same here:

- two plain Strings: `case line in String => s; s << "!"` where s holds no handle. The append makes a new String for s and `line` keeps the old one (72 programs);
- a constant, a class variable's reader or a method that returns a reader's String as the subject, which the assignment copies as well (48);
- a Symbol-keyed Hash's element, whose value is boxed and does not come through this arm (36);
- under `--share-strings`, a reader call as the subject (`case k2.text in String => s`) takes a copy (24 of the 306 measured there).

Tests: `test/reject/string_pattern_bind_subject.rb` is the program above and `test/reject/string_pattern_bind_appended_local.rb` the one that did not build; both are in `reject-test`, with their four records in `test/collect/refusals.expected`, and in `test/share/reject.list` with the output they have under the flag. `test/pattern_bind_string_handle.rb` holds what stays: a subject that is a local holding a handle, bound with and without a class, a call's value, an interpolation, a `dup`, and an arm that does not match. It is right on master and here.

Generated C against master (`make cident REF=9274c732`): `6420 identical, 0 differ, 0 refusal changes` (the new test's C is master's). `tools/refusals.sh` passes (540 records); `make reject-test` and `make share-strings-test` pass. optcarrot's generated C is byte-identical. Programs of ours, on master 9274c732 with CRuby 3.3.6 as the reference: 696 whole-subject bindings (24 kinds of subject, a local that holds a reader's handle, one appended to before, one first bound by the pattern; an append through the local, one through the subject, `equal?`, nothing, an append after the `case`; `in String => s` and `in s`). 92 that printed a wrong answer are refused, 72 that did not build are refused by name, and the 26 above are refused. The other 506 are the same, with master's C byte for byte: 322 right, 156 wrong and 28 that do not build (a local appended to in place, bound to a subject outside that list). Of the 92, 46 were also measured on master 5c78f07e, before the pull request "The share facts follow break and next values, patterns, global aliases and builtin containers" was merged: they did not build there. Under `--share-strings`, 486 of them: each has master's output; the C is identical for the 456 that compile.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the tests print Strings and true)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
