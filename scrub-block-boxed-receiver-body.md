<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
a = ["ab\xFEcd", 1]
n = 0
p a[0].scrub { |b| n += 1; "?" }, n   # "ab�cd" and 0, CRuby: "ab?cd" and 1
```

`scrub` with a block dropped the block when its receiver is boxed (a String read out of an Array or a Hash of mixed values, a method's boxed value, a boxed parameter): the two boxed arms never looked at it, so each invalid sequence became U+FFFD, what the block does never happened, and a replacement given beside the block did not raise. With a literal block both arms now run the String arm's loop over the unboxed String. A block that holds a break or a return, or whose first parameter is not a plain name, keeps the arm it had.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-"ab?cd"
-1
+"ab�cd"
+0
```

Test: `test/scrub_block_boxed_receiver.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
