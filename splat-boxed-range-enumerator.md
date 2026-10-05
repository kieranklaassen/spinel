<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A Range whose kind is known only at run time, and an Enumerator, went through a splat as one element, with nothing said:

```ruby
def u(v) = [0, "s"].push(*v)
u([1])                             # so the parameter is boxed
p u(3..4)                          # [0, "s", 3..4]; CRuby [0, "s", 3, 4]
r = [1..2, "s"][0]                 # a Range read out of a container
p u(r)                             # [0, "s", 1..2]; CRuby [0, "s", 1, 2]
c = [0]
c.push(*[1, 2, 3].each_slice(2))
p c                                # [0, #<Enumerator: ...>]; CRuby [0, [1, 2], [3]]
```

`sp_splat_to_array`, the run-time half of a splat, knew nil, an Array and a Hash and wrapped any other value in a one-element array. It now answers the members of an Integer or String Range and the items an Enumerator yields (`sp_enum_items_from`), as their `to_a` does. An endless Range raises RangeError there, as in CRuby. `lib/spinel_rt.h` gains five lines and nothing in `src/` changes, so no program's generated C changes.

Every caller gains it: `push`, `append`, `unshift`, `prepend` and `insert` with a splat, the arguments of a method called with a boxed splat, `values_at`, `break *v`.

Not changed here: `[*v]` and `x, y = *v` lower their splat without `sp_splat_to_array` and still take such a value as one element, and a Float Range is still wrapped where CRuby raises TypeError.

One test, `test/splat_spreads_boxed_range_and_enumerator.rb`. On master c1d108abe with the pull request this one depends on, 21 of its 42 lines are wrong; with this commit all 42 are right, under `SPINEL_GC_STRESS=1` and `=2` too. The 153 other programs in `test/`, `benchmark/` and `packages/*/test/` whose C calls `sp_splat_to_array` print what they printed.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (CRuby 4.0.7 with that flag prints exactly the test's `.expected`)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: nothing in `src/` changes)
- [ ] Depends on: #FIRST_SPLAT_PR ("A splat pushed onto an empty array literal spreads its elements"; this commit sits on that one, and one section of the test pushes onto `[]`)
