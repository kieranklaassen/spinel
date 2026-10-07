<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A match keeps the Strings of nine groups and the positions of thirty-one, and every read by
number asked the Strings, with a bound of 9. Reading past it costs a match 5 instructions and a
call of a matching method 10 (callgrind, 200,000 of each, master 5390d300):

```ruby
"abcdefghijkl" =~ /(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)/
p $~[10], $~[12], $~[-1], $10
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,4 +1,4 @@
-"j"
-"l"
-"l"
-"j"
+nil
+nil
+nil
+nil
```

`$~.to_a[10]` was right. `sp_re_group` now answers a group by number: the kept String for 1 to
9, and past the ninth the subject cut at the kept position, as `` $` `` and `$'` are. A
negative number counts back from the pattern's last group. `defined?($10)`,
`Regexp.last_match(n)` and `s[re, n]` read through it too.

**Chosen: cut by position only where the positions are the match's own.** `String#match` and
`Regexp#match` hand `$~` their Strings and leave the positions at the match before, so one
int, `sp_re_caps_own`, says which it was. Where it does not hold, a group past the ninth
reads nil as before: `test/regexp_group_past_ninth_kept_match.rb`, right today, would print
another match's bytes. A method's frame saves the int in a spare bit of the flag beside it,
so `sp_re_frame` is 400 bytes before and after and a recursion runs as deep as it did (575
in a Fiber, 149,789 on the main stack).

**Rejected.** Keeping the Strings of all thirty-one groups: every match would pay for groups
few programs read, and the frame would grow.

Not here: `slice!(re, n)` and `s[re, n] = v` keep their bound of 9.

One route goes from right to wrong, through a leak master has. A method whose only match is a
`when` arm saves no frame, so its match is left in its caller's registers, and a caller with no
match of its own that then read `$~[-1]` or `$10` printed nil only because the group could not
be read. It now prints the arm's group, as `$~[1]` there already does.

On master 5390d300, `make cident`: 6,325 programs' C identical, 33 differ: 29 where a group is
read by number, 4 that print the compiler's revision.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
