<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**Cost.** Thirteen instructions a call more for a `slice!(re, n)` whose value is used
(725,863,767 to 728,481,831 over 200,000 calls, callgrind): the head of the receiver is held in
a rooted temporary.

`slice!` with a Regexp and a group rebuilds the receiver from what is left of it, and wrote that
as one C expression, `sp_str_concat(sp_str_byteslice(..), sp_str_byteslice(..))`. Whichever
piece C built first was held by nothing while the other allocated, and a collection between the
two freed it: the receiver came back with other bytes in place of its head. A plain run shows
it:

```ruby
bad = 0
i = 0
while i < 4000
  n = 700 + (i * 37) % 900
  s = +("a" * n + "ll" + "b" * n)
  r = s.slice!(/(l)(l)/, 2)
  bad += 1 unless s.count("a") == n && s.count("b") == n
  i += 1
end
p bad
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-0
+2
```

With `SPINEL_GC_STRESS=1` it prints 1,191, and at level 2 it stops with "the mark reached a
freed heap string". The head now goes into a rooted temporary before the tail is cut, as the
index assignment by a group does beside it (the pull requests beneath).

**Not here.** The arms of `slice!` by position join a head and a tail in one expression too and
lose a piece in the same loop (`r = s.slice!(n, 1)` there prints 3); they are left as they are.
The statement form (`s.slice!(/(l)(l)/, 2)` with its value unused raises TypeError), a negative
group number and the tenth group and beyond (`s.slice!(/(e)(l)(l)/, -1)` is nil) are each a pull
request of their own above this one.

On master ea8c6aaa with the pull requests beneath: beside this pull request's test, the C of two
tests changes (`make cident`: 6,361 identical, 7 differ, four of them the tests that print the
compiler's revision). `string_slice_bang_frozen` prints the same at GC stress unset, 1 and 2;
`string_regexp_group_index`, which stopped on a freed String at 2, is right at all three.

The test's `.rb.expected` is the output of CRuby 3.3.6 with `--enable-frozen-string-literal`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (String#[]= with a Regexp group keeps its pieces rooted), # (String#[]= with a Regexp group raises for a missing group or nil)
