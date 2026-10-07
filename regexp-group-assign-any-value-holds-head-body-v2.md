<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`s[/re/, n] = v` has a second arm, for a value that is not typed String (a method that returns
a String or an Integer, an element of an Array of several kinds). It built its answer in one
nested call, `sp_str_concat(sp_str_concat(head, value), tail)`: the joined head and value were
held by nothing while the tail allocated, and a collection there freed them. A plain run shows
it:

```ruby
def pick(i) = i == 0 ? "XY" : 5

bad = 0
4000.times do |i|
  n = 700 + (i * 37) % 900
  s = +("a" * n + "ll" + "b" * n)
  s[/(l)(l)/, 2] = pick(0)
  bad += 1 unless s.count("a") == n && s[n + 1, 2] == "XY"
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
+4
```

With `SPINEL_GC_STRESS=1` it prints 3,861, and at level 2 the statement stops with "the mark
reached a freed heap string". The arm for a String value had the same shape and was fixed the
same way in the pull request beneath: the head goes into a rooted temporary, the value into one
that is rooted unless it is a plain read, and `sp_str_concat3` joins them with the tail. The
tests of the arm, their order and their messages are untouched.

The String that joined the head and the value alone is no longer built, one allocation fewer a
statement: 140 instructions fewer with the value in a local (749,581,480 to 721,489,733 over
200,000 statements, callgrind), 125 fewer with the value read from a call.

**Not here.** After a value that runs code, a group that took no part in the match is still
stored into (`s[/(e)(x)?(l)/, 2] = [1, "Q"].last` makes "Qo"); a negative group number and the
tenth group and beyond still raise (`s[/(e)(l)(l)/, -1] = "X"` is an IndexError). Each is a pull
request of its own above this one.

On master ea8c6aaa with the pull requests beneath: beside this pull request's test, the C of two
tests changes (`make cident`: 6,362 identical, 7 differ, four of them the tests that print the
compiler's revision): `string_regexp_group_assign_raises` and
`string_regexp_group_assign_rooted`, which use the arm and print the same at GC stress unset, 1
and 2.

The test's `.rb.expected` is the output of CRuby 3.3.6 with `--enable-frozen-string-literal`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (String#[]= with a Regexp group keeps its pieces rooted), # (String#[]= with a Regexp group raises for a missing group or nil), # (slice!(re, n) holds the head of the receiver while it cuts the tail)
