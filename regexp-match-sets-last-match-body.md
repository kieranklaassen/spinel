<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

After `String#match` or `Regexp#match`, `$~` kept the positions and the pattern of the match
before it. Only the Strings behind `$1` and `$~[n]` were the new match's:

```ruby
line = "2026-10-05 x"
line.match(/(\d+)-(\d+)/)
p $~.to_a, $~.begin(2)
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-["2026-10", "2026", "10"]
-5
+["", "", ""]
+0
```

After a match on another String it printed pieces of the new subject cut at the old positions,
and a named group of the new pattern raised IndexError.

`sp_re_matchdata` and `sp_re_matchdata_at` ran the engine into a caps array of their own and
handed the registers the Strings alone. Both now call `sp_re_set_last_match`, as `gsub`, `sub`
and `scan` do. A `match` costs 52 instructions more (callgrind).

On master dafa0d047, with `SPINEL_GC_STRESS` unset, 1 and 2: 21 of the test's 26 lines differ
on master, none with this. No program's generated C changes, and the 96 corpus programs that
reach the two functions answer as before. Of 660 generated programs (eleven ways to call
`match`, by what matched before, by twenty reads of `$~`) 288 are wrong on master and none
with this.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
