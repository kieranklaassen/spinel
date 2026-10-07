<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A boxed Integer, Symbol, nil or true answered another `object_id` than the same value unboxed. The cost of the cure: a boxed `object_id` call is 7 instructions more (22 against 15 a loop turn, callgrind on master a3941433), for a String too, since the tag has to be read.

```ruby
row = [5, "q"]
x = row[0]
ids = {}
ids[x.object_id] = x
p ids[5.object_id]
```

```
spinel diff: output-diff
  program: registry.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-5
+nil
```

`object_id` on a boxed receiver answered the box's payload word: an Integer's value where an Integer answers 2n+1, a Symbol's id where a Symbol answers twice it, 0 for nil and 1 for true where they answer 4 and 20. So one value had two ids by how it was held, and `x.object_id == 5.object_id` was false for an element of a mixed Array, a parameter or an instance variable given two kinds, a Hash value, a value picked by a condition, and through `&.`, `send`, `map(&:object_id)` and `method(:object_id)`.

`sp_poly_object_id` reads the tag and answers what the kind answers unboxed. A String, an Array, a Float, a big Integer and every other kind keep the payload's bits, as before.

Not in this change: nil held in a slot typed String (`y = c ? nil : "s"; y.object_id`) still answers 0, and a Symbol's id can still equal false's, nil's or true's (`:ab.object_id == false.object_id` is true for a program's first Symbol).

On master a3941433: `make cident` reports 6,337 identical, 33 differ: the new test and 32 that ask a boxed value's `object_id`, 21 of them in the ffi and fiddle packages. The 32 answer as on master, plain and under `SPINEL_GC_STRESS=1` and `2` (seven of the package tests stop under stress 2 on master, "the mark reached a freed slot", and stop the same way here). The new test is wrong on master at 20 of its 22 lines.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
