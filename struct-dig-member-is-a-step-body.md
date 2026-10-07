Title: A Struct member dug into is a step of the dig, not its receiver

## What this changes

```ruby
S = Struct.new(:a, :b)
v = S.new("str", :sym)
begin
  p v.dig(:a, 0)
rescue TypeError
  puts "TypeError"
end
```

- before "A boxed value's dig raises NoMethodError for a receiver that cannot be dug": `TypeError`
- now: the program dies with `undefined method 'dig' for an instance of String (NoMethodError)`
- CRuby 4.0: `TypeError`

A Struct's dig reads the member its first key names itself and hands the other keys to `sp_poly_dig_n`, with that member's value in the receiver's place. That commit gave `sp_poly_dig_n` a test of its receiver, which is right for a receiver and wrong for a member: a member's value is a step of the walk, where CRuby ends at nil and raises TypeError naming the class of anything else that has no `dig`.

The walk's loop is now `sp_poly_dig_rest`. `sp_poly_dig_n` runs it after its receiver tests, and the Struct emitter calls it for the keys past the first, for a literal member and for one chosen at run time.

The same hand-off met the older receiver tests too, so these were wrong before that commit as well and are right with this one: a nil member (`S.new(nil, 1).dig(:a, 0)` is nil in CRuby and raised NoMethodError here), and an Integer, a Float or a true member (TypeError in CRuby, NoMethodError here). It is one cause, so it is one commit.

Of 1,080 Struct dig programs (18 kinds of member, the first key a literal, a variable or an index, one to three keys, five ways to make and hold the Struct), 243 answer wrong on master and as CRuby does with this: 135 of them the regression (a String, a Symbol, a Range or an object member) and 108 the older fault (nil, Integer, Float, true). None that was right changes its answer. `tools/cident.sh`: 6357 identical, 5 differ (the new test and four that pass before and after, where only the name of the call changes).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (nothing)
