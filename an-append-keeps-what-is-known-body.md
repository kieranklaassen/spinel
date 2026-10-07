## What this changes

```ruby
s = +""
n = ARGV[0].to_i
t = 0
n.times { s << "ab"; t += s.size }
p t
```

Instructions (callgrind):

| n | 25,000 | 50,000 | 100,000 |
|---|---|---|---|
| master 8684d54c | 713,056,417 | 2,831,707,396 | 11,287,775,303 |
| with this | 7,806,006 | 14,955,489 | 29,270,305 |

Every append in place dropped what the String remembered of its character count (the hint in its header, its entry in the length cache), so the next `size`, `length`, negative index or slice counted every byte again. The answers were right and the loop quadratic. Thirteen such loops are linear with this: `size`, `length`, `s[0]`, `s[-1]` and `s[-2, 2]` on a local, and `size` and `s[-1]` on a global, an instance variable, a String under two names and with an interpolated String appended.

An append leaves the bytes ahead of it alone, so it now keeps both (`sp_str_lcache_grown`): the hint while every appended byte is below 0x80, and the cache entry, which notes the new length. The append counts nothing; the next `sp_str_length` counts only the bytes added (`sp_str_length_grown`), or the whole String as before where it cannot tell (a prefix or a tail that is not valid UTF-8). An entry is kept only if the length it noted is the length the append started from.

Cost, instructions a call (callgrind, master -> this): an append to a String nobody has measured 89 -> 90, through an instance variable 251.6 -> 246.6, of an interpolated String 294.2 -> 296.2; an append to a String whose hint is set 223.5 -> 250.5 (the scan of the appended bytes), to one with a cache entry 223 -> 228; `size` answered from the cache 79 -> 83; `replace` on a String under two names 84 -> 85.

The generated C does not change: the change is in `lib/`. optcarrot's C is the same; checksum 59662; 2,377,778,203 -> 2,377,786,488 Ir (+0.0003%).

Test: `test/string_append_keeps_length.rb` holds the answers after each kind of append. It passes without this change once the setbyte fix is in; the counts are what shows it.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the setbyte fix, its first commit: without it a count setbyte left stale would outlive an append)
