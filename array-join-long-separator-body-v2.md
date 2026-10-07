<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p ["a", "b"].join("x" * 1000).count("x")   # 511, CRuby: 1000
p [1, 2, 3].join("-" * 1000).count("-")    # 1511, CRuby: 2000
```

A join with a long separator writes past its buffer. With `SPINEL_GC_SLAB=0` valgrind names the write, "Invalid write of size 8 ... 0 bytes after a block of size 512 alloc'd", and glibc aborts with "realloc(): invalid next size". With the slab allocator the bytes land in the slots behind the buffer and the run can go on: here the result has the right length and NULs where the rest of the separator was.

The String, Integer and Float Array joins build the result in a buffer of 256 bytes. For an element they grow it until the element fits; for a separator they doubled it once, whatever the separator's length, so one that did not fit the doubled buffer (512 bytes at first) was copied past its end. The three joins now double the buffer until the separator fits.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-1000
-2000
+511
+1511
```

A join that fits costs the same within three instructions a call (callgrind, 200,000 joins): three Strings with ", " 128.3M to 127.7M, four Integers 530.3M on both, three Strings with a 300-byte separator 261.9M to 262.1M. No generated C changes. Test: `test/array_join_long_separator.rb`.

This stands on "Array#join picks its encoding before it allocates the result", which rewrote the String Array join's loop.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # ("Array#join picks its encoding before it allocates the result")
