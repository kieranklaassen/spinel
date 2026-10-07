<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

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

Cost: one more case in the switch of an `include?` or `member?` whose receiver is boxed (callgrind on master a2bd8900, 300,000 such calls on a String Array, a Hash and an Integer Range: 34,068,436 on master and 34,069,318 here with gcc, 32,325,719 and 32,326,844 with clang). The case is written for those two names only: `key?` and `has_key?` share the switch and get the C they had. optcarrot's C is unchanged.

The call now reads the Range's two ends. A String Range held by an instance variable, a Struct member, a global, a constant or a class variable could lose them on master, where the `false` read nothing: so this depends on the two pieces that keep them, "A String Range stored into an instance variable or a Struct member keeps its ends" and "A String Range in a global, a constant or a class variable keeps its ends".

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (equal under CRuby 4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: "A String Range stored into an instance variable or a Struct member keeps its ends" and "A String Range in a global, a constant or a class variable keeps its ends" (the ends of a String Range in a slot are kept by those two, and this reads them)
