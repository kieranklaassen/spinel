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

The arm now binds them as well when both operands are such reads: `operand_may_allocate`, which counts the copy and which `==` asks already (`emit_str_eq_ordered`). Everything else keeps its C: one shared operand beside a plain String or a literal is one copy, and `sp_str_plus` roots its arguments across its own allocation.

**Measured against CRuby 3.3.6 on master a2bd8900.** 162 generated programs: `X + Y` for every ordered pair of nine operands (two shared locals, two shared instance variables, a plain local, a literal, a reader call, and a shared local and a shared instance variable in parentheses), in a loop run by a block and by `while`, 1,500 turns that keep 62 Strings a turn.

| of 162 | master | this branch |
|---|---|---|
| `SPINEL_GC_STRESS=1`: wrong and silent | 52 | 0 |
| `SPINEL_GC_STRESS=2`: the mark stops | 72 | 0 |

The 72 are the pairs of two shared operands, the 52 those of two different ones. The other 90 are right on both, and none right on master changes; the clang builds give the same counts, and with `--share-strings` every count is the same. Six spellings of the sum among 96 other forms that read both Strings in one expression: `s + t`, `s.+(t)`, `s + t + s`, `(s + t) + (t + s)`, `s.send(:+, t)` and `s.public_send(:+, t)` are wrong under `SPINEL_GC_STRESS=1` and stop under 2 on master, and are right here; the other 90 forms are the same on both.

**Cost.** Two roots where both operands are shared. `r = s + t` 200,000 times: 182,285,702 instructions on master, 186,343,124 here (callgrind, gcc). One shared operand beside a plain String, and two plain Strings, are master's C.

**Not here.** Other forms that read two shared Strings in one expression make both copies in one C call the same way and are wrong or stop under stress on master and here: `s < t`, `case s when t`, a call's two arguments, `s.delete(t)`, `s.sub(t, s)`, `(s..t)`. They are other arms.

**Generated C.** `make cident REF=d02a49fb`: `6403 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The one is the new test. Whether optcarrot's generated C changes is not known: there is no checkout of it where this was written.

**Test.** `test/string_plus_shared_operands.rb`, also in `GC_STRESS_TESTS`: on master its four lines (two locals, in parentheses, called by name, two instance variables) are wrong in a plain run, built with gcc, with clang and under `--share-strings`. Here it prints the same plain, at both stress levels with and without `SPINEL_GC_VERIFY=1`, built with clang, and under `--share-strings`. The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written. The test prints Strings and Arrays.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
