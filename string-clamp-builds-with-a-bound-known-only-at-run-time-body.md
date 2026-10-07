<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
g = { "lo" => "b", "hi" => "d", "n" => 1 }
p "a".clamp(g["lo"], g["hi"])
```

does not build (`spinel diff`: link-error, incompatible types when initializing type `const char *` using type `sp_RbVal`). CRuby prints `"b"`.

One answer is not CRuby's, and it is the cost of this change: when the bound that wins is a String the program appends to, the answer is a copy of its text, so a later append to the answer does not reach that bound, nor the reverse (`x = "e".clamp(g["lo"], h["k"]); x << "!"; p h["k"]` prints the bound without the `!`). The receiver or a plain String bound is answered itself, as the typed arm answers.

The String arm of `clamp` emits each bound as a C string, and a boxed bound is a boxed value. Now a boxed bound goes to `sp_str_clamp_poly`: the boxed clamp decides, so nil is an open side and a bound that is no String raises CRuby's comparison error, and the answer is read back as the String it is. A bound the program appends to is kept as a shared handle whose buffer moves as it grows, which is why its text is copied.

Cost: two typed bounds emit what they did. No corpus program's C changes (`make cident` against fc6e90cc8d29: 6,402 of 6,403 programs identical, the other being the new test, which does not build there), and optcarrot's C is unchanged.

Not changed: `s.clamp(g["lo"]..g["hi"])`, a Range of boxed ends, still does not build. A bound that is an object with its own `<=>` and no `to_str` raises ArgumentError where CRuby asks the object, as a boxed receiver does on master. `:c.clamp(g["lo"], g["hi"])` still raises NoMethodError.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
