<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
g = { "lo" => "b", "hi" => "d", "n" => 1 }
p "c".between?(g["lo"], g["hi"])
```

does not build (`spinel diff`: link-error, incompatible type for argument 2 of `sp_str_cmp_bytes`). CRuby prints `true`.

The String arm of `between?` emits each bound as a C string, and a boxed bound is a boxed value. Now a String receiver with a boxed bound takes the arm a boxed receiver takes: the receiver is boxed and `sp_poly_cmp_ck` compares it with each bound as it is, so a bound the program appends to is read, and an Integer or a nil bound raises CRuby's comparison error. A Symbol read as its name keeps its arm, since its bounds compare as Symbols.

Cost: two typed bounds emit what they did. No corpus program's C changes (`make cident` against 759d120fd207: 6,424 of 6,429 programs identical; four of the five that differ print the compiler's revision, the other being the new test, which does not build there), and optcarrot's C is unchanged.

Not in this change, each as a boxed receiver answers on master: a Bignum bound answers with no raise (`g = { "lo" => "b", "big" => 2 ** 70 }; s = "c"; p s.between?(g["lo"], g["big"])` prints `true`, as `r["s"].between?(g["lo"], g["big"])` does for a boxed `"c"`; CRuby raises ArgumentError), and a bound that is an object with its own `<=>`, with or without `to_str`, raises ArgumentError (comparison of String with ... failed) where CRuby asks the object. A Symbol read as its name with a boxed bound (`sym.to_s.between?(g["lo"], g["hi"])`) still does not build.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
