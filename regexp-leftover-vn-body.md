<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**Cost.** One instruction a statement more with the number in a variable and a value that runs
code (728,082,970 to 728,282,970 over 200,000 statements, callgrind), also where the statement
was right; none with a literal number.

`s[/re/, n] = v` with a value that is not typed String and has code to run (a call, an element
of an Array of several kinds) still refused every negative group number and every group past
the ninth. With any other value the number already names its group at run time (the pull
requests beneath).

```ruby
s = +"hello"
s[/(e)(l)(l)/, -1] = [1, "X"].last
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

Where the number is not a literal from 0 to 9, this arm now names the group as the other one
does: a negative number counts back from the last group, and a group up to the fifteenth is
replaced by its span. The value runs before the group is tested, as in CRuby, so a group that
took no part raises "regexp group N not matched", by the number it came to, once the value has
run.

**Chosen: a number that names no group at all is refused ahead of the value, as it was.** Past
the pattern's groups, or a negative number past the first, it raised IndexError before the
value was read, and with a value of another kind CRuby raises that IndexError and not the
value's TypeError; tested after the value, those programs would change their error. A literal
from 0 to 9 is emitted as before, byte for byte.

**Rejected.** Testing every number after the value: right where the value prints or raises, but
it trades a right IndexError for a TypeError where the value is an Integer.

**Not here.** Where the number names no group, a value that prints or raises is not heard
before the IndexError: `s[/(e)(l)/, -4] = pick(0)` raises without running `pick`.

On master ea8c6aaa with the pull requests beneath: beside this pull request's test, the C of one
test changes (`make cident`: 6,368 identical, 6 differ, four of them the tests that print the
compiler's revision): `string_regexp_group_assign_value_missing`, which prints the same at GC
stress unset and 1 and stops at 2 as it did before (the pull request beneath says where).

The test's `.rb.expected` is the output of CRuby 3.3.6 with `--enable-frozen-string-literal`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (String#[]= with a Regexp group keeps its pieces rooted), # (String#[]= with a Regexp group raises for a missing group or nil), # (slice!(re, n) holds the head of the receiver while it cuts the tail), # (`s[re, n] = v` holds the head while it cuts the tail for any value), # (slice!(re, n) counts a negative group back and reaches the tenth), # (`s[re, n] = v` counts a negative group back from the last one), # (`s[re, n] = v` replaces the tenth group and beyond), # (`s[re, n] = v` raises for a missing group after a computed value)
