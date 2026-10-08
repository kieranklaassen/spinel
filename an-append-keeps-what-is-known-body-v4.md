<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A cost change, with a cost of its own: `buf << x; buf.size` in a loop was quadratic and is linear. It costs one instruction on every `setbyte`, two on a `size` answered from the length cache and one on an append to a String that has a cache entry (seven with clang); an append nobody measures gets ten cheaper (six with clang). No answer changes.

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
| master | 713,062,335 | 2,831,713,314 | 11,287,781,425 |
| with this | 10,610,520 | 20,559,889 | 40,474,807 |

Every append in place dropped what the String remembered of its character count (the hint in its header, its entry in the length cache), so the next `size`, `length`, negative index or slice counted every byte again. Thirteen such loops are linear with this: `size`, `length`, `s[0]`, `s[-1]` and `s[-2, 2]` on a local, and `size` and `s[-1]` on a global, an instance variable, a String under two names and with an interpolated String appended.

An append leaves the bytes ahead of it alone, so the cache entry now stays (`sp_str_lcache_grown`) and notes the new length. The append counts nothing; the next `sp_str_length` counts only the bytes added (`sp_str_length_grown`), or the whole String as before where it cannot tell (a prefix or a tail that is not valid UTF-8).

Why no answer changes. `setbyte` writes in place and leaves the cache entry, and for a String CRuby counts by bytes that stale count is the right answer:

```ruby
t = +"abc"; p t.size; t << "\xFF".b; p t.size; t.setbyte(0, 0xC3); p t.size   # 3 4 4, CRuby and master
```

An append after the `setbyte` dropped the entry, and the next `size` counted afresh. Three things keep every such answer:

- `setbyte` bumps a counter (`sp_str_byte_writes`); an entry records it when it is counted; a carried entry whose record is old is counted whole.
- What the cache holds decides these answers too, so a carried entry is a free way when a count is stored, as the dropped one was, and a carried count is stored as a fresh one is. Among its counted entries the cache holds what it held before.
- The header's hint goes at every append, as it did.

The threaded runtime (`SP_THREADS`) forgets as before: another worker may have written the bytes this one counted.

Cost, instructions a call (callgrind, master then this; gcc, and clang in brackets): `setbyte` 70 to 71 (70 to 71); `size` from the cache 79 to 81 (79 to 81); an append to a String nobody has measured 89 to 79 (85 to 79), through an instance variable 251.6 to 239.6 (255.7 to 243.7), of an interpolated String 197 to 181 (242 to 228); an append to a String with a cache entry 223.5 to 224.5 (215.5 to 222.5). With clang the cured loop takes 10,545,450, 20,469,817 and 40,337,556. Of 28 other built-in calls measured the same way (gcc), 12 cost what they did, 12 cost less (eight kinds of `inspect` and `Regexp#to_s` 44 to 97 less, three others 1 to 4) and 4 cost more: `a.join(",")` 841.4 to 848.4, `s.inspect` 480.9 to 485.8, a slice of a multibyte String 497.9 to 499.9, `casecmp` 118 to 119.

The generated C does not change: the change is in `lib/`. optcarrot's C is byte-identical; checksum 59662; 2,371,908,638 to 2,371,891,427 instructions (-0.001%).

Test: `test/string_append_keeps_length.rb` holds the answers after each kind of append, and after an append and a `setbyte` in either order. It passes on master; the counts are what shows the change, and without the counter six of its lines are wrong. Also run against master, line for line: 1,400 generated programs that mix appends, `setbyte`, questions about the length and other mutators on one String, with gcc and with `--share-strings` (350 of them with clang too), `SPINEL_GC_STRESS` unset, 1 and 2; and 60 programs that keep the length cache full, where the answers depend on what the cache holds. Every run prints master's bytes and ends with master's status. (What the cache holds depends on where a String lies, so both run with ASLR off and master's binary is padded to the same heap start.)

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
