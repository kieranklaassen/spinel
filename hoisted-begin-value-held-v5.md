<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** A `begin` or a `catch` read as a value lost its value when what came after it in the same expression allocated before the value was read: a `begin` or a `catch` of its own, an Array literal, a call with a block. The cost is a root for each such value that something reads through a call, an operator or a list of arguments: 9 to 40 instructions built with gcc, 16 to 25 with clang (the numbers are below). Most programs that pay it were right on master. A `begin` or a `catch` that is its statement, all that a write stores (`x = begin ... end`), or the one value a `return` hands back pays nothing: its generated C is master's.

```ruby
def churn(n)
  i = 0
  x = nil
  while i < n
    x = ["c#{i}", "d#{i}"]
    i += 1
  end
  x
end
def tags_of(i)
  churn(200)
  ["t" + i.to_s, "x"]
end

rows = []
300.times do |i|
  rows << (begin; tags_of(i); rescue; ["q"]; end) + (begin; tags_of(i); ensure; churn(10); end)
end
churn(2000)
bad = 0
rows.each_with_index { |r, i| bad += 1 unless r == ["t#{i}", "x", "t#{i}", "x"] }
p bad
p rows.find { |r| r.size != 4 || r[0][0] != "t" }
```

Ruby prints `0` and `nil`. Master (84f5b5020), in a plain run built with gcc or clang, prints `38` and `["c192", "d192", "t6", "x"]`: the first Array of a row was freed, and one that `churn` made took its place.

A `begin` read as a value runs ahead of its statement, into a temp the expression then reads (the `BeginNode` arm of `emit_expr`). The temp was rooted only when the `begin` had an `ensure` body, for the time that body runs. But the value also waits in it while whatever an operand after it puts ahead of the statement runs: here the second `begin`, with the first one's Array in a temp nothing else knows. The same expression shapes are wrong on master with a Struct's `super(begin ... end, begin ... end)`, positional or with keywords, with two Strings added, with an interpolation of two such values, and with a method called on the first one. A plain call, a class's `super`, `Struct.new` and an Array or Hash literal hold their arguments themselves and were right. `catch` as a value has the same temp and the same window, on either side.

A second `begin` is one way the window opens. On master (counted on 0e8befeb3) these lose the value too, each with one `begin` and a plain call after it: an Array literal as the other operand (`(begin; name_of(i); rescue; "x"; end) + [tag_of(i)].first`: none of 300 wrong in a plain run, all 300 at `SPINEL_GC_STRESS=1`), and a call with a block (`+ [i].map { |k| tag_of(k) }.join`: 1 of 300 in a plain run, 300 at level 1). So do `format` with a call's String (`+ format("%s", tag_of(i))`: 1 and 300), a conversion in place (`+ (i >= 0 && tag_of(i))`: 0 and 300), and a reader that allocates before it reads the value (`Array(begin ... end) + [tag_of(i)]`: 26 and 300). Each is right with this change at every level, gcc and clang.

Both temps are now rooted where they run ahead of the statement, for every kind that holds a reference, the two Strings of a String Range among them (a `begin` whose value is a String Range loses 19 of 300 in a plain run on master). A `begin` emitted as a statement expression is read where it stands and keeps the root it had.

Three places take no root (`hoisted_value_is_stmt`), because the temp is read as soon as it is written and nothing runs in between: a `begin` or a `catch` that is the statement being emitted (the last statement of a method, say), one that is all a write to a local, an instance variable or a global stores (`x = begin ... end`, `@v = catch(:t) { ... }`), and one that is the one value a `return` hands back (`return begin ... end`). Master is right in the first two, and the generated C of all three is master's, whatever the store does with the value (a local changed in place, a boxed or a captured local). A `return` copies the value into its own slot at once, ahead of any `ensure` body around it, and the temp's root is gone by the time that body runs, so a root there held nothing; what holds the `return`'s own slot while an `ensure` body runs is master's, and is not touched. Every other place keeps the root, also where the reader happens to allocate nothing before it reads (`(begin ... end).size`): telling those readers apart needs a list of every builtin that allocates before it reads its receiver or an operand, and the ones that do are where master is wrong.

