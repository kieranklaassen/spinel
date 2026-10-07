<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A String as the index of a boxed Symbol answered nil where CRuby answers the substring:

```ruby
def pick(n) = n > 0 ? {a: 1} : :stone
s = pick(0)
p s["ton"]   # nil; CRuby: "ton"
```

`Symbol#[]` is `String#[]` on the Symbol's name. `sp_poly_get_str` answers the substring for a String and for a shared String, and answered nil for a Symbol with every other value that is no object. A Symbol now answers as its name does, for a String the program appends to as well, with a copy of the index: CRuby's answer is a new String, never the index itself.

The search is out of line, behind the test for a value that is no object which the function already makes, so a Hash's read meets no new test. By callgrind a loop reading `h[:a]` and `g["a"]` from boxed Hashes runs 223 instructions a pass on master and 223 here with gcc, 214 and 214 with clang; two String reads of one String-keyed boxed Hash run 325 and 323, 305 and 303.

Of the 174 programs of a 1,748-program family whose C calls this function, 9 are cured and none that was right is lost: 107 are right on master and here, and the other 58 print the same bytes on both.

Not here: a Symbol index on the boxed Symbol (`s[:a]`) still answers nil, where CRuby raises TypeError; an appended String that reaches the read boxed (`j = [k, 0][0]; s[j]` after `k << "n"`) still answers the name's first character, "s" where CRuby prints "ton". That read is `sp_poly_index_poly`'s.

No generated C changes: the function is in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
