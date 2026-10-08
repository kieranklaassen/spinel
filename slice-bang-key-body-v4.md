<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = +"abcd"; r = s.slice!("bc"); r << "x"        # CRuby "bcx"; here FrozenError
k = +"bc"; s = +"abcd"; r = s.slice!(k)
p r.equal?(k)                                    # CRuby false; here true
$n = 0; def mk; $n += 1; +"abcd"; end
r = mk.slice!("b"); p $n                         # CRuby 1; here 4
```

The value arm answered the key itself, a frozen literal or the very String in `k`; it now answers a copy of the key where it matched. The same arm rendered a receiver that is no variable at each of its uses, so `mk` ran four times; such a receiver is now read once into a rooted temp.

The copy is one allocation more where the value is taken: 495 instructions a `r = s.slice!("cd")` before, 657 after built with gcc, 476 and 638 built with clang (callgrind); a `r = mk.slice!("cd")` 570 before, 245 after (clang 559 and 232). A `s.slice!("cd")` whose value is not taken runs the instructions it did. Six existing tests that read `slice!`'s value change their generated C and print what they printed.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
