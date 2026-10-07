<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
h = { "k" => +"a", "n" => 1 }
h["k"] << "b"
q = { "a" => { "ab" => 1, "c" => 2 }, "n" => 1 }
p q["a"][h["k"]], q["a"].key?(h["k"]), q["a"].fetch(h["k"], 0)
```

prints `nil`, `false` and `0` (`spinel diff`: output-diff). CRuby prints `1`, `true` and `1`.

A boxed String the program appends to is kept as a shared handle, and its tag is not `SP_TAG_STR`. The dispatchers that read a Hash reached through a boxed value (`sp_poly_index_poly`, `sp_poly_has_key`, `sp_poly_delete_key`) tested that tag alone for a String-keyed storage, so the key was taken for a key of another kind: a miss. `[]`, `dig`, `fetch`, `key?` and its three aliases, `values_at`, `slice` and `delete` all missed, and `fetch` with no default raised KeyError. Now the three read a handle key by its text before they dispatch. The text is only hashed and compared; `slice` hands the key on to `sp_PolyPolyHash_set`, which keeps its own copy of a handle's text. A Hash with keys of mixed kinds takes the box as it did, and so does a receiver that is no Hash.

Cost: one test of the key's tag in each of the three (callgrind on 70cddab37194, gcc, 100,000 calls: `t[g["k"]]` with a plain String key goes from 190 to 193 instructions a call, `t.key?(g["k"])` from 111 to 112, `t.fetch(g["k"], nil)` from 324 to 332; an Integer key into an Integer-keyed Hash 129 to 130). The change is in lib/spinel_rt.h, so no generated C changes.

Not changed: a Hash the compiler types (not reached through a boxed value) found such a key already. A boxed String indexed by an appended String, `t["s"][h["k"]]`, still answers its first character where CRuby answers the substring.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
