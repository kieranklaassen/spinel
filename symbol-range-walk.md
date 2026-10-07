<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Symbol Range literal was walked by `String#succ` from the begin until the end was met or the name grew past the end's length. Ruby walks it as `String#upto` does, and that is only the last of `String#upto`'s cases:

```ruby
p (:y..:ab).to_a             # [] in Ruby, "y" sorts after "ab"; master: [:y, :z, :aa, :ab]
p (:Y..:b).to_a.size         # 10, one character each: every character between; master: 2
p (:"10"..:"9").to_a         # [], digits go by number; master: [:"10"]
p (:"1"..:"010").to_a.size   # 10; master: 999
p (:aa..:z).to_a             # [], the begin is the end's successor; master: [:aa]
p (:x..:ab).include?(:z)     # false; master: true
```

Cost first. A Range that was right keeps the loop it had and pays for one thing, a root on the loop's cursor: 19 instructions on a walk of one name (callgrind, `(:qa..:qa).to_a` 1,000,000 times: 202,987,017 to 221,987,021) and 64 on a walk of 26 (`(:qa..:qz).to_a` 100,000 times: 3,209,740,876 to 3,216,168,755). Three kinds of Range the compiler does not try to prove take the runtime's walk whether they were right or not, and a short one that was right pays more: names that are not ASCII (`(:"é"..:"é")`: 203 to 1,099 a walk), a begin longer than its end (`(:aa..:b)`: 725 to 1,390), and an end whose carry lands on a 0 that no letter or digit stands before (`:"0z"`, `:"a.09"`).

One decision. Both names are literals, so `emit_range_expr` asks at compile time whether the loop is `String#upto`'s walk for them (`sym_range_plain_walk`) and keeps the loop where that is proved; any other Range calls a new `sp_PolyArray_from_symbol_range`, which walks with `sp_str_upto_each`, the walk String Ranges use, and interns each name through the unit's own table. The other way is the runtime's walk for every Symbol Range: one emitter less, and a walk of one name then costs 1,073 instructions for 203 while one of 26 one-character names costs 8,795 for 16,413. This change keeps what was right at its cost.

The test for "the loop is the walk" was checked against CRuby 3.3 over every pair of names of up to four characters from `0 9 z . -` and of up to three from `0 z 9 A - b 1` (1,535,202 pairs with both kinds of end): no pair it accepts is walked otherwise by Ruby. 10,920 random literals compiled by this branch answer as Ruby does; on master 1,476 of the first 7,200 walk another count of names.

The root: every name past the first is a String of its own, made by `sp_str_succ`, and nothing held it while its Symbol was made, which allocates when the name is new. `p (:ax..:az).to_a` aborts at `SPINEL_GC_STRESS=2` with gcc and with clang, and so does `test/symbol_range_enum.rb` on master.

Not in this change, each as on master: a Symbol Range as a `when` value never matches (`case :c when :a..:e` goes to `else`); a Range of two Symbol variables raises TypeError when it is walked.

Test: `test/symbol_range_walk.rb`; 13 of its 25 lines differ from Ruby on master (5390d3002) in a plain run. It and `test/symbol_range_enum.rb` are added to `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on 5390d3002)
- [ ] Depends on: # (nothing)
