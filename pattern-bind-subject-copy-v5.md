<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Since the commit "Array.new(a) is not followed, and a whole-String pattern binding takes the subject's handle", a pattern that binds its whole subject to a local holding a String handle gives the local a copy where the subject has no handle to hand over. Of 696 such bindings, compared with master 5c78f07e, from before its pull request was merged: without `--share-strings` 116 that did not build now print a wrong answer, and with the flag 20 that were right now print a wrong one. This refuses 92 of the 116 and 8 of the 20; the rest have a constant, a class variable's reader or a method that returns a reader's String as the subject and are listed below.

A refusal with a cost, which is yours to weigh: of 1,032 programs (the 696 and 336 more), 78 without the flag and 18 with it are right on master and refused here. In each a local is rebound by the pattern to a String that someone else holds, and neither String is appended to or asked `equal?` afterwards: the two are only printed, or compared with `==`, or the local is assigned again before anything is appended to it. A copy cannot be told from the subject there. The same binding followed by an append through either name is the wrong answer above.

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

`in String => s` binds s to the subject itself. s holds the reader's String by a handle, and `emit_pattern_bind_handle` gives such a local the subject's own handle when the subject is a variable that holds one, and a fresh handle over the subject's text otherwise. Under `--share-strings` the share facts join the local with the subject, so a variable has the handle; a reader call as the subject (`case other.text`) is not followed and is copied. Without the flag nothing joins them: `line` is a plain String, s takes a copy, and the append is lost with nothing said. The same binding onto a local that is appended to in place and holds no shared handle (`t = +""; t << "a"`) does not build without the flag: the subject's `const char *` goes into an `sp_String *` slot.

What was chosen: CONTRIBUTING asks that a route that silently copies a String be refused at compile time and that no per-route sharing rule be added. So the binding is refused by name where the local holds a handle or is appended to in place, and the subject names a String someone else holds: a variable, a reader's field (an `attr_reader`, a Struct member), an Array's or a Hash's element (`[]`, `at`, `first`, `last`, `fetch`). The refusal goes through `share_route_defer`, as the other routes' do: without the flag it stands; under the flag the share facts decide, and of the subjects measured only the reader call is refused. Two bindings are let through: a variable in parentheses (`case (line)`) is the variable and hands its handle over, where master took a copy; and an arm whose test is already known to fail (`in Integer => s` on a String) never binds.

```
a String variable a pattern binds to its subject is mutated in place, or names a String that is (a String is not yet shared by reference through a pattern's binding). Assign the subject to the variable instead.
```

The assignment the message names is right on master in both modes: `s = line` joins the two (`promote_local_alias_pairs`), and under the flag `s = other.text` does. A variable that holds the handle still hands it over, and any other subject (a call's value, an interpolation, a `dup`) is still taken for a new String, with master's C.

Not here, each wrong on master and the same here:

- a constant, a class variable's reader (`Box.cur`) or a method that returns a reader's String as the subject. Without the flag the assignment copies it as well (`s = LINE; s << "!"`), so the message would name a program that is wrong too (48 programs; 24 did not build before the commit). Under the flag 72 are wrong, and 12 of them were right before the commit, so those stay a regression here: 4 with a constant, 4 with a class variable's reader, 4 with a method that returns a reader's String. The constant has the handle in its slot and is a fix of its own, sent apart. For the other two the assignment is wrong under the flag as well: a call that returns a held String is not told from one that returns a new one;
- two plain Strings without the flag: `case line in String => s; s << "!"` where s holds no handle. The append makes a new String for s and `line` keeps the old one (72 programs, wrong before the commit too);
- a Symbol-keyed Hash's element without the flag, whose value is boxed and does not come through this arm (36).

Tests: `test/reject/string_pattern_bind_subject.rb` is the program above and `test/reject/string_pattern_bind_appended_local.rb` the one that did not build; both are in `reject-test` and, compiling right under the flag, in `test/share/reject.list` with their output there. `test/reject/string_pattern_bind_reader_subject.rb` has a reader call as the subject and is refused in both modes; `reject-test` runs it without the flag. The refusal under the flag has no harness upstream and was run by hand (`bin/spinel --share-strings test/reject/string_pattern_bind_reader_subject.rb -c -o /dev/null` refuses with the same message). Their six records are in `test/collect/refusals.expected`. `test/pattern_bind_string_handle.rb` holds what stays: a subject that is a local holding a handle, bound with and without a class and in parentheses, a call's value, an interpolation, a `dup`, an arm that does not match and one whose class a String can never be. Two of its lines, the subject in parentheses, differ on master.

Generated C against master (`make cident REF=8dc55225`): `6447 identical, 1 differ, 0 refusal changes` (the new test, for its subject in parentheses). `tools/refusals.sh` passes (542 records); `make reject-test` and `make share-strings-test` pass. optcarrot's generated C is byte-identical. Programs of ours, on master 8dc55225 with CRuby 3.3.6 as the reference: 1,032 whole-subject bindings. 696 are 24 kinds of subject; a local that holds a reader's handle, one appended to before, one first bound by the pattern; an append through the local, one through the subject, `equal?`, nothing, an append after the `case`; `in String => s` and `in s`. 336 more have the two compared with `==` after the `case`, the local assigned again and then appended to, and an arm of another class (`in Integer => s`).

| | without the flag | with `--share-strings` |
|---|---|---|
| wrong on master, refused | 92 | 24 |
| wrong on master, right (the variable in parentheses) | 0 | 24 |
| no build on master, refused by name | 80 | 0 |
| right on master, refused (the cost) | 78 | 18 |
| right on both, the variable in parentheses hands its handle over | 0 | 20 |
| the same, right | 597 | 814 |
| the same, wrong | 156 | 72 |
| the same, no build or refused by master | 29 | 60 |

Every program in the last three rows that compiles has master's C byte for byte (782 and 902). Of the 78, 26 only print the two Strings, 26 compare them with `==` and 26 assign the local again; of the 18, 6 each, and each of the 18 is right on master at the three stress levels (`SPINEL_GC_STRESS` unset, 1 and 2). The 29 are a local appended to in place, bound to a subject outside the list; the 60 are 44 that master refuses (a Struct member as the subject) and 16 of those. None of the 48 with an arm of another class is refused.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the tests print Strings and true)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
