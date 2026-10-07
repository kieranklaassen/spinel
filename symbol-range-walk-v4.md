<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A fix with a stated cost: a Symbol Range that was right and that the compiler does not prove right takes the runtime's walk, about 800 instructions more on a short walk (`(:"002"...:"3")`, one name: 732 to 1,535 a walk with gcc, 736 to 1,479 with clang; callgrind, here and below, on 5390d3002). Five kinds are not proved; they are listed below.

A Symbol Range literal was walked by `String#succ` from the begin until the end was met or the name grew past the end's length. Ruby walks it as `String#upto` does, and that is only the last of `String#upto`'s cases:

```ruby
p (:y..:ab).to_a             # [] in Ruby, "y" sorts after "ab"; master: [:y, :z, :aa, :ab]
p (:Y..:b).to_a.size         # 10, one character each: every character between; master: 2
p (:"10"..:"9").to_a         # [], digits go by number; master: [:"10"]
p (:"1"..:"010").to_a.size   # 10; master: 999
p (:aa..:z).to_a             # [], the begin is the end's successor; master: [:aa]
p (:x..:ab).include?(:z)     # false; master: true
```

Both names are literals, so `emit_range_expr` asks at compile time whether the loop is `String#upto`'s walk for them (`sym_range_plain_walk`) and keeps the loop where that is proved, and for two names of digits past 18, which the runtime walks no better (below). Any other Range calls a new `sp_PolyArray_from_symbol_range`, which walks with `sp_str_upto_each`, the walk String Ranges use, and interns each name through the unit's own table. The other way is the runtime's walk for every Symbol Range: one emitter less, and a walk of one name then costs 1,073 instructions for 203.

A Range that keeps the loop pays for one thing, a root on the loop's cursor: 8 to 19 instructions on a walk of one name (callgrind, `(:qa..:qa).to_a` 1,000,000 times: 202,987,017 to 221,987,021 with gcc) and 64 on a walk of 26 (`(:qa..:qz).to_a` 100,000 times: 3,209,740,876 to 3,216,168,755).

A Range that was right and takes the runtime's walk is one of these:

- two names of digits where the end is not its own number at the begin's width: `(:"002"...:"3")`;
- a begin shorter than an end whose carry lands on a 0 that no letter or digit stands before: `(:"0"..:"0z")`, 100 names, 109,824 to 116,600 a walk with gcc and 127,853 to 129,219 with clang;
- a begin one character longer than the end that has the shape of the end's successor and is not it: `(:"1aa"..:"1z")`;
- two different names where either is not ASCII or holds a NUL;
- the empty name up to itself with the end excluded, `(:""...:"")`.

How many: over every pair of names of up to three characters from `0 9 z Z a - .` and of up to four from `1 9 a z -`, with both kinds of end (1,535,202 Ranges), the loop stepped by `String#succ` walks 768,628 as CRuby 3.3 does; the test accepts 766,544 of those and none of the others. 15,720 literals drawn at these kinds and compiled by this branch answer as Ruby does, but for 140 whose two names are digits past 18, walked as on master; of the 4,800 aimed at the kinds above, master answers 3,152 otherwise. A set whose walks pass a name of punctuation alone also meets the `sp_str_succ` difference named below.

The root: every name past the first is a String of its own, made by `sp_str_succ`, and nothing held it while its Symbol was made, which allocates when the name is new. `p (:ax..:az).to_a` aborts at `SPINEL_GC_STRESS=2` with gcc and with clang, and so does `test/symbol_range_enum.rb` on master.

Not in this change, each as on master:

- two names of digits past 18 keep the loop whether it is right or not, because the runtime walks by number only up to 18 digits: `(:"9999999999999999999"..:"10000000000000000001")` has its three names, `(:"10000000000000000000"..:"8")` has one for none, and a walk that does not end on master does not end here: `(:"10000000000000000001"..:"10000000000000000000")`, none in Ruby, and `(:"1"..:"0000000000000000003")`, three in Ruby;
- the loop steps by the runtime's `sp_str_succ`, which leaves `String#succ` at a name with no letter or digit that ends in 0x7F: `(:"-~"..:".!").to_a.size` is 55170 for Ruby's 36;
- a Symbol Range as a `when` value never matches (`case :c when :a..:e` goes to `else`);
- a Range of two Symbol variables raises TypeError when it is walked.

Test: `test/symbol_range_walk.rb`; 13 of its 28 lines differ from Ruby on master (4f8b737c1) in a plain run. It and `test/symbol_range_enum.rb` are added to `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none: the pre-commit check notes "literals past 2^31" for the test; they are the digits of two Symbol names on one line, `:"9999999999999999999"` and `:"10000000000000000001"`, and no Integer)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on 4f8b737c1)
- [ ] Depends on: # (nothing)
