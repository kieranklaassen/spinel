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

Cost: 11 instructions a store with gcc, what a String member's store pays, and 13 with clang, where a String's pays 12 (callgrind on master 8684d54c, 2,000,000 stores: 172,664,860 to 194,664,897 with gcc, 174,626,825 to 200,626,840 with clang). The barrier goes by the slot's name, as it does for a String, so an Integer `@r` in one class beside a String Range `@r` in another pays it too, 20 to 22 instructions a `new` over two programs and both compilers (300,000 of them with gcc: 22,727,134 to 29,327,140; master runs 29,392,935 when the other `@r` is a String). A program with no such store gets the C it had; optcarrot's C is unchanged.

Cured with it: a store whose value is used (`x = c.r = (a..z)`) and `h.instance_variable_set(:@r, (a..z))`. Both take the barrier ahead of the value, as they do for a String; with the two ends already made they were wrong at `SPINEL_GC_STRESS=1` and stopped at level 2 on master, and are right here.

Not changed: ends made in the store itself (`s.r = ("a#{i}".."z#{i}")`) are lost before the store is reached, which is "A String Range made on the spot keeps its ends, made in order, until it is read", and this depends on it. Where the barrier is ahead of the value and the value comes from a call that allocates (`x = c.r = mk(i)`, `h.instance_variable_set(:@r, mk(i))`), a collection inside the call drops the record: such a store is right here in a plain run, where master was wrong, and still loses its ends at `SPINEL_GC_STRESS=1` (19 of 200 turns for master's 197), as a String stored that way does on master with gcc. Under `SPINEL_GC_STRESS=2`, `inspect` of such a Range stopped on master before the read; it now reaches the fault "A String Range's inspect holds its Strings while it builds the text" cures and prints the wrong line the same Range prints from an Array element.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (equal under CRuby 4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: "A String Range made on the spot keeps its ends, made in order, until it is read" (ends made in the store itself are lost before the store)
