<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A method that matches saves its caller's `$~` on the way in and puts it back on the way out.
The saved Strings were held by that frame alone, unrooted, so a collection while the method ran
freed them and the caller read another String's bytes, on a plain run:

```ruby
def hit?(s)
  r = (s =~ /rr/) ? 1 : 0
  GC.start
  a = []
  4.times { |i| a << "Z" + i.to_s }
  r + a.size
end
("k" + 99.to_s) =~ /k(\d+)/
p hit?("cherry"), $1, $~[0]
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,3 @@
 5
-"99"
-"k99"
+"1"
+"Z1"
```

`sp_re_frame_push` now roots the saved Strings, as one root frame, and `sp_re_frame_pop` drops
it. No program's generated C changes (`make cident`). A call of a matching method pays 50
instructions more (callgrind, 200,000 calls, on master 8684d54c).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
