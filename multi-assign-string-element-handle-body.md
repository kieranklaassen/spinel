Title: A new String a multiple assignment stores where it is appended to is held as its handle

## What this changes

```ruby
r = [+"q"]
r[0], r[1] = +"ab", +"cd"
r[0] << "z"
p r
```

prints `["abz", "cd"]` in CRuby and does not build on master, with and without `--share-strings`: `initialization of 'sp_String *' from incompatible pointer type 'const char *'`. Two single stores (`r[0] = +"ab"; r[1] = +"cd"`) build and are right.

A String stored where an element is changed in place is wrapped in a handle of its own (`repr_of`'s `RS_FRESH`); a single store does that at the store, and an operand run ahead of its call is rendered that way too (`operand_fresh_str`). A multiple assignment holds each value in a temp first: the temp was declared the handle and filled with the String. It is now the handle the store would have made, and the wrap counts as an allocation for rooting the temps before it.

3,283 programs (12 kinds of target, 13 kinds of value, 9 changes, 3 contexts):

| | without the flag | with `--share-strings` |
|---|---|---|
| same C as master (320 and 233 of them refused on both) | 2,365 | 2,113 |
| C error, now right | 798 | 1,013 |
| C error, now FrozenError as CRuby (a literal) | 120 | 153 |
| C error, now a wrong answer | 0 | 4 |

The 4: with the flag, in a method, `r = []; r[0], r[1] = "ab".dup, "cd".dup; r.each { |e| e << "z" if e.is_a?(String) }; p r` prints `["abz", "cd"]`. Master prints the same for two single stores there; it is the Array born empty that the index-store pull request cures, and with that one beside this all 4 are right.

No collector-stress difference at 0, 1 and 2. `tools/cident.sh`: 6341 identical, 1 differs (the new test).

Not here, as on master: without the flag an instance variable's Array born empty and a Struct's members as the targets lose the append without a word.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing; see the 4 above for the index-store pull request)
