<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** A `begin` or a `catch` read as a value lost its value when an operand after it in the same expression ran a `begin` or a `catch` of its own. The cost is a root for each such value: 10 to 16 instructions built with gcc, 18 to 25 with clang (the numbers are below).

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

Ruby prints `0` and `nil`. Master (3d629868d), in a plain run built with gcc or clang, prints `38` and `["c192", "d192", "t6", "x"]`: the first Array of a row was freed, and one that `churn` made took its place.

A `begin` read as a value runs ahead of its statement, into a temp the expression then reads (the `BeginNode` arm of `emit_expr`). The temp was rooted only when the `begin` had an `ensure` body, for the time that body runs. But the value also waits in it while whatever an operand after it puts ahead of the statement runs: here the second `begin`, with the first one's Array in a temp nothing else knows. The same expression shapes are wrong on master with a Struct's `super(begin ... end, begin ... end)`, positional or with keywords, with two Strings added, with an interpolation of two such values, and with a method called on the first one. A plain call, a class's `super`, `Struct.new` and an Array or Hash literal hold their arguments themselves and were right. `catch` as a value has the same temp and the same window, on either side.

Both temps are now rooted where they run ahead of the statement, for every kind that holds a reference, the two Strings of a String Range among them (a `begin` whose value is a String Range loses 19 of 300 in a plain run on master). A `begin` emitted as a statement expression is read where it stands and keeps the root it had; so does the statement form, `x = begin ... end`.

Cost, by callgrind on 3d629868d: a loop that evaluates one such value 300,000 times and does nothing else with it but take its size.

| | gcc before | gcc after | clang before | clang after |
|---|---|---|---|---|
| `(begin; f(i); rescue ArgumentError; "x"; end).size` | 225,531,355 | 229,432,890 | 229,356,214 | 235,358,968 |
| `(begin; i += 0; f(i); end).size` | 204,230,394 | 209,030,701 | 204,027,091 | 209,431,065 |
| `(catch(:done) { f(i) }).size` | 232,422,044 | 235,723,778 | 231,459,054 | 238,960,581 |

That is 13, 16 and 11 instructions a value with gcc (1.7%, 2.4% and 1.4% of these loops) and 20, 18 and 25 with clang (2.6%, 2.6% and 3.2%). The same loops inside a method cost 10, 12 and 16 with gcc and the same as above with clang. A value of a kind that holds no reference (an Integer, a Float, true or false) takes no root. On master 9c7ea3ce0 the generated C of 170 of the 6,512 programs under `test/`, `benchmark/` and `packages/*/test/` changes, each by such a root. Built by master and by this change, each of the 170 answers the same in a plain run and at `SPINEL_GC_STRESS=1`.

One decision: the root is not left to the expression that reads the value. The call arms that hold their arguments do root a temp like this one a second time; the readers that do not are many (every operator and builtin that takes two operands), and the temp is the one place they share.

**Not in this change:** a String Range written with a call on each side, `r = (f(i)..g(i))`, does not hold its first end while the second is made: of 300 such Ranges all 300 are wrong at `SPINEL_GC_STRESS=1` and none in a plain run, on master and here. It is another temp, in the Range literal.

Test: `test/hoisted_begin_value_held.rb`, in `GC_STRESS_TESTS`. It counts the wrong values of 300 for nine shapes: a Struct's `super` without and with keywords, two Strings added, two Arrays added, an interpolation, a String Range, a receiver, and a `catch` on the left and on the right. On master a plain run prints 30, 37, 1, 37, 0, 19, 3, 1 and 0 (gcc and clang alike), `SPINEL_GC_STRESS=1` prints 300, 300, 300, 296, 300, 299, 300, 300 and 300, and it aborts with the verifier and at level 2; with this change it prints nine zeros in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang, and the same with `--share-strings`.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master 9c7ea3ce0, built from nothing: the test in the seven collector lanes with gcc and clang, with and without `--share-strings` (master is wrong or aborts in all seven; this change is right in every one); `ruby tools/gate.rb check`; the generated C of the 6,512 programs, changed in 170, each of them run; optcarrot, checksum 59662; `make share-strings-test` and `make int-min-test`, both pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal` (nine lines of `0`); CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change. It depends on no other pull request.
