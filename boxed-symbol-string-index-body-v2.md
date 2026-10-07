<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A String as the index of a boxed Symbol answered nil where CRuby answers the substring:

```ruby
def pick(n) = n > 0 ? {a: 1} : :stone
s = pick(0)
p s["ton"]   # nil; CRuby: "ton"
```

`Symbol#[]` is `String#[]` on the Symbol's name. `sp_poly_get_str` answers the substring for a String and for a shared String, and answered nil for a Symbol with every other value that is no object. A Symbol now answers as its name does, for a String the program appends to as well. The test stands where the receiver is already known to be no object, so a Hash's read does not meet it: by callgrind a loop reading `h[:a]` and `g["a"]` from boxed Hashes runs 223 instructions an iteration on master and 222 here with gcc, 214 and 212 with clang.

Of 1,748 programs that read a boxed value by a String or by a boxed index, the 11 that read a boxed Symbol by a String are cured. Each of the other 1,737 prints what master prints.

Not here: an appended String that reaches the read boxed (`j = [k, 0][0]; s[j]` after `k << "n"`) still answers the name's first character, "s" where CRuby prints "ton". That read is `sp_poly_index_poly`'s.

No generated C changes: the function is in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
