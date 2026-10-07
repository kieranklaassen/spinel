<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
g = { "k" => "ab", "r" => (1..2), "x" => /a./ }
s = "cabab"
p s[g["k"]]
```

raises TypeError: no implicit conversion of String into Integer (`spinel diff`: exception-diff). CRuby prints `"ab"`. `s[g["r"]]` and `s.slice(g["x"])` raise it for the Range and the Regexp.

The String arms of `[]` and `slice` pick the read by the index's static type. A boxed index matched none of them and went to the last arm, the character read, whose Integer conversion raises for all three. A boxed receiver with the same index answered already, through `sp_poly_index_poly`. Now a boxed index has its own arm, which calls `sp_str_aref_poly`. An Integer is the character read as before. A String is searched for, and the answer is a copy of it, a new String as CRuby's is; one the program appends to is kept as a shared handle, whose buffer moves as it grows. A Range and a Regexp go to `sp_poly_index_poly`'s arms for a String receiver, so a Regexp sets the match variables as it does there. Anything else is converted by `sp_poly_arg_int_chk` as it was. A Symbol receiver reads its name through the same arm.

Cost: an Integer index pays nothing (callgrind on a39414338a22, gcc, 100,000 rounds: `s[g["n"]]` is 268 instructions a round before and after, an Integer read from an Array goes from 223 to 224), a Float index goes from 300 to 331. The generated C changes in 3 corpus programs, the ones with a String `[]` or `slice` whose one index is boxed (a splatted Array of one element, the argument of a bound `slice` Method, a boxed variable), in that call alone, and their tests pass; optcarrot's C is unchanged.

Not changed: the two-argument form with a boxed Regexp, `s[g["x"], 1]`, still raises TypeError, and so does a boxed Float Range, `(1.0..2.0)`, where CRuby slices. A Bignum index still answers the first character where CRuby raises RangeError.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
