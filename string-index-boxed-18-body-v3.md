<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
h = { "k" => +"a", "n" => 1 }
h["k"] << "b"
g = { "c" => "cabab", "f" => 1.5 }
p g["c"][h["k"]], g["c"][g["f"]]
```

prints `"c"` and `"c"` (`spinel diff`: output-diff). CRuby prints `"ab"` and `"a"`. With `true` as the index it prints `"c"` where CRuby raises TypeError.

`sp_poly_index_poly`, which reads a boxed receiver by a boxed index, has an arm for a String receiver with an Integer, a String, an Integer Range, a Regexp and a nil index. An index of any other kind fell to its last line, which reads element 0: a String the program appends to (kept as a shared handle, whose tag is not `SP_TAG_STR`), a Float, a Float Range, true, an Array. Now such an index goes the way the typed read goes. An appended String is searched for, and the answer is a copy of its text, since the handle's buffer moves as it grows. A Float Range slices by its ends cut to Integers, and a String Range raises CRuby's TypeError. Anything else is converted by `sp_poly_arg_int_chk`: a Float is cut, an object answers its `to_int`, and what has no conversion raises CRuby's TypeError.

Cost: one test of the index's tag on the last line, which an Integer index into an Array never reaches. callgrind on 42557a3c0e7c, 100,000 rounds, instructions a round before and after: with gcc `g["a"][g["n"]]` on an Array 239 and 238, `g["c"][g["n"]]` on a String 436 and 435, a String key into a Hash 318 and 318; with clang 211 and 209, 460 and 461, 328 and 326. The helper takes the index by address, since passed by value clang's caller sets the copy up on every read, the Integer one too. The change is in lib/spinel_rt.h, so no generated C changes.

Not changed: an Integer index, a Bignum index (the first character, where CRuby raises RangeError) and a Symbol index (nil, where CRuby raises TypeError) answer as they did, and so does a receiver that is no String: a boxed Symbol read by such an index still answers its first character. An infinite Float or one too large for an Integer, as an index or as a Float Range's end, raises RangeError with the conversion's own message, not CRuby's. A NaN index answers nil, as the typed read `s[0.0 / 0.0]` does, where CRuby raises RangeError. A String with no boxed receiver, `s[g["k"]]`, raises TypeError for a boxed String, Range or Regexp index; that is an arm of the emitter, not this function.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
