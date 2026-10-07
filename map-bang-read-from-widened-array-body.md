<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A local read out of an Array that `map!` rewrote with another kind of element was typed from the Array as it began.

```ruby
t = [1.5, 2.5]
t.map! { |e| e == t[0] ? :k : e }
r = t.first
p r
```

```
spinel diff: exception-diff
  program: lead.rb
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): TypeError: can't convert Symbol into Float

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +0,0 @@
-:k
```

A String read out of what began as an Integer Array printed 0.

**The cost** is the one the pull request beneath states, for one more way an Array is widened. A local read out of an Array that `map!` gave another kind is boxed, also where the element it read was of the first kind. A program with such a `map!` compiles slower: 250 of them, each read, took 2,929,042,429 instructions on the pull request beneath and 4,079,117,199 here (callgrind, `spinel -c`), 1.06 times the same program with the Array mixed from its literal (3,832,295,742 on master). A `map!` whose block answers the Array's own kind compiles to the same C; 250 of those cost the compiler 1.7% more (2,338,959,495 and 2,377,826,363), and a program with no `map!` 0.02% (2,334,139,078 and 2,334,563,098), since the widening is now asked in each round.

`widen_arrays_from_map_bang` makes the receiver the general Array once the types have settled, after each local was typed from its writes. The pull request beneath brackets the container fold in `infer_write_types`: a typed local Array that becomes the general Array between its two marks sends the scan of the writes round again with that local held general. The `map!` widening now also runs between the same two, beside the fold, and is seen the same way. Its call after the types settle stays where it was. One line.

Checked on master a785162aa:

- `test/map_bang_read_from_widened_array.rb` fails on master in its first five sections and passes here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`, with gcc and clang. Its sixth section holds a `map!` of the Array's own kind and one that never runs: right before and after.
- 1,792 generated programs (an Array of Integers, Floats, Strings or Symbols, 14 ways a `map!` or a `collect!` stands, 32 ways a local reads from the Array), each against CRuby: the C changes in 600 and all 600 are right, where before 310 were right, 161 printed a wrong answer and 129 raised. The other 1,192 compile to the C they have on the pull request beneath.
- `tools/cident.sh` against a785162aa: 6414 identical, 0 differ, 0 refusal changes. The two new tests (this one and the one beneath) are not in that reference; the one beneath compiles to the same C with and without this commit.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A local read out of a widened Array holds the element itself": this one adds a line between the two marks it makes; its two commits sit beneath this one with the same SHAs)
