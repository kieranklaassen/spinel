<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
title = ["title".freeze, 3][0]
begin
  title[9] = "!"
rescue IndexError
  puts "no such place"      # CRuby prints this; on master the program dies of FrozenError
end
begin
  title["x"] = "!"
rescue IndexError
  puts "no such text"       # the same
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

An index assignment on a String read out of a mixed container raised an error of another class than CRuby's, so a `rescue` written for CRuby did not take it: a frozen String raised FrozenError whatever the index or the key, and a Range that starts outside the String raised IndexError, or was stored at the front when it started below it.

CRuby looks at the index before it asks whether the String may change. Its order, in each line the two tests pin:

- `fz[9] = "X"`, `fz[-9] = "X"`, `fz[9, 1] = "X"`, `fz[-9, 1] = "X"`: IndexError, index out of string, ahead of FrozenError.
- `fz[1, -1] = "X"`: IndexError, negative length, ahead of both.
- `fz["q"] = "X"`, `fz[/q/] = "X"`, and the same keys read out of an Array: IndexError, string or regexp not matched, ahead of FrozenError.
- `fz[9..10] = "X"`, `fz[-9..1] = "X"`: RangeError, naming the Range, ahead of FrozenError.
- a store that would be made (`fz[2] = "X"`, `fz[6] = "X"`, `fz["b"] = "X"`, `fz[1..2] = "X"`): FrozenError.
- a String that is not frozen: `s[9..10] = "X"` and `s[-9..1] = "X"` are RangeError; `s[6..7] = "X"`, at the end, is stored.

The checks are in the runtime's stores for a boxed receiver (`lib/spinel_rt.h` +30 -1): a cold helper raises the index's error ahead of the frozen test in the three index stores, and the keyed store, which splices a plain String to a fresh buffer, runs as it does for a String that is not frozen and raises FrozenError where it would have answered. No compiler source changes, so every program emits the C it did.

Cost by callgrind, a million stores into a boxed String: an Integer index 1,165,551,350 to 1,165,551,392 and a start with a length 1,210,655,121 to 1,210,655,100, the same; a String key 1,420,861,467 to 1,425,862,601, 5 instructions a store; a Range 1,261,837,397 to 1,269,838,457, 8 a store; beside a class that owns `[]=`, an Integer index 1 a store and a String key 5. An Integer store into a boxed Array is the same (67,673,974 to 67,673,980).

Not here, the same on master: a value that is no String is CRuby's TypeError, which Spinel does not raise yet; for such a value the frozen store keeps the FrozenError it had. A key that is no index (a Symbol, nil) is taken in silence, frozen or not.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (no generated C changes)
- [ ] Depends on: # (nothing)
