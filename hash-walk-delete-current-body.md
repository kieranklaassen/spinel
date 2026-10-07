<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Cost first: `each` and `each_pair` over String or boxed keys, and `each_key` and `each_value` over any keys, pay 5 to 7 instructions a turn more (table below). `each` over Integer or Symbol keys is the C it was.

```ruby
h = {"a" => 1, "b" => 2, "c" => 3}
h.each { |k, _v| h.delete(k) }
p h
```

```
spinel diff: output-diff
  program: unit.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-{}
+{"b" => 2}
```

Deleting the entry a walk is at slides the next one into its slot, and the walk stepped past it. `each` and `each_pair` already stay on the slot for Integer and Symbol keys. String keys, boxed keys, and `each_key` and `each_value` with any key did not.

They keep the key of the turn in a temporary now, and on a turn that left the Hash shorter they step only if the slot still holds that key. A turn that deleted nothing steps as before. Every turn that does not step has made the Hash shorter, so the walk ends.

Instructions a turn over a Hash of 101 entries whose block deletes nothing (callgrind, the difference of two run sizes), master b4d30a1d and this:

| keys | `each` | `each_key` | `each_value` |
|---|---|---|---|
| String | 115 → 120 | 52 → 59 | 111 → 118 |
| Integer | 41 → 41 | 12 → 11 | 31 → 38 |
| two kinds (boxed) | 34 → 40 | 14 → 14 | |

Not in this change:

- `map`, `select` and the other walks that build a result still step past the entry.
- A walk over a Hash held in a boxed variable (a local given two kinds of Hash) is emitted elsewhere and still steps past it.
- A turn that deletes two entries at or before the one the walk is at skipped two entries and skips one.
- A turn that deletes an entry and adds one goes on, where CRuby raises "can't add a new key into hash during iteration".

On master b4d30a1d: `make cident` reports 6,261 identical, 113 differ: the new test and 112 files that walk a Hash this way. The 112 give the same result on master and on this, plain and under `SPINEL_GC_STRESS=1` (all pass). Under `SPINEL_GC_STRESS=2` 14 of them (6 of ffi, 1 of fiddle, 5 of net, 2 of `test/`) fail on master and on this alike, and two more net tests abort on some runs and not on others, on either (`net_http_timeouts`: 15 of 25 runs on master, 14 of 25 on this). The new test prints 14 of its 23 lines wrong on master. `make infer-test` passes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
