<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`IO.select` with an error set now and then answers no handle for a pipe that has a byte to read, when an element's `to_io` allocates:

```ruby
class Wrap
  def initialize(io)
    @io = io
    @log = []
  end
  def to_io
    @log = [1, 2, 3, 4]
    @io
  end
end
r, w = IO.pipe
w.write "x"
w.flush
wrap = Wrap.new(r)
rd = [wrap]
er = [wrap]
bad = 0
i = 0
while i < 100000
  res = IO.select(rd, nil, er, 0)
  ok = !res.nil? && res.length == 3 && res[0].length == 1 && res[0][0].equal?(wrap) && res[1].empty? && res[2].empty?
  bad += 1 unless ok
  i += 1
end
p bad
```

```
spinel diff: output-diff
  program: select.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-0
+32
```

32 of the 100,000 calls answer `[[], [], []]`. With an error set `sp_io_select` waits in select(2) and then asks every element for its handle again to read the sets back; each of the three answer Arrays is held by a C local alone while `sp_select_io_of` runs the program's `to_io`. When that collects, the Array is freed and the ready handle is pushed into freed memory. The Array is now rooted while it is filled. The compiler is not touched; a call costs 51 instructions more. The poll path, taken with no error set, reads back by descriptor and calls nothing.

Not here: `IO.select([w], nil, nil, 0)` asks `w.to_io` once where CRuby asks twice, as on master.

Test: `test/io_select_to_io_allocates.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
