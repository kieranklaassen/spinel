<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = "ab" * 2100
bad = 0
300.times do |i|
  t = s + i.to_s
  bad += 1 unless t.each_byte.inspect == "#<Enumerator: " + t.inspect + ":each_byte>"
end
p bad
```

prints 15 in a plain run (`spinel diff`: output-diff). CRuby prints 0. Fifteen of the texts hold other bytes where the String's inspect belongs.

`sp_sprintf` formats into a 4,096-byte buffer on the stack. For a longer text it allocated the result and then formatted a second time from its arguments. A caller often hands it a fresh String that nothing else holds, here the receiver's inspect, and that allocation could collect it. Now the long text is rendered into a malloc buffer first, in a helper of its own, and copied into the result. Every long text built this way had the fault: the inspect of an Enumerator over a String, an Array or a Hash, and at `SPINEL_GC_STRESS=1` the default inspect of an object with a long instance variable. The test is in `GC_STRESS_TESTS`.

Cost: a short text takes 3 instructions more a call (callgrind on 70cddab37194, gcc, 100,000 calls: `"ab".each_byte.inspect` goes from 2,160 to 2,163). The count grows with the text, to about 100 more at 4 KB, there on 470,559 a call. A text of 4,096 bytes or more is copied once more, and that copy lives while the result is made. The change is in lib/sp_cold.c, so no generated C changes.

Not changed: a caller that makes two fresh Strings before it calls `sp_sprintf` still has to hold the first while the second is made. Two callers do not, the inspect of a String Range and the default inspect of an object with two instance variables, and with gcc both are wrong in a plain run before and after: `Two.new(i, "a" * 4500 + i.to_s).inspect` in 14 of 1,000 rounds on master and in 10 here, `(t..u).inspect` with a 5 KB begin in 12 of 300 and in 13. Which rounds go wrong moves with the allocations. The inspect of a Symbol made from a String nothing else holds is wrong at `SPINEL_GC_STRESS=1` when it is long and quoted, and at 2 whatever its length, before and after.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
