<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

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

```
spinel diff: exception-diff
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): NoMethodError: undefined method 'dig' for an instance of String

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +0,0 @@
-TypeError
```

A Struct's dig reads the member its first key names itself and hands the other keys to `sp_poly_dig_n`, with that member's value in the receiver's place. That commit gave `sp_poly_dig_n` a test of its receiver, which is right for a receiver and wrong for a member: a member's value is a step of the walk, where CRuby ends at nil and raises TypeError naming the class of anything else that has no `dig`.

The walk's loop is now `sp_poly_dig_rest`. `sp_poly_dig_n` runs it after its receiver tests, and the Struct emitter enters it through `sp_poly_dig_member` for the keys past the first, for a literal member and for one chosen at run time.

The same hand-off met the older receiver tests too, so these were wrong before that commit as well and are right with this one: a nil member (`S.new(nil, 1).dig(:a, 0)` is nil in CRuby and raised NoMethodError here), and an Integer, a Float or a true member (TypeError in CRuby, NoMethodError here). It is one cause, so it is one commit.

Of 1,080 Struct dig programs (18 kinds of member, the first key a literal, a variable or an index, one to three keys, five ways to make and hold the Struct), 243 answer wrong on master and as CRuby does with this: 135 of them the regression (a String, a Symbol, a Range or an `Object.new` member) and 108 the older fault (nil, Integer, Float, true). None that was right changes its answer. `tools/cident.sh`: 6409 identical, 5 differ (the new test and four that pass before and after, where only the name of the call changes).

No dig costs more (callgrind, a million calls each, master then this change):

```
row = [[1, [2, 3]], "q"];            row[0].dig(1, 0)           310,668,277    310,668,277
row = [{a: {b: [1, 2]}}, "q"];       row[0].dig(:a, :b, 1)      590,669,641    590,669,642
row = [S.new({k: [1, 2]}, 5), "q"];  row[0].dig(:a, :k, 1)    1,847,183,275  1,847,183,275
v = S.new({k: [1, 2]}, 0);           v.dig(:a, :k, 1)           399,671,958    379,671,956
v = S.new(S.new([1, 2], 0), 0);      v.dig(:a, :a, 1)         1,628,840,297  1,625,840,356
```

The last two are the Struct's own hand-over: the member no longer goes through the receiver tests, and `sp_poly_dig_member` asks whether it is a Struct only when it is an object of one of the program's classes.

Not in this change:

- A member that is an object of one of the program's own classes (`S.new(Plain.new, 0).dig(:a, :k)`) keeps the NoMethodError it has on master. CRuby raises TypeError there, or calls the object's own `dig`. The walk answers nil for such an object wherever it meets one (`[Plain.new, 0].dig(0, :k)` prints nil on master), so `sp_poly_dig_member` raises for it first: a raise is not traded for that nil.
- A member holding the Integer or the Float that stands for nil in a typed slot (`S.new(-9223372036854775807 - 1, 0).dig(:a, 0)`) ends the walk with nil where it raised NoMethodError; CRuby raises TypeError. The member reads as nil before the dig sees it (the same `.dig(:a)` prints nil on master).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (nothing)
