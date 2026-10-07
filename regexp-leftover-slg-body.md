<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**Cost.** With the number in a variable, `slice!(re, n)` pays 12 instructions a call more
(728,281,823 to 730,690,408 over 200,000 calls, callgrind), also where the variable holds 1 to 9
and the call was right. A literal number pays nothing.

`slice!` with a Regexp and a group number knew the groups 1 to 9, by the Strings a match
keeps. Any other number answered nil and left the receiver whole: a negative one, which CRuby
counts back from the last group, and the tenth group and beyond.

```ruby
s = +"hello"
p s.slice!(/(e)(l)(l)/, -1), s

w = +"abcdefghijklm"
p w.slice!(/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)/, 10), w
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,4 +1,4 @@
-"l"
-"helo"
-"j"
-"abcdefghiklm"
+nil
+"hello"
+nil
+"abcdefghijklm"
```

A number that is not a literal from 0 to 9 is now settled at run time. A negative one counts
back from the last group, and one past the first is nil, as in CRuby. A group from the tenth to
the fifteenth, as far as a match keeps spans, is cut out of the receiver by its span and held
while the receiver is rebuilt. A literal from 0 to 9 is emitted as before, byte for byte.

**Not here.** A group past the fifteenth, for which a match keeps no span: `slice!` with 16 and
a pattern of sixteen groups is still nil.

On master ea8c6aaa with the pull requests beneath: no program's C changes but this pull
request's own test (`make cident`: 6,365 identical, 5 differ, four of them the tests that print
the compiler's revision).

The test's `.rb.expected` is the output of CRuby 3.3.6 with `--enable-frozen-string-literal`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (String#[]= with a Regexp group keeps its pieces rooted), # (String#[]= with a Regexp group raises for a missing group or nil), # (slice!(re, n) holds the head of the receiver while it cuts the tail), # (`s[re, n] = v` holds the head while it cuts the tail for any value)
