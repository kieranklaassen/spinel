<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
S = Struct.new(:r)
def fill(c, i)
  a = "a#{i}"
  z = "z#{i}"
  c.r = (a..z)
end
c = S.new(("a".."z"))
warm = (1..5000).map { |k| "warm-#{k}" }
i = 0
while i < 200
  fill(c, i)
  junk = (1..3000).map { |k| "j#{k}" }
  r = c.r
  puts "#{i}: #{r.first}..#{r.last}" unless r.first == "a#{i}" && r.last == "z#{i}" && junk.size == 3000
  i += 1
end
puts "done"
```

prints `59: j319..j320` and `110: j240..j241` before `done` in a plain run (`spinel diff`: output-diff). CRuby prints `done` alone.

A String Range sits in a Struct member or an instance variable by value and carries two GC strings. `class_needs_scan` counts such a slot, but `wb_field_is_ref_in` asked `needs_root` alone, so the store took no write barrier, a minor mark did not walk the old object, and the sweep freed both ends while the slot still named them. The two now ask one predicate, `ivar_holds_ref`, and the store is followed by `sp_gc_wb` as a String's is.

Cost: 11 instructions a store, what a String member's store pays (callgrind on master c6bbdfbc9, 2,000,000 stores: 172,668,600 to 194,668,623). The barrier goes by the slot's name, as it does for a String, so an Integer `@r` in one class beside a String Range `@r` in another pays it too, 22 instructions a `new`. A program with no such store gets the C it had; optcarrot's C is unchanged.

Not changed: ends made in the store itself (`s.r = ("a#{i}".."z#{i}")`) are lost before the store is reached, which is #<fork PR 94>, and this depends on it. A store whose value is used and comes from a call (`x = h.r = mk(i)`) and `instance_variable_set` still take no barrier. Under `SPINEL_GC_STRESS=2`, `inspect` of such a Range stopped on master before the read; it now reaches the fault #<fork PR 51> cures and prints the wrong line the same Range prints from an Array element.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (equal under CRuby 4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: #<fork PR 94> (ends made in the store itself are lost before the store)
