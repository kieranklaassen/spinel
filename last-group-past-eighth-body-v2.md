<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`$+` walked the kept Strings one place off, so a ninth group answered the eighth, and a group
past the ninth was never reached:

```ruby
"abcdefghi" =~ /(a)(b)(c)(d)(e)(f)(g)(h)(i)/
p $+
"abcdefghijkl" =~ /(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)/
p $+
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-"i"
-"l"
+"h"
+"h"
```

`$+` now calls `sp_re_last_paren_match`. Past the ninth group it walks the kept positions from
the pattern's last group down, where the positions are the match's own (`sp_re_caps_own`,
from the pull request beneath); the first nine it knows by their kept Strings, from the ninth
down. After `String#match`, which keeps Strings alone, it reads the Strings
(`test/regexp_last_paren_match_kept_match.rb`).

On master 5390d300 with the pull request beneath: `make cident`: 6,353 programs' C identical,
7 differ: 3 that read `$+`, 4 that print the compiler's revision. A read of `$+` costs 10
instructions more (callgrind, 200,000 reads).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A Regexp's tenth group and beyond are read by number)
