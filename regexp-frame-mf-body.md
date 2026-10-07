<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A method saves its caller's `$~` where it performs a match. `match` counted only with a Regexp
in sight, so a method whose `match` took a String pattern, or a pattern that is a Regexp or a
String only as the program runs, left its own match to its caller:

```ruby
def zero(s) = s.match("(0)")

"ab" =~ /(a)/
zero("x0")
p $1
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"a"
+"0"
```

`gsub`, `sub` and `scan` already count for those kinds of pattern. `match` now does too, in a
program where a method's registers are provably its own (`match_frame_closed`, from the pull
requests beneath). Every other program is emitted as before, byte for byte: a frame there
would take away the match of a block the method runs, as it would for a `when` arm.

On master 5390d300 with the pull requests beneath: no program's C changes but this pull
request's own test (`make cident`). A method that matches this way now pays the frame: 847
instructions a call (callgrind, 200,000 calls) and 16 bytes of C stack for the frame's cleanup,
so a recursion through such a `match` that ran 466,010 deep runs 419,409.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A method that matches keeps its caller's match alive across a collection), # (A matching method starts with no match; a jump out restores its caller's), # (A method matching in a `when` arm or a quantifier keeps its caller's $~), # (any?, all?, none? and one? given a Regexp stop where CRuby stops)
