<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
buf = +""
bad = 0
400.times do |i|
  buf.replace("x" * 300_000 + i.to_s)
  bad += 1 unless buf.start_with?("xxxx")
end
p bad                        # 5, CRuby: 0
```

A plain run, gcc and clang. `replace` written as a statement on a local, an instance variable, a global or a parameter copies the argument's bytes into a new String. The argument was read into a C temporary that nothing held, and the copy allocates before it reads: a collection at that allocation freed the argument, and the receiver took whatever the freed bytes then held. `s.replace(s.upcase)`, `s.replace(n.to_s)` and `s.replace("#{a}#{b}")` are all this; under `SPINEL_GC_STRESS=2` each leaves the receiver holding the freed pattern:

```ruby
s = +"abc"
s.replace(s.upcase)
p s                          # "\xDB\xDB\xDB", CRuby: "ABC"
```

The temporary is now rooted where the argument may allocate. An argument that is a literal or a variable keeps the C it had.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-0
+5
```

Callgrind, 200,000 calls of `q.replace(i.to_s)`: 10 instructions a call more with gcc, 22 with clang. `q.replace(y)` with `y` a local: the same C, no change.

Test: `test/string_replace_fresh_source_held.rb`, also in `GC_STRESS_TESTS`. On master it fails in a plain run (the long loop at its end), dies of a segmentation fault at `SPINEL_GC_STRESS=1`, and prints 13 wrong lines of 16 at 2.

Not here: `String#-@` and a Symbol made from a String copy through the same helper; each is its own change.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
