## What this changes

```ruby
u = +"u"
u.replace("r").concat("c")
p u
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
-"rc"
+"r"
```

The second link's receiver is the first link's value, a temporary, so its change went there and `u` kept the first one alone. `s.prepend("b").prepend("a")` left "bc" and `s.clear.concat("z")` left "". The `replace` chain raised FrozenError until pull request 7684 made that value a new String; since then it is silent.

`s = +""; s.reverse!.concat("x").clear; p s` is "" in CRuby and was "" here until pull request 7642 wrote a bang chain's value back; master prints "x", because the last link still changes a temporary.

A statement whose value nothing reads now runs each link on the local: `s.m(x).n(y)` becomes `(s.m(x); s.n(y))`, for the links that always answer their receiver (`<<`, `concat`, `prepend`, `replace`, `clear`, `reverse!`, `freeze`, `force_encoding`, `insert` at a literal 0 or -1). A chain whose value is assigned, passed, compared or returned stays whole, and so does one on anything but a String local.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
