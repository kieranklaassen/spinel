<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`String#match` and `Regexp#match` handed `$~` the matched Strings alone. Its positions and its
pattern stayed those of the match before:

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

`$1` and `$~[2]` were right: they read the Strings. After a match on another String `$~.to_a`
gave pieces of the new subject cut at the old positions, and a named group of the new pattern
raised IndexError.

**Chosen: a variant of the two runtime functions that hands over the positions and the pattern
too, emitted only where the match is provably its frame's own to leave**: in a program where a
method's registers are its own (`match_frame_closed`), and outside the block of a call that
itself matches (`gsub`, `scan`, `grep`, a quantifier). Elsewhere a program can be right today
because the positions stay behind (`test/match_last_match_kept_yielder.rb`: the block's match
is the block's frame's, and there is one set of registers), and it is emitted as before, byte
for byte.

**Rejected.** Handing them over in `sp_re_matchdata` itself: the three
`test/match_last_match_kept_*.rb`, right today, would each print another frame's positions.

Not here: a `match` whose receiver and pattern are both boxed (`emit_poly_call`).

On master b4d30a1d with the pull requests beneath: beside the tests the C of nine programs of
the corpus changes, by the variant's name alone (`make cident`). A `match` that takes the
variant costs 57 instructions more (callgrind, 200,000 calls).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A method that matches keeps its caller's match alive across a collection), # (A matching method starts with no match; a jump out restores its caller's), # (A method matching in a `when` arm or a quantifier keeps its caller's $~), # (any?, all?, none? and one? given a Regexp stop where CRuby stops), # (A method that matches a String pattern keeps its caller's match)
