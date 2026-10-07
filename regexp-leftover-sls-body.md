<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`s.slice!(/re/, n)` written as a statement, its value unused, took the pattern for a position
and raised.

```ruby
s = +"hello"
s.slice!(/(l)(l)/, 2)
p s
```

```
spinel diff: exception-diff
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): TypeError: no implicit conversion of Regexp into Integer

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +0,0 @@
-"helo"
```

The statement form has arms of its own for a String, an Integer or a Range, and two Integers,
and its two-argument arm read both arguments as Integers whatever the first was. It now
declines a Regexp literal, so the statement falls to the arms that answer the value, which cut
the group (the pull requests beneath), and the value is dropped.

**Chosen: a pattern that may have more than fifteen groups is left raising**, counted by its
parentheses. A match keeps no span past the fifteenth and the answering arm leaves the receiver
whole there: the raise would turn into a String silently not cut.

**Not here.** That statement over sixteen groups
(`w.slice!(/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)/, 16)`), and a group named by a
String (`s.slice!(/(?<a>l)/, "a")`), which raises TypeError before and after.

On master ea8c6aaa with the pull requests beneath: no program's C changes but this pull
request's own test (`make cident`: 6,370 identical, 5 differ, four of them the tests that print
the compiler's revision). The family of 154 statement programs behind the test: 4,968 lines
made right, none lost, the same with `SPINEL_GC_STRESS=2`.

The test's `.rb.expected` is the output of CRuby 3.3.6 with `--enable-frozen-string-literal`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (String#[]= with a Regexp group keeps its pieces rooted), # (String#[]= with a Regexp group raises for a missing group or nil), # (slice!(re, n) holds the head of the receiver while it cuts the tail), # (`s[re, n] = v` holds the head while it cuts the tail for any value), # (slice!(re, n) counts a negative group back and reaches the tenth), # (`s[re, n] = v` counts a negative group back from the last one), # (`s[re, n] = v` replaces the tenth group and beyond), # (`s[re, n] = v` raises for a missing group after a computed value), # (`s[re, n] = v` counts its group after a computed value too)
