<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
spans = [("ab".."ae"), 1]
r = spans[0]
p r.include?("ac")
p r.member?("ae")
p r.include?("zz")
```

printed `false` three times. CRuby prints `true`, `true`, `false`.

The Range comes out of the Array boxed, so the call goes through the switch `emit_poly_cases_n` writes over the receiver's class. For a String argument that switch had a case for a String Array and for each String-keyed Hash and none for a String Range, which fell to the default arm: `sp_poly_user_include` says "not a user Enumerable" and the call answers false.

The switch gains `case SP_BUILTIN_STR_RANGE:` for a String argument, and for a boxed argument behind its tag (a boxed value that is not a String is not a member). Both call `sp_srange_include`, which the typed call uses, so a Range with an end left out raises TypeError here as it does typed and in CRuby; it answered false.

The case is written for `include?` and `member?` only. `key?` and `has_key?` share this switch (`is_key_query`) and a Range has neither: a boxed String Range given `key?` gets the C it had. An Integer or a Float Range takes its own cases as before. A program with no such call gets the C it had.

The call now reads the Range's two ends, as the typed call does. A String Range held by an instance variable, a Struct member, a global, a constant or a class variable could lose them on master, and there master's `false` read nothing: so this sits on the two pieces that keep them, #<fork PR 146> and #<fork PR 148>.

Not changed, and as on master:

- `begin`, `end` and `cover?` on a boxed String Range. Each is its own commit.
- `key?` and `has_key?` on a boxed Range answer (false for a String Range) where CRuby raises NoMethodError.
- A beginless or endless String Range given a value that is not a String answers false, typed and boxed, where CRuby raises TypeError.

Measured on master 5c2dea5154f8, against CRuby 3.3.6, with gcc 13.3 and clang 18.1, in a plain run, under `SPINEL_GC_STRESS=1` and `2`, and with `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1` without and with level 1:

- 1,042 generated programs: a String Range (inclusive and exclusive) read from an Array element, a Hash value, a captured local, a method's boxed return, an instance variable and a local, given 22 arguments (a member, a non-member, each end, a longer and a shorter String, the empty String, a String built at run time, a mutable one, an Integer, nil, a Symbol, a Float, and the same boxed); the same calls on an Integer and a Float Range; the answer as a condition, negated and twice in one expression; a program whose own class defines `include?`; the slot's other values (a String, an Array, a Hash, an Integer, nil); beginless, endless, one-letter, carrying, empty and one-member Ranges. Right at all five settings: 623 on master, 870 here, the same with both compilers. Of 5,210 runs a compiler: 3,115 right on both, 1,235 not right on master and right here, 860 the same and not right. Right on master and not right here: 0. A build failure, abort or raise on master that prints a wrong line here: 0.
- The 172 programs still not right print master's lines: 168 are `key?` or `has_key?` on a Range (their C is byte for byte master's), 4 are a beginless or endless Range given a boxed Integer.
- `make cident REF=5c2dea5154f8`: 5979 identical, 100 differ, 0 refusal changes. The 100 are the new test and 99 programs with an `include?` or `member?` on a boxed receiver: 112 switches gain the case, the rest of their C is byte for byte master's, and each prints what its `.expected` says.
- Cost: none for another receiver. 300,000 calls on a String Array, a Hash and an Integer Range from one boxed slot: 60,767,275 instructions on master, 60,766,531 here (callgrind). optcarrot's C is unchanged.
- `tools/refusals.sh` passes (426 records). `make scale-test` gives master's four numbers (1.71x, 4.73x, 6.06x, 4.22x). `ruby tools/gate.rb check` passes.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (equal under CRuby 4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: #<fork PR 146> and #<fork PR 148> (the ends of a String Range in a slot are kept by those two, and this reads them)
