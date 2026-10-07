Title: A String stored by index into an empty Array is changed in place by a block over it

## What this changes

```ruby
r = []
r[1] = "ab".dup
r.each { |e| e << "z" if e.is_a?(String) }
p r
```

prints `[nil, "abz"]` in CRuby and `[nil, "ab"]` on master, with `--share-strings` too. Without the flag the plain form is wrong as well:

```ruby
r = []
r[0] = +"ab"
r.each { |e| e << "z" }
p r   # ["abz"] in CRuby, ["ab"] on master
```

The same index store into a seeded Array (`r = [+"q"]; r[0] = +"ab"`) and a push (`r << +"ab"`) take the handle on master and are right.

`promote_shared_stored_strings` asks the stores of an Array whose elements a block changes in place for the handle, and it asks a local whose kind is an Array. A local written only `[]` and filled by index has none while the fixpoint runs (the index store guesses a Hash; `an_phase_post_fixpoint` makes it the general Array afterwards), so the pass skipped it. It now asks that local's stores too, through the same `strbuf_demand_container_stores_here`, and only where every stored String takes the handle without a refusal and the block changes its own parameter (`sb_stores_take_handle`). A String variable stored this way (`c = +"cd"; u[0] = c`) is its element, as in `u = [+"q"]; u[0] = c` on master.

1,833 programs (17 kinds of value, 8 store forms, 12 iterators, 12 changes, 4 contexts), C compared with master's:

| stored value | programs | same C | wrong, now right | right on both, C differs | FrozenError on both, as CRuby |
|---|---|---|---|---|---|
| a new String (`+"ab"`, `dup`, interpolation, `String.new`, a call) | 963 | 324 | 472 | 167 | 0 |
| a String variable | 293 | 126 | 136 | 31 | 0 |
| a literal | 77 | 20 | 0 | 0 | 57 |
| another Array's element (`a[0]`) | 86 | 86 | 0 | 0 | 0 |
| a reader's, a constant's, a conditional's, a Hash value's, a block parameter's | 414 | 414 | 0 | 0 | 0 |

No program that was right changes its answer, at `SPINEL_GC_STRESS` 0, 1 and 2. With `--share-strings`: 1,802 have master's C, 18 go from wrong (17) or a C error (1) to right, 13 answer the same.

Cost: an Array that is only read keeps master's C. 300,000 index stores then an appending `each`: 979M instructions, where master's push form takes 960M (callgrind). `tools/cident.sh`: 6341 identical, 1 differs (the new test).

Not here, as on master: another Array's element or a reader's String as the value, `reverse_each`, a `for` or `while` loop, `insert`, an instance variable's or a constant's Array.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
