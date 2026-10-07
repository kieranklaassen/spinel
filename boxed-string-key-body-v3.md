<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
b = [+"abc", 1][0]
b["b"] = "x"; p b       # CRuby "axc"; here "abc"
b["q"] = "x"            # CRuby IndexError, string not matched; here nothing
a = [+"abc", 1]; k = ["b", 1][0]
a[0][k] = "x"           # CRuby "axc"; here TypeError, no implicit conversion of String into Integer
```

A boxed receiver's `recv["key"] = v` goes to `sp_poly_set_str`, and to `sp_poly_set_poly` with the key boxed; each stores into a Hash or an OpenStruct and answers for anything else. Both now pass a String receiver to one `sp_poly_str_aset`, which replaces the first occurrence or raises the IndexError, and the new contents are stored back where the Integer key's arm stores them. `lib/spinel_rt.h` only gains lines.

A boxed Hash pays for the look at its receiver: 182 instructions a `h["k"] = i` before, 194 after (callgrind). 30 existing tests change their generated C and print what they printed.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
