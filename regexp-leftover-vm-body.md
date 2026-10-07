<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**Cost.** Ten instructions a statement more where the value is read from a call (722,685,669
to 724,687,380 over 200,000 statements, callgrind), also where the group took part and the
statement was right; none with a value in a local.

`s[/re/, n] = v` with a value that is not typed String and has code to run (a call, an element
of an Array of several kinds) stored into a group that took no part in the match: the String
was cut at the group's start, which is -1 for such a group. A number past the pattern's groups
stored wherever an earlier, wider match had left a span.

```ruby
s = +"hello"
begin
  s[/(e)(x)?(l)/, 2] = [1, "Q"].last
rescue IndexError => e
  p e.message
end
p s
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1 @@
-"regexp group 2 not matched"
-"hello"
+"Qo"
```

This arm reads its value after the match, and CRuby reads the value before it looks at the
String, so the two group tests were left out ahead of a value that runs code: a value that
raises must be heard first. They now come after it. What the match left (the span, and whether
the number is within the pattern's groups) is noted before the value runs, since the value may
match again; the value is read and held; then the two tests raise, in CRuby's order and with
CRuby's messages. A value with nothing to run keeps the tests ahead of it.

**Not here**, each as it was in this arm. A frozen receiver raises FrozenError first
(`f[/(e)(x)?(l)/, 2] = [1, "Q"].last` with `f` frozen), and a value of another kind its
TypeError (`s[/(e)(x)?(l)/, 2] = [1, "Q"].first`), where CRuby raises the IndexError of the
group. A negative number and a group past the ninth still raise IndexError before the value is
read (`s[/(e)(l)(l)/, -1] = [1, "X"].last`).

The test is right at GC stress unset and 1. At 2 it stops where `conv`, a method that matches,
is entered with a match live: the fault of master that "A method that matches keeps its
caller's match alive across a collection" cures, and above that pull request the test is right
at 2 as well.

On master ea8c6aaa with the pull requests beneath: beside this pull request's test, the C of two
tests changes (`make cident`: 6,366 identical, 7 differ, four of them the tests that print the
compiler's revision): `string_regexp_group_assign_raises` and
`string_regexp_group_assign_value_rooted`, which give the arm a value that runs code and print
the same at GC stress unset, 1 and 2.

The test's `.rb.expected` is the output of CRuby 3.3.6 with `--enable-frozen-string-literal`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (String#[]= with a Regexp group keeps its pieces rooted), # (String#[]= with a Regexp group raises for a missing group or nil), # (slice!(re, n) holds the head of the receiver while it cuts the tail), # (`s[re, n] = v` holds the head while it cuts the tail for any value), # (slice!(re, n) counts a negative group back and reaches the tenth), # (`s[re, n] = v` counts a negative group back from the last one), # (`s[re, n] = v` replaces the tenth group and beyond)