Cost, by callgrind on 84f5b5020: a loop that evaluates one such value 300,000 times and does nothing else with it but take its size, at the top level and inside a method.

| | gcc before | gcc after | clang before | clang after |
|---|---|---|---|---|
| `(begin; f(i); rescue ArgumentError; "x"; end).size` | 224,631,007 | 227,932,845 | 226,656,594 | 232,659,359 |
| the same in a method | 222,640,868 | 225,642,899 | 226,957,746 | 232,959,388 |
| `(begin; i += 0; f(i); end).size` | 203,029,209 | 207,530,643 | 202,226,355 | 207,632,683 |
| the same in a method | 206,019,653 | 208,731,814 | 202,227,496 | 207,632,701 |
| `(catch(:done) { f(i) }).size` | 230,022,192 | 235,423,328 | 229,358,335 | 235,961,090 |
| the same in a method | 224,142,197 | 228,943,733 | 229,659,429 | 236,259,934 |

That is 11, 15 and 18 instructions a value with gcc at the top level and 10, 9 and 16 in a method (1.3% to 2.4% of these loops), and 20, 18 and 22 with clang in either place (2.6% to 2.9%). Those loops are `300_000.times` blocks. Another loop of the same kind pays more with gcc inside a method, where master's loop was tighter: `(begin; f(i); rescue ArgumentError; "x"; end).size` in a `while` of a method ran 219,371,236 before and 231,222,481 after, 39.5 a value and 5.4% of that loop (21 with clang), and the `catch` there 38.5 (25 with clang); a `while` at the top level pays 13 to 19 with gcc and 16 to 23 with clang. A `begin` or a `catch` that is all a write stores (`x = begin; f(i); rescue ArgumentError; "x"; end`, then `x.size`) or the one value of a `return` is the same C before and after, compared byte for byte for six such loops. A value of a kind that holds no reference (an Integer, a Float, true or false) takes no root. On master 84f5b5020 the generated C of 71 of the 6,608 programs under `test/`, `benchmark/` and `packages/*/test/` changes, each by such a root. Each of the 71 was built by master and by this change and run plain and at level 1: every one answers the same on both, 70 with their `.expected` and `test/fiber_kill_self.rb` with its `.expected` and exit status 1 on both.

One decision: the root is not left to the expression that reads the value. The call arms that hold their arguments do root a temp like this one a second time; the readers that do not are many (every operator and builtin that takes two operands), and the temp is the one place they share.

**Not in this change:**

- A String Range written with a call on each side, `r = (f(i)..g(i))`, does not hold its first end while the second is made: of 300 such Ranges 26 are wrong in a plain run and all 300 at `SPINEL_GC_STRESS=1`, on master and here (the same C). It is another temp, in the Range literal.
- The order of effects, which is master's: a later operand that appends to the String the `begin` answered is not seen through it. `(begin; s; rescue; "q"; end) + (begin; s << "zz"; t; ensure; churn(10); end)` answers `s` without the `"zz"` in a plain run on master, which aborts on it at level 2; here level 2 prints that same line.

Test: `test/hoisted_begin_value_held.rb`, in `GC_STRESS_TESTS`. It counts the wrong values of 300 for nine shapes: a Struct's `super` without and with keywords, two Strings added, two Arrays added, an interpolation, a String Range, a receiver, and a `catch` on the left and on the right. On master (84f5b5020) a plain run prints 30, 37, 1, 37, 0, 19, 3, 1 and 0 (gcc and clang alike), `SPINEL_GC_STRESS=1` prints 300, 300, 300, 296, 300, 299, 300, 300 and 300, and it aborts with the verifier and at level 2; with this change it prints nine zeros in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang, and the same with `--share-strings`.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here, built from nothing, on master 84f5b5020: the test in the seven collector lanes with gcc and clang, with and without `--share-strings` (master is wrong or aborts in all seven; this change is right in every one); `ruby tools/gate.rb check`; the generated C of the 6,608 programs, changed in 71, each of them run; optcarrot, checksum 59662; `make share-strings-test` and `make int-min-test`, both pass; the cost table.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal` (nine lines of `0`); CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change. It depends on no other pull request.
