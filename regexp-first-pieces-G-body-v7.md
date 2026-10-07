<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A method that matches saves its caller's `$~` on the way in and puts it back on the way out.
The saved Strings were held by that frame alone, unrooted, so a collection while the method ran
freed them and the caller read another String's bytes:

```ruby
def hit?(s) = (s =~ /rr/) ? 1 : 0
"k9" =~ /k(\d)/
n = 0
i = 0
words = ["apple", "berry", "cherry", "avocado"]
while i < 200_000
  n += hit?(words[i & 3])
  i += 1
end
p n, $1
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
 100000
-"9"
+"rr"
```

`sp_re_frame_push` now roots each saved String that is set and `sp_re_frame_pop` drops those
roots. A call of a matching method pays 139 instructions more where its caller has a match set
and 110 where it has none; the call and its match cost 1,223 before (callgrind, 200,000 calls,
master 5390d300). No program's generated C changes (`make cident`), and the method's C frame
stays the size it was: the recursion that runs 575 deep in a Fiber and 149,789 deep on the
main stack still does.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
