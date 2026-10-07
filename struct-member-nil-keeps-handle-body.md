Title: A Struct member a construction leaves nil keeps the String handle its writer gives it

## What this changes

```ruby
S = Struct.new(:buf)
s = S.new
s.buf = +""
3.times { |i| s.buf << i.to_s }
p s.buf
```

prints `"012"` in CRuby and `""` here. A class with `attr_accessor` in the Struct's place prints `"012"`, and so does this with `--share-strings`.

The writer's String makes the member the shared handle, and the `new` that omits the member types it nil. `ty_unify` keeps a String that also sees nil a String, whose NULL is nil, but has no such rule for the handle: the member went to poly, the next round made it the handle again, and the two alternated until the round limit. It ended poly, and the append answered a new String that nothing kept.

A handle member that a `new` leaves nil now stays the handle. A call on it while it is nil is still CRuby's NoMethodError, as the poly member raised: that nil is the program's own, so the member is marked, the nil fact answers `NFW_UNSET` for its reader, and the call plan's nil target tests it as it tests any nil the program writes. `cplan_nil` takes one arm, for a handle a reader renders with that fact. A member no `new` leaves nil is not marked and keeps its C, and so does every other handle slot. Without `--share-strings` only: with it these programs are right already.

A multiple assignment into such members (`r.x, r.y = +"ab", +"cd"` after `S.new`) lost the append the same way. It now gets the refusal a class's attributes get on master ("a multiple assignment's target given a String, which no conversion keeps in its sp_String * slot").

Of 541 programs (a Struct made four ways and a class; the member set, left nil on a second instance, or set and put back to nil; 36 uses of it), 144 go from wrong to right, 288 are right before and after, and 109 (the class's) are the same C. None that was right changes its answer. With `--share-strings` all 541 are the same C. `tools/cident.sh`: 6369 identical, 1 differ (this test); with `--share-strings` 6265 identical, none differ.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (nothing)
