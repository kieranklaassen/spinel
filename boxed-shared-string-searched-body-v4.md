<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
h = { "k" => +"ab", "n" => 1 }
h["k"] << "c"
p %w[abc cd].include?(h["k"]), "ABC".casecmp?(h["k"])
```

prints `true` and `true` in CRuby and `false` and `nil` on master, with `--share-strings` too. Without the append both are right.

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-true
-true
+false
+nil
```

The append makes the Hash's String a shared handle, and its box then carries the handle. A String Array's `include?`, `member?`, `index`, `find_index`, `rindex` and `delete`, a String Range's `include?` and `cover?`, and `casecmp` and `casecmp?` each test the box's tag for a String, and a handle's is not one. They now read the argument through `sp_poly_strbuf_deref`, as `String#==` does. The string directives of `Array#pack` asked the same way; "Convert Array#pack String directive elements as CRuby does" already reads the handle there, so pack is not part of this.

Of 1,279 programs that hand such a String to 47 String-taking forms, 34 go from wrong to right, with and without `--share-strings`, and none that was right changes its answer. The wrap is two compares for a box that holds no handle: 2 instructions per `include?`, 9 per `casecmp?` (callgrind, 300,000 calls each). `tools/cident.sh`: 6405 identical, 9 differ (the new test and eight that pass before and after, each changed line master's with the `sp_poly_strbuf_deref(` wrap added); with `--share-strings` 6293 identical, 9 differ, 112 refused by both.

Left as on master: `(h["k"]..h["k"]).to_a` prints `[0]` for boxed ends, a handle or not.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (nothing)
