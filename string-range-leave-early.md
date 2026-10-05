<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p ("a".."zzzzzzzz").find { |s| s == "c" }          # CRuby: "c". Here: out of memory
p ("a".."zzzzzzzz").first(3)                       # CRuby: ["a", "b", "c"]. Here: out of memory
("a".."zzzzzzzz").each { |s| break if s == "c" }   # the same
```

All three answered at once until the String Range walk lost its 4096 cut (#7325): every traversal builds the range's whole element array first, and with no cut that array is the whole range. No cut comes back.

Four commits, one cause each:

1. `sp_str_walk_first` / `sp_str_walk_next` are added to `lib/sp_array.c`: the walk of `sp_str_upto_each`, case for case, taken a member at a time, for a caller whose loop body is inline C. `sp_str_upto_each` is not touched. Nothing calls the pair yet.
2. `each` with a block of at most one plain parameter, `for`, and `String#upto` with a block walk on the pair and build no array. `each` answers the range, as CRuby's does.
3. The methods `builtins/enumerable.rb` defines over `each` (find, detect, find_index, any?, all?, none?, one?, take_while, drop_while, each_with_index, each_with_object, inject, count, partition, group_by, filter_map, flat_map and the rest), called with a block on a String Range, are left to that definition.
4. `first(n)`, `take(n)` and `min(n)` stop the walk at the nth member.

**Measured against master ab9b925a, each line compared with CRuby.**

| | master | this branch |
|---|---|---|
| matrix of 253 generated programs, 38,465 lines: right | 35,956 | 36,012 (the 56 are #NNNN's, the minimum of an excluded end; these four commits change none) |
| 321 one-line programs that leave a range of 10^11 members early: right | 60 | 174 |
| the same: out of memory | 243 | 129 |

Nothing right on master is wrong, refused or non-building here. Generated C of 6,017 programs: 14 change, those that run `each`, `for`, `upto`, `first(n)` or a block method over a String Range.

**What it costs** (callgrind, whole program, instructions):

| | master | this branch | |
|---|---|---|---|
| `("a".."e").each { }` 20,000 times | 39,410,281 | 32,094,829 | -18.6% |
| `("a".."zz").each { }` 200 times | 105,969,448 | 98,081,208 | -7.4% |
| `find` in a short range | 28,298,607 | 18,121,281 | -36% |
| `first(2)` | 28,483,316 | 13,636,863 | -52% |
| `("a".."zz").to_a` | 1,016,916 | 1,019,756 | +0.3% |
| `("1".."10000").to_a` | 9,002,400 | 9,072,414 | +0.8% |
| `map` over five members | 45,373,857 | 46,753,857 | +3.0% |
| `select` over five members | 34,559,365 | 35,939,365 | +4.0% |
| `each_slice` over five members | 42,197,048 | 43,837,048 | +3.9% |

Memory no longer grows with the range for the callers this covers: a whole `each` over 12,356,630 members peaks at 644 MB on master and 10 MB here. The rows that cost more do not run the new code: with the pair in the file gcc no longer inlines `sp_str_alloc` into `sp_str_upto_each`.

**Still on the whole array**, so still out of memory over a range that long: `map`, `select`, `reject`, `sort_by`, `sum`, `min_by`, `max_by`, `cycle`, `each_slice`, `each_cons`, `each_entry`, `step`, `zip`, `chunk_while`, `slice_when`, `lazy`, the forms with no block, `find_index(v)`, `any?(pattern)`, a block of two parameters, a splat parameter or `&blk`, and a range read out of a boxed slot.

**Tests.** `test/string_range_each_walks.rb`, `test/string_range_enumerable_walks.rb`, `test/string_range_first_n.rb`; each prints the same under `SPINEL_GC_STRESS=1` and `2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: #NNNN
