<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`s + t` answered `s + s` when both operands are Strings another name appends to in place. A plain run shows it:

```ruby
s = +"abc"
t = +"def"
a = s
a << "x"
b = t
b << "y"
words = ["k", "kk", "kkk", "kkkk", "kkkkk"]
keep = Array.new(64, "")
seen = []
n = 0
30000.times do |k|
  126.times do |j|
    keep[n % 64] = words[(k + j) % 5] + "q"
    n += 1
  end
  r = s + t
  seen << r unless seen.include?(r)
end
p seen
```

```
spinel diff: output-diff
  program: plus.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-["abcxdefy"]
+["abcxdefy", "abcxabcx"]
```

Built with clang the second String is `"defydefy"`.

A String that is aliased and appended to in place is a shared slot, and reading it makes a fresh copy. The String `+` arm binds its operands to rooted temporaries only where the node table shows an allocation (`subtree_may_allocate`), which a bare read of a variable does not, so both copies were made inside one C call:

```c
lv_r = sp_str_plus(/* a copy of lv_s */, /* a copy of lv_t */);
```

A collection that falls on the second copy frees the first, which nothing holds, and the second takes its slot. gcc makes the right operand's copy first and clang the left's, hence the two answers.

The arm now binds them as well when one operand ends in such a read and the other makes a copy too (`str_plus_operand_copy`). An operand ends in such a read when it is the read itself, as `operand_may_allocate` answers it for `==` (`emit_str_eq_ordered`); an assignment to such a variable, whose value is read back out of it (`(x = s) + (y = t)`); or a parenthesised sequence whose last statement is one of those (`(k; s) + (k; t)`). Everything else keeps its C: one shared operand beside a plain String or a literal is one copy, and `sp_str_plus` roots its arguments across its own allocation; an operand that ran ahead into a rooted temporary, as the receiver of `s&.+(t)` does, is held already.

This adds no sharing rule. The sum is a new String as before and each operand is read as before; the change is two roots. `--share-strings` makes more variables shared slots, so the same condition is met in more programs, and the counts below are given both ways.

**Measured against CRuby 3.3.6 on master 8dc55225.** Three sets of generated programs. Each runs the sum in a loop that keeps other Strings between sums, plain, under `SPINEL_GC_STRESS=1` and under 2.

128 programs: sixteen spellings of the two operands (the bare read; in parentheses; an assignment on both sides, on the left, on the right, to instance variables; a sequence that ends in the read, on both sides and on the right; a sequence that ends in an assignment; three in a chain; `if`; `s&.+(t)`; `&&`; `||`; `begin`; `case`), locals and instance variables in their four pairings, the loop run by a block and by `while`.

| of 128 | master | this branch | master, `--share-strings` | this branch, `--share-strings` |
|---|---|---|---|---|
| right in all three runs | 34 | 96 | 20 | 96 |
| right plain, wrong under 1, the mark stops under 2 | 81 | 29 | 94 | 29 |
| wrong in a plain run | 13 | 3 | 14 | 3 |

The 32 left are the `&&`, `||`, `begin` and `case` operands, named below.

162 programs: `X + Y` for every ordered pair of nine operands (two shared locals, two shared instance variables holding other text, a plain local, a literal, a reader call, and a shared local and a shared instance variable in parentheses), the loop run by a block and by `while`.

| of 162 | master | this branch |
|---|---|---|
| right in all three runs | 90 | 162 |
| wrong under `SPINEL_GC_STRESS=1`, the mark stops under 2 | 52 | 0 |
| right under 1, the mark stops under 2 | 20 | 0 |

The counts are the same with `--share-strings`.

96 programs, each another form that reads both Strings in one expression. 65 are right in all three runs on master and here. The six that are a sum (`s + t`, `s.+(t)`, `s + t + s`, `(s + t) + (t + s)`, `s.send(:+, t)`, `s.public_send(:+, t)`) were wrong under `SPINEL_GC_STRESS=1` and are right here; with `--share-strings` a seventh, the sum inside `then`, is cured too. The other 25 (24 with the flag) fault the same way on both: comparisons, `case`, a call's two arguments, `concat`, `sub`, `tr` and the Range forms are other arms. None changes for the worse.

**Cost.** Two roots where both operands are shared, about 20 instructions a sum. 200,000 sums each (callgrind, gcc):

| | master | this branch |
|---|---|---|
| `r = s + t`, both shared | 182,284,521 | 186,343,071 |
| `r = (x = s) + (y = t)` | 182,895,088 | 186,953,638 |
| `r = (k; s) + (k; t)` | 182,284,521 | 186,343,071 |
| `r = s&.+(t)` | 185,543,902 | 185,543,902 |
| `r = s + u`, one shared and one plain | 148,748,176 | 148,748,176 |
| `r = s + u`, two plain Strings | 98,456,073 | 98,456,073 |

**Not here.** In this arm, an operand written with `&&`, `||` or `case` still makes its copy in the same C call as the other one, and those sums are wrong or stop under stress on master and here. A `begin ... end` operand hands its copy over through a statement temporary that nothing holds, which is the `begin`'s fault and not the sum's. `arr << (s + t); arr[0] << "m"; puts arr[0]` prints `abcxdefy` for `abcxdefym` in a plain run on master and here; with two plain Strings master prints the same. Other arms that read two shared Strings in one expression make both copies in one C call the same way: `s < t`, `case s when t`, `s.delete(t)`, `s.sub(t, s)`, `(s..t)`, and a call's two arguments at top level (inside an instance method those are right on both).

**Depends on, in words.** This stands on "A String made in place is kept alive while it becomes a new Symbol". `(s + t).to_sym.to_s` stops in the mark under `SPINEL_GC_STRESS=2` on master; with the sum held and without that commit it would run on and print freed bytes. With both it prints `abcxdefy` in every run.

**Generated C.** `make cident` against the commit this stands on: `6447 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The one is the new test. Whether optcarrot's generated C changes is not known: there is no checkout of it where this was written.

**Test.** `test/string_plus_shared_operands.rb`, also in `GC_STRESS_TESTS`: on master its seven lines (two locals, in parentheses, called by name, two instance variables, an assignment's value, a sequence's last statement, instance variables assigned) are wrong in a plain run, built with gcc and with clang. Here it prints the same plain, at both stress levels with and without `SPINEL_GC_VERIFY=1`, built with clang, and under `--share-strings`. The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written. The test prints Strings and Arrays.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
