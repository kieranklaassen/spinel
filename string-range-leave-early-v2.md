<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p ("a".."zzzzzzzz").find { |s| s == "c" }          # CRuby: "c". Here: out of memory
p ("a".."zzzzzzzz").first(3)                       # CRuby: ["a", "b", "c"]. Here: out of memory
("a".."zzzzzzzz").each { |s| break if s == "c" }   # the same
```

Every traversal of a String Range rides `R.to_a`: the whole element array is built before the block sees "a", and that array is the Range, here 2 * 10^11 Strings.

Four commits, one cause each.

1. `sp_str_walk_first` and `sp_str_walk_next`: the walk of `sp_str_upto_each`, case for case, taken a member at a time, for a caller whose loop body is inline C. `sp_str_upto_each` is not touched. The pair has an object of its own, `lib/sp_str_walk.c`: `lib/sp_array.c` and `lib/sp_cold.c` each sit at gcc's inline limit for a unit, and with the pair in `lib/sp_cold.c` gcc no longer inlined `sp_str_eq` into nine functions there that have nothing to do with a Range (`sp_srange_eq`, `sp_dir_pwd`, `sp_math_lgamma` among them). In its own object no other object of the runtime changes by a byte. Nothing calls the pair yet.
2. `each` with a literal block of at most one plain parameter, `for`, and `String#upto` with a block walk on the pair and build no array, where nothing reads the call's value: a statement, the body of a `for`, the arm of an `if` that is a statement, the last statement of a method on a local. Where the value is read the call is what it was.
3. The methods `builtins/enumerable.rb` defines over `each` (find, detect, find_index, any?, all?, none?, one?, take_while, drop_while, each_with_object, count, partition, group_by, filter_map, flat_map and the rest), called with a block on a String Range, are left to that definition.
4. `first(n)`, `take(n)` and `min(n)` stop the walk at the nth member.

**A block that may change its member keeps the array.** `each { |s| s << "!" }`, a block that hands its member to a method that appends to it, or one that appends through another name: the walk asks the tests `promote_shared_stored_strings` makes of an element's block, and where one holds the call rides `R.to_a` as it did. What refuses that block, or shares its member under `--share-strings`, is the code that did, and the sharing pass is not touched. A parameter the share rule makes the handle takes a handle of its member, as the element array's `each` binds its element.

**Measured on master 8dc55225 against CRuby 3.3.6, with gcc, plain and under `SPINEL_GC_STRESS=1` and `2`, without `--share-strings` and with it.** 2,265 generated programs: 37 block methods by five receivers (five members, none, two digit ends, 2 * 10^11 members left by `break`, ends made on the spot) by five blocks (plain, appending to its member, `upcase!` on it, `break`, collecting into an outer Array) by five positions (printed, assigned, a statement, a condition, a method's value).

- Without the flag 580 are refused before and after with the same message, the generated C of 796 does not change and that of 889 does. With the flag: 468, 908, and the same 889. In neither mode is a program refused that was built, or a message changed.
- Of the 889, without the flag: 52 that ran out of memory are right at all three levels, and 729 are right before and after. 9 run out of memory before and after (`cycle`, `min_by`, `max_by`). 75, with both ends made on the spot, abort at level 2 before and after: the begin is freed while the end is made, which is "A String Range made on the spot keeps its ends, made in order, until it is read". 10 are a method that ends in `each` and whose Range is then printed: 6 are wrong at level 2 before and after, and 4, with a `break` in the block, print the member Array on master at every level and the Range here, right in a plain run and at level 1. 14 print a Hash, which 3.3.6 spells the older way, the same line before and after. None that is right at a level is wrong or stops at that level here.
- The flag changes the C of 137 of the 889. Run with it: 105 right before and after, 9 out of memory made right, 9 that abort at level 2 before and after, the 14 Hashes.
- 116 more keep a member (pushed onto an Array, assigned out of the block, or handed back by `find`, `take_while`, `first(n)` and the like) and change it afterwards. Without the flag each prints the line it printed on master. With it, 50 are right before and after, 8 do not converge before and after, and 58 are right here that are not on master: in 50 the append is lost there (a member kept from `take_while`, `drop_while`, `each_with_object`, `filter_map`, `partition`, `group_by` or `find`), and 8, `each_with_index`, do not compile there.

**Cost** by callgrind, whole program, instructions, a gcc build then a clang build:

| | master | this branch | |
|---|---|---|---|
| `("a".."e").each { \|s\| n += s.size }`, 20,000 times | 40.84M, 38.20M | 32.05M, 30.95M | -21.5%, -19.0% |
| `("a".."zz").each { \|s\| n += s.size }`, 200 times | 112.44M, 105.11M | 96.81M, 96.31M | -13.9%, -8.4% |
| `("a".."e").find { \|s\| s == "c" }`, 20,000 times | 32.49M, 32.37M | 20.40M, 22.85M | -37.2%, -29.4% |
| `("a".."e").first(2)`, 20,000 times | 29.91M, 28.74M | 13.62M, 12.77M | -54.5%, -55.6% |

`("a".."zz").to_a`, `map`, `select` and `inject` over five members, `each` with its value read, `include?`, `==` of two String Ranges, an Enumerator's `take` and `transpose` compile to the C they did and cost what they did, to the instruction.

**Still on the whole array**, so still out of memory over a Range that long: `each` and `each_with_index` where the value is read (`x = r.each { }`, a condition, a receiver); `inject` and `reduce`, whose definition seeds from `first`, a Range's begin even when the Range holds nothing; `grep` and `grep_v`; `map`, `select`, `reject`, `sort_by`, `min_by`, `max_by`, `cycle`, `each_slice`, `each_cons`, `each_entry`, `reverse_each`, `step`, `zip`, `lazy`, the forms with no block, `find_index(v)`, `any?(pattern)`, a block of two parameters, a splat parameter or `&blk`; and `first(n)` or `take(n)` whose count is a block's parameter (`[1, 2].map { |n| r.first(n) }`).

**Tests.** `test/string_range_each_walks.rb`, `test/string_range_each_value.rb`, `test/string_range_enumerable_walks.rb`, `test/string_range_first_n.rb`, each printing the same under `SPINEL_GC_STRESS=1` and `2`. `test/reject/string_range_each_member_append.rb` and `test/reject/string_range_member_append.rb`: an appending block is refused as it was. Under `make share-strings-test`, `test/share/share_strings_string_range_each_member.rb` and `test/share/share_strings_string_range_enumerable_member.rb`, which keep a member and change it; the second does not compile on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
