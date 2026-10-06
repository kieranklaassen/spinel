<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
spans = [("ab".."ae"), 1]
r = spans[0]
p r.include?("ac")
p r.member?("ae")
p r.include?("zz")
```

prints `false` three times (`spinel diff`: output-diff). CRuby prints `true`, `true`, `false`.

The Range comes out of the Array boxed, so the call goes through the switch `emit_poly_cases_n` writes over the receiver's class. That switch had a case for a String Array and for each String-keyed Hash and none for a String Range, which fell to the default arm's false. It gains `case SP_BUILTIN_STR_RANGE:` for a String argument, and for a boxed argument behind its tag. Both call `sp_srange_include`, which the typed call uses, so a Range with an end left out raises TypeError as it does typed and in CRuby.

Cost: one more case in the switch of an `include?` or `member?` whose receiver is boxed (callgrind on master 5c2dea5154f8, 300,000 such calls on a String Array, a Hash and an Integer Range: 60,767,275 on master, 60,766,531 here). The case is written for those two names only: `key?` and `has_key?` share the switch and get the C they had. optcarrot's C is unchanged.

The call now reads the Range's two ends. A String Range held by an instance variable, a Struct member, a global, a constant or a class variable could lose them on master, where the `false` read nothing: so this depends on the two pieces that keep them, #<fork PR 146> and #<fork PR 148>.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (equal under CRuby 4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: #<fork PR 146> and #<fork PR 148> (the ends of a String Range in a slot are kept by those two, and this reads them)
