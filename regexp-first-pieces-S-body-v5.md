<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`any?`, `all?`, `none?` and `one?` given a Regexp ask it of an element at a time and stop where
the answer is known: `any?` and `none?` at the first match, `all?` at the first miss, `one?` at
the second match. Spinel asked every element and counted, so `$~` was left at the last
element's:

```ruby
a = ["xb", "q", "yb"]
p a.any?(/(.)b/), $1
p a.all?(/(.)b/), $~
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,4 +1,4 @@
 true
-"x"
+"y"
 false
-nil
+#<MatchData "yb" 1:"y">
```

The loop now stops at those points; the answers do not change. Where `all?` stops at a nil
element it leaves no match, as CRuby does.

**Chosen: stop where a method's registers are provably its own (`match_frame_closed`), or are
never read.** In a program that reads `$~` and fails that test, a method whose only match is
the quantifier saves no frame, so its caller reads what it leaves, and a stop would change a
right answer (`test/quantifier_regexp_count_kept_proc.rb`); so does a `class << self` body or
a required file's top level that reads `$~` after a quantifier at the top level. There the
count stays, byte for byte.

**Rejected.** Stopping in every program: that test, right today, would print the first match.

On master 5390d300 with the pull requests beneath: beside the tests the C of one program of the
corpus changes, `test/array_float_conformance.rb`, by the stop (`make cident`). Four
quantifiers over eight Strings, 200,000 times, cost 480.6M instructions where they cost
1,756.8M (callgrind).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A method that matches keeps its caller's match alive across a collection), # (A matching method starts with no match; a jump out restores its caller's), # (A method matching in a `when` arm or a quantifier keeps its caller's $~)
