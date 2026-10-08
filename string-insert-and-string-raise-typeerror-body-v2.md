<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

The cost first: a `String#[]=` or `insert` whose value may be nil pays one compare, 1,031 to 1,033 instructions a `s[1] = v` statement (callgrind; the same two with gcc and clang, and for a Range, a String key and a start and length; four where the length is a variable, which is tested for its sign first). No list cuts it further: the compare is emitted only where the analysis cannot prove the value a String, and there the compare is the fix. A literal, an interpolation and a local that only ever holds a String store with the C they had.

```ruby
def none(k) = k == 1 ? +"one" : nil
m = +"abc"; m[1] = none(2); p m          # CRuby TypeError, no implicit conversion of nil into String; here "ac"
m = +"abc"; m.insert(1, none(2)); p m    # CRuby the same TypeError; here "abc"
m = +"abc"; p m.insert(1, none(2))       # CRuby the same TypeError; here "abc"
```

A String-typed value that is nil when the program runs was spliced in as "": on a String in a local, an instance variable or a global, every form of `String#[]=` (an index, a start and length, a Range, a String key, a pattern) cut its span and put nothing there, and `insert` left the String as it was. The splice now tests such a value where CRuby converts it: ahead of an index outside the String and of a frozen String; behind a negative length, a Range's start check, a String key's "string not matched" and a pattern that does not match. The second commit does the same for `insert` whose value is taken.

"May be nil" is the nil fact, read through `repr_of`'s `may_nil`; nothing is added to it. Two existing tests change their generated C and print what they printed.

Left as they are: a receiver that is boxed, an Array's element or a Hash's value (`a[0][1] = v`) still stores "", in other emitters; a nil value on a frozen String under a String key or a pattern, or on a String frozen through a second name (`t = s; t.freeze`), is still the FrozenError (CRuby TypeError); a value the nil fact takes as never nil without proof (`ENV["X"]`) is still spliced as ""; the Regexp group form `s[/(b)/, 1] = v` is in "String#[]= with a Regexp group raises for a missing group or nil"; `<<`, `prepend`, `replace` and `concat` take a nil argument as they did, in another emitter.

This stands on "String#[]= with a Range starting outside the String raises RangeError": the Range arm's test goes behind that pull request's start check.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
