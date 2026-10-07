## What this changes

```ruby
title = ["title".freeze, 3][0]
begin
  title[9] = "!"
rescue IndexError
  puts "no such place"      # CRuby prints this; on master the program dies of FrozenError
end
s = [+"title", 3][0]
begin
  s[9..10] = "!"
rescue RangeError => e
  puts e.message            # "9..10 out of range"; on master it dies of IndexError
end
s[-9..1] = "!"              # RangeError in CRuby; master writes at the front in silence
```

`spinel diff` on master: exception-diff, `FrozenError: can't modify frozen String: "title"` where CRuby exits 0.

An index assignment on a String read out of a mixed container raised an error of another class than CRuby's, so a `rescue` written for CRuby did not take it: a frozen String raised FrozenError whatever the index, and a Range that starts outside the String raised IndexError, or was stored at the front when it started below it.

Now a frozen String raises IndexError for an index or a start outside it and for a negative length, and FrozenError only for a store that would be made; a Range that starts outside the String raises RangeError. The checks are in the runtime's three stores for a boxed receiver, ahead of the frozen test (`lib/spinel_rt.h` +22 -0); no compiler source changes, so every program emits the C it did. `s[a..b] = v` costs 8 instructions a store more by callgrind, the other two forms the same count.

Not here: a value that is no String is CRuby's TypeError, which Spinel does not raise yet; for such a value the frozen store keeps the FrozenError it had.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (no generated C changes)
- [ ] Depends on: # (nothing)
