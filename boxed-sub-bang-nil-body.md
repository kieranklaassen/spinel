<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
a = [+"ab=", 1]
p a[0].sub!("=") { "=" }     # nil, CRuby: "ab="
p a[0].gsub!(/b/, "b")       # nil, CRuby: "ab="
```

`sub!` and `gsub!` answer nil when no substitution was made. For a boxed receiver (a String read out of a mixed Array or Hash, a method's boxed value) the answer came from comparing the text before and after, so a substitution that wrote the bytes it found answered nil. A String receiver reads the runtime's matched flag for this, and the boxed arm now reads it too.

The flag is one value the whole program shares. The arm marks it 2 where it was already set, so that a 1 after the call is the call's own, and puts the old value back when the call made no substitution: every other reader of the flag finds it as it would have. Only a call whose arguments are literals or plain reads takes this; an argument that runs code may run a `sub` of its own, and such a call keeps the comparison.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-"ab="
-"ab="
+nil
+nil
```

A String receiver's call compiles to the C it did. A boxed `sub!` or `gsub!` takes 11 to 17 more instructions a call (callgrind). Test: `test/boxed_sub_bang_same_bytes.rb`.

Not here: a boxed call with an argument that runs code, or with a Hash of replacements, still answers nil for a substitution that wrote the same bytes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
