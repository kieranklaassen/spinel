<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
h = { "k" => +"AB", "n" => 1 }
h["k"] << "c"
p "abc".casecmp(h["k"]), "abc".casecmp?(h["k"])
```

prints `nil` and `nil` (`spinel diff`: output-diff). CRuby prints `0` and `true`.

A boxed String the program appends to is kept as a shared handle, and its tag is not `SP_TAG_STR`. The arm for a String receiver with a boxed operand asked `sp_poly_check_str`, which answers NULL for a handle, so the operand was taken for no String and the call answered nil, as it does for an Integer. Now the two templates read a handle's text, through `sp_str_casecmp_strbuf`, where `sp_poly_check_str` answered NULL. It still answers nil where the two encodings differ and each side has a byte past ASCII. The operand is only compared, so nothing keeps the handle's buffer. A boxed receiver read a handle operand already (`sp_poly_casecmp`).

Cost: a plain String operand takes the path it took (callgrind on fc6e90cc8d29, gcc, 100,000 calls: `"ab".casecmp(h["k"])` goes from 100 to 99 instructions a call, `casecmp?` from 200 to 199); an Integer operand is 23 before and after. The generated C changes in 2 corpus programs, in that expression alone, and their tests pass; optcarrot's C is unchanged.

Not changed: an append through a reader is lost before the call when the instance variable is boxed (`b1.v << "b"` and then `[b1, b2][0].v` reads `"a"`), so such an operand is still compared as `"a"`. A plain String operand in another encoding is still compared by its bytes: `"é".casecmp("\xE9".b)` answers -1 and `casecmp?` true where CRuby answers nil. A receiver the program appended binary bytes to is still read as UTF-8, so against an appended binary operand it answers nil where CRuby compares: `h = { "k" => "A".b, "n" => 1 }; h["k"] << "\xFFB".b; m = +""; m << "a\xFFb".b; p m.casecmp(h["k"]), m.casecmp?(h["k"])` prints `nil` and `nil` for `0` and `true`, as on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
