<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

After `=~`, a `when` arm, a match from a position or `slice!`, a group past the fifteenth read
as `""` at position 0, or as the match before:

```ruby
s = "abcdefghijklmnopqrstuvwxyz"
s =~ /(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)(r)(s)(t)/
p $~.to_a[16], $~.begin(20)
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-"p"
-19
+""
+0
```

`sp_re_caps[64]` holds two ints a group. `sp_re_match`, `sp_re_match_at` and `sp_str_slice_re`
passed the engine 32, the count of groups, where it counts ints; every other caller that fills
the registers passes 64, and now these three do. No program's generated C changes
(`make cident`). A match of fewer than sixteen groups costs the same; one of twenty groups
pays 8 instructions more, the eight ints it now copies (callgrind, 200,000 matches, master
5390d300).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
