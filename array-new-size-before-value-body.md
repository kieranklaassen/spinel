<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`Array.new(n, value)` ran the value before n when the value needs statements of its own:

```ruby
def note(x)
  puts "n#{x}"
  x
end
p Array.new(note(2), [note(4), note(5)])
```

```
spinel diff: output-diff
  program: order.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,4 +1,4 @@
-n2
 n4
 n5
+n2
 [[4, 5], [4, 5]]
```

The arm in `emit_new_call_arms` wrote the value's statements to the prelude and only then the line that computes the size. That line is now written first. A value that is one C expression was in Ruby's order already.

The same move closes what the pull request this stands on leaves under "Not here": a value those statements make was held by nothing while the size ran, so `Array.new((s + u).size - 4, begin; s + t; end)` kept a freed String under `SPINEL_GC_STRESS=1` and stopped in the mark under 2.

The negative-size check stays where it was, after the value's statements: `Array.new(-1, [note(9), note(10)])` prints n9 and n10 and then raises, on CRuby, on master and here.

**Measured against CRuby 3.3.6 on master b4d30a1d, over the pull request this stands on** (both were run again over the same programs on d02a49fb, where this branch stands, and no answer moved). The 1,979 generated programs of that pull request: eighteen change, all of one shape, a value its own statements make beside a size that allocates. Ten of 252 (nine sizes beside fourteen values) stopped under `SPINEL_GC_STRESS=2`; of eight more, three printed a wrong Array in a plain run of 3,000 kept Arrays (`rows << Array.new(churn(s, u), begin; s + t; end)`), and five stopped under `SPINEL_GC_STRESS=2`, two of them wrong under 1 as well. All eighteen are right here. No other cell moves, and none moves from a stop or a raise to a wrong answer. The order itself is in the test: five of its lines print n before the value's notes here and after them on master.

**Cost.** None. `Array.new(note(2), [k, k + 1])` 200,000 times: 98,318,007 instructions before and after (callgrind, gcc); the line moves and nothing is added.

**Not here.** A value written as one expression is still evaluated after the negative-size check: `Array.new(-1, note(3))` raises before `note(3)` runs, and CRuby runs it first.

**Generated C.** `make cident` against the pull request this stands on: `6402 identical, 3 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The three are the new test, `test/array_new_container_default.rb` and the test of the pull request this stands on: in the last two the size's line moved and nothing else changed. Whether optcarrot's generated C changes is not known: there is no checkout of it where this was written.

**Test.** `test/array_new_size_before_value.rb`, also in `GC_STRESS_TESTS`: on master five of its 25 lines are wrong in a plain run, seven under `SPINEL_GC_STRESS=1`, and it stops under `SPINEL_GC_STRESS=2`. Here it prints the same plain, at both stress levels with and without `SPINEL_GC_VERIFY=1`, built with clang, and under `--share-strings`; `make gc-stress-test` passes. The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written. The test prints Strings, Integers and Arrays.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: the pull request "Array.new(n, value) holds a value made in place while the Array is made"
