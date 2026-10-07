<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

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

The loop now stops at those points. The answers do not change. Four quantifiers over eight
Strings, 200,000 times, cost 480.6M instructions where they cost 1,756.8M (callgrind).

**Chosen: stop where a method's registers are provably its own (`match_frame_closed`), or are
never read.** In a program that reads `$~` and fails that test, a method whose only match is
the quantifier saves no frame, so its caller reads what it leaves:

```ruby
def any_b?(a) = a.any?(/(.)b/)
pr = proc { |s| s =~ /z/ }
pr.call("q")
p any_b?(["xb", "q"]), $~     # true and nil in CRuby and today; a MatchData if the loop stopped
```

There the count stays, byte for byte.

**Rejected.** Stopping in every program: the program above, right today, would print the
first match.

On master dafa0d047:

- `test/quantifier_regexp_last_match.rb`: 5 of its 41 lines differ on master, none with this,
  with `SPINEL_GC_STRESS` unset, 1 and 2. The two `test/quantifier_regexp_count_kept_*.rb`
  are right before and after, and wrong on a build with the stop forced on.
- Of the corpus's 6,280 programs one changes, `test/array_float_conformance.rb` (two lines of
  C, the same output at all three levels).
- 1,226 generated programs (a quantifier in a method, a closure run inside a matching method,
  a matching body in a Fiber, a Thread or an Enumerator): 40 more are right, none is lost.

Left alone: `$~` after a quantifier in a program that reads the registers and fails the test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A method that matches in a `when` or in any?, all?, none? or one? keeps its caller's $~)
