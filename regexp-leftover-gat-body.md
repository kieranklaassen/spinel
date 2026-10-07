<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An index assignment by a Regexp and a group number refused every group past the ninth of a
pattern that has them.

```ruby
w = +"abcdefghijklm"
w[/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)/, 10] = "X"
p w
```

```
spinel diff: exception-diff
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): IndexError: index 10 out of regexp

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +0,0 @@
-"abcdefghiXklm"
```

The assignment replaces a group by its span, and a match keeps the spans of the groups up to
the fifteenth. So the arm that names its group at run time (the pull request beneath) now takes
them, with the tests it makes of any group: past the pattern's groups is "out of regexp", a
group that took no part is "not matched". No instruction more (725,082,078 and 725,080,950
over 200,000 statements, callgrind).

**Not here.** A group past the fifteenth, for which a match keeps no span:
`w[/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)/, 16] = "X"` still raises "index 16 out of
regexp".

On master ea8c6aaa with the pull requests beneath: beside this pull request's test, the C of
three tests changes (`make cident`: 6,364 identical, 8 differ, four of them the tests that print
the compiler's revision): `string_regexp_group_assign_negative`,
`string_regexp_group_assign_raises` and `string_regexp_group_assign_rooted`, which name a group
in a variable and print the same at GC stress unset, 1 and 2.

The test's `.rb.expected` is the output of CRuby 3.3.6 with `--enable-frozen-string-literal`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (String#[]= with a Regexp group keeps its pieces rooted), # (String#[]= with a Regexp group raises for a missing group or nil), # (slice!(re, n) holds the head of the receiver while it cuts the tail), # (`s[re, n] = v` holds the head while it cuts the tail for any value), # (slice!(re, n) counts a negative group back and reaches the tenth), # (`s[re, n] = v` counts a negative group back from the last one)
