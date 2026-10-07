<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A boxed Symbol read by a boxed index that is no Integer answered the first character of its name:

```ruby
g = { "s" => :stone, "f" => 1.5 }
p g["s"][g["f"]]   # "s"; CRuby: "t"
```

`Symbol#[]` is `String#[]` on the Symbol's name. `sp_poly_index_poly` reads a Symbol receiver by an Integer, an Integer Range and a Regexp; an index of any other kind that no earlier arm takes fell to its last line, which reads offset 0. The arm a boxed String has for such an index (`sp_poly_str_aref_other`) now takes a Symbol's name too: a Float is cut, a Float Range slices, an appended String is searched for, and `nil`, `true` or an Array is CRuby's TypeError.

Of 957 programs that read a boxed value of every kind through an index of every kind, 521 are right before and after, 212 are cured, and none that was right is lost. With a NaN index a boxed Symbol now answers nil where it answered "s"; a boxed String answers that nil too, and CRuby raises RangeError.

No generated C changes: the function is in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: the pull request "A boxed String's [] reads an appended String, a Float or nil index"
