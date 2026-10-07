<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
rows = []
20_000.times do |i|
  line = "id" + i.to_s + "\tname" + i.to_s + "\t" + (i * 3).to_s
  rows << line.split(/\t/)
end
bad = 0
rows.each_with_index { |r, i| bad += 1 unless r[0] == "id" + i.to_s }
p bad
```

prints 2 in a plain run (`spinel diff`: output-diff). CRuby prints 0. Two of the 20,000 kept rows hold another row's fields and nothing says so. It needs a collection to start while one split is still filling its Array, so a short script is right; and a split big enough to lose the Array outright crashes instead (8 rounds of `s.split(/ /)` on an 800 KB String exit 139). `rpartition` with a Regexp answers freed pieces too: on a 6 KB String, 20,000 rounds of `t.rpartition(/b/)` answer a wrong head or match 113 times. With a String separator all three are right.

`sp_re_split_limit` kept the Array it fills in a C local with no root, so the collection that a later piece's allocation starts freed the Array. `sp_re_rpartition` rooted its Array but made the head, the match and the tail before it pushed any of them, so the head and the match had no holder while the next piece was allocated. Now split roots its Array where it is made, as `sp_re_scan` does, and rpartition pushes each piece as it is made, as `sp_str_partition` does. The test is in `GC_STRESS_TESTS`.

Cost: the root costs split 20 to 24 instructions a call (callgrind on 8578e3fb543a, 200,000 calls: `"ab cd ef".split(/ /)` goes from 1,283 to 1,303 a call, a subject with no match from 545 to 569); rpartition's count does not rise (1,133 to 1,132). The change is in lib/sp_re.c, so no generated C changes.

Not changed: under `SPINEL_GC_STRESS=2` a program that aborted in its split now runs on to what follows it. `for x in s.split(/\s/) do t << x + "!" end` over 20 words walks an Array held in no root and counts 10 there, as the same loop over `s.split(" ")` does on master. test/string_nul_regexp.rb, which aborted at its split after 8 lines, prints 30 right lines of 32 and stops at `named_captures` with a fault on the GC mark path. A split into very many pieces is slow under a stress level, as `chars` is: its Array is now marked at each collection. `"a\0b".split(/a/)` still drops a last piece that begins with a NUL byte.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
