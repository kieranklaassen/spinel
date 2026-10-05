<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
s = +"abcd"; r = s.slice!("bc"); r << "x"        # CRuby "bcx"; here FrozenError
k = +"bc"; s = +"abcd"; r = s.slice!(k)
p r.equal?(k)                                    # CRuby false; here true
def mk; $n += 1; +"abcd"; end
r = mk.slice!("b"); p $n                         # CRuby 1; here 4
```

The value arm answered the key itself: a frozen literal, or with a key that can change, that very String, so `r.setbyte(0, 90)` changed the key too. It now answers a copy of the key where it matched. That is one allocation more where the value is taken: 398 instructions a `r = s.slice!("cd")` on an eight-character String before, 673 after (callgrind, 200,000 calls).

The same arm rendered a receiver that is no variable at each of its uses, so `mk.slice!("b")` ran `mk` four times, hit or miss, with its value taken or not. Such a receiver is now read once into a rooted temp, and nothing is stored back, as before: 469 instructions a `r = mk.slice!("cd")` before, 257 after.

The generated C changes in the new test and in six existing tests that call `slice!` with a String key; each of the six prints what it printed. No benchmark and not optcarrot.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
