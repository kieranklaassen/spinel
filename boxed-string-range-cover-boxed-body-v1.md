<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
r = [("ab".."ae"), 1][0]
ks = ["ac", 3]
p r.cover?("ac")
p r.cover?(ks[0])
```

prints `true` and `false` (`spinel diff`: output-diff). CRuby prints `true` twice.

The Range comes out of the Array boxed. For a String argument written in place, the chain of tests `emit_poly_prearms_n` writes for `cover?` has a String Range arm (pull request 7605), which answers by `sp_poly_case_eq`. For a boxed argument it has an Integer Range's arm and a Float Range's and none for a String Range, so the call fell to the false the chain starts from, whatever the argument held. The boxed argument gains the same test, after the numeric Ranges' own, and answers by `sp_poly_case_eq` too.

Cost: none for an Integer or a Float Range (callgrind, 300,000 boxed-argument calls on those two by turns: 41,461,140 instructions on master and 41,311,140 here with gcc, 41,572,739 on both with clang). A program with no `cover?` on a boxed receiver, or with an argument that is not boxed, gets the C it had; optcarrot's C is unchanged.

Limits. The boxed argument now answers what the String argument answers on the same receiver, also where that is not CRuby's, and there the boxed call's `false` was right:

- A String with a NUL byte compares up to it: `[("a".."c"), 1][0].cover?(["c\0x", 1][0])` is `true` here, as `[("a".."c"), 1][0].cover?("c\0x")` is on master. #<fork PR 106> compares the whole String, and this depends on it: with it beneath both are `false`.
- An end changed in place after the Range was made is not seen: after `mz.replace("ac")`, `[(ma..mz), 1][0].cover?(["ad", 1][0])` is `true` here, as the same call with `"ad"` written in place is on master. The cure belongs to the Range, which keeps its two ends as they were when it was made, not to this piece.

The call now reads the Range's two ends. A String Range held by an instance variable, a Struct member, a global, a constant or a class variable could lose them on master, where the `false` read nothing: so this depends on the two pieces that keep them, #<fork PR 146> and #<fork PR 148>.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; no Ruby 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: #<fork PR 146>, #<fork PR 148> and #<fork PR 106> (the first two keep the ends of a String Range in a slot; the third compares past a NUL byte)
