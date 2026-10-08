<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A String as the index of a boxed Symbol answered nil where CRuby answers the substring:

```ruby
def pick(n) = n > 0 ? {a: 1} : :stone
s = pick(0)
p s["ton"]   # nil; CRuby: "ton"
```

The fix costs a read that is right on master: a boxed Symbol read by a String its name does not hold. It answered nil without looking at the name, 23 instructions a loop pass with gcc and 33 with clang; it now looks, 98 and 106 (105 and 114 when the index starts as the name does, 133 and 138 when it is longer than the name). The look goes through the name, so it grows with it: 371 and 380 for a name of 43 letters, 714 and 723 where every letter of the name is a false start (`"aac"` in thirty-one a's and a b). The same three misses on a boxed String cost 95, 315 and 1,125 on master with gcc. And with clang a loop that reads a Symbol-keyed boxed Hash by a Symbol and then misses it by a String runs 153 instructions a pass on master and 156 here (138 and 135 with gcc).

`Symbol#[]` is `String#[]` on the Symbol's name. `sp_poly_get_str` answers the substring for a String and for a shared String, and answered nil for a Symbol with every other value that is no object. A Symbol now answers the substring its name holds, for a String the program appends to as well, with a copy of the index: CRuby's answer is a new String, never the index itself. An index that is not whole characters is nil though the name holds its bytes (`"\xC3"` into `:"héllo"`): CRuby's search refuses one.

The work is out of line, behind the test for a value that is no object which the function already makes, so a Hash's read meets no new test. An index the name does not hold is the read a value that is a Hash elsewhere makes, so it is answered before the search and the copy. By callgrind a loop reading `h[:a]` and `g["a"]` from boxed Hashes runs 223 instructions a pass on master and 223 here with gcc, 214 and 214 with clang; one String read of a String-keyed boxed Hash 139 and 139, 149 and 149; two of them 325 and 323, 305 and 303.

Of 4,496 programs that read a boxed receiver by an index of every kind, 77 reach the new arm: 39 are cured and 38 are right on master and here. Of 45 more, a boxed Symbol of nine names read by 29 Strings in five forms, all are right here. Of 1,116 more reads, six names with characters of two to four bytes read by 31 Strings in six forms, 17 of the Strings not whole characters, 132 answered nil and print CRuby's line here; the other 984 are right on master and here.

Not here: a Symbol index on the boxed Symbol (`s[:a]`) still answers nil, where CRuby raises TypeError; an appended String that reaches the read boxed (`j = [k, 0][0]; s[j]` after `k << "n"`) still answers the name's first character, "s" where CRuby prints "ton". That read is `sp_poly_index_poly`'s. And `a = [s[k], s[k]]; a[0] << "1"` prints `["ton", "ton"]`, as an Array of two boxed Strings does on master (CRuby: `["ton1", "ton"]`). A binary index with a byte past ASCII that the name holds (`s["é".b]`) is nil as it was, where CRuby raises Encoding::CompatibilityError. A String, boxed or not, answers an index that is not whole characters when it holds the bytes (`"héllo"["\xC3"]` is `"\xC3"`; CRuby: nil), on master and here: the Symbol does not follow its name there.

No generated C changes: the function is in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
