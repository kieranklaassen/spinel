<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An index assignment by a Regexp and a group number refused every negative number. CRuby counts
a negative number back from the last group, and only one past the first group is out of the
regexp.

```ruby
s = +"hello"
s[/(e)(l)(l)/, -1] = "X"
p s
```

```
spinel diff: exception-diff
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): IndexError: index -1 out of regexp

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +0,0 @@
-"helXo"
```

A number that is not a literal from 0 to 9 now names its group at run time. The group it comes
to is tested like any other: one that took no part raises "regexp group 1 not matched" by the
number it came to, as in CRuby, and a frozen receiver raises FrozenError only where CRuby gets
as far.

**Chosen: only where the arm tests its group.** A literal from 0 to 9 is emitted as before,
byte for byte. So is the arm that tests no group because its value runs code of its own first:
counted back there, a negative number could come to a group that took no part, and the String
would be cut at no position where it raises today.

A number in a variable costs nothing measurable (725,080,950 and 725,082,078 instructions over
200,000 statements, callgrind).

On master ea8c6aaa with the pull requests beneath: beside this pull request's test, the C of two
tests changes (`make cident`: 6,364 identical, 7 differ, four of them the tests that print the
compiler's revision): `string_regexp_group_assign_raises` and
`string_regexp_group_assign_rooted`, which name a group in a variable and print the same at GC
stress unset, 1 and 2.

The test's `.rb.expected` is the output of CRuby 3.3.6 with `--enable-frozen-string-literal`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (String#[]= with a Regexp group keeps its pieces rooted), # (String#[]= with a Regexp group raises for a missing group or nil), # (slice!(re, n) holds the head of the receiver while it cuts the tail), # (`s[re, n] = v` holds the head while it cuts the tail for any value), # (slice!(re, n) counts a negative group back and reaches the tenth)
