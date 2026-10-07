<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
$n = 0
nil.tap { $n += 10 }&.size
p $n
```

| | prints |
|---|---|
| master before "v&.upto(n) { } in statement or tail position skips a nil receiver" | `10` |
| master now | `20` |
| CRuby | `10` |

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-10
+20
```

The block of the receiver runs twice. For a `&.` call whose nil guard is pending, `emit_iteration_stmt_sn` emits the receiver and then asks the loop emitters for the call. When they decline, because the call is no loop (`&.size`, `&.then { }`), its own text is dropped, but the statements the receiver hoisted are already written, and the plain emission that follows emits the receiver again. So a receiver whose block is inlined ahead of the statement (`tap`, `then`, `each`, `map`) ran twice.

On a decline the hoisted statements are now taken back as well, so nothing is written, as the function's comment says. A call the loop emitters take (`v&.upto(3) { }`, `v&.each { }`) is emitted as it was, and `test/safe_nav_iter_stmt.rb` is unchanged.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
