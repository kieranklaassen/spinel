<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class Bus
  def initialize = @v = [+"leaf", +"two"]
  def cell(i) = @v[i]
  def m4(i) = cell(i)
  def m3(i) = m4(i)
  def m2(i) = m3(i)
  def m1(i) = m2(i)
  def peek(i)
    return m4(i) if i > 5
    m1(i)
  end
end
bus = Bus.new
bus.peek(0) << "!"
p bus.peek(0)
```

- before "An append through a delegating reader follows each method once" was merged (c4f8bfc7e): `"leaf!"`
- master (669ffd906): `"leaf"`
- CRuby, and this: `"leaf!"`

```
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"leaf!"
+"leaf"
```

The append goes to a copy. A bus loses it the same way when four or more pass-through classes (`def peek(i) = @nxt.peek(i)`) are declared ahead of the class that holds the String and reads it through a helper; the test has both. Under `--share-strings` both are right.

That change walks each method once per demand, and the walk is bounded at five methods deep. `peek` ends in `m1(i)`, so `m4` is first met at depth 4, where its own result `cell(i)` is past the bound and is cut; the short route `return m4(i)` then finds `m4` walked and skips it, and `@v[i]` is never demanded. A method's results are the same however it was reached, as the comment says; what is left of the bound is not.

The table now keeps the depth each method was walked at, and a method is skipped only when that walk was no deeper than this one, as `hash_literal_sources` does for its nodes. A method is walked at most once per depth, so the fan-out stays ended: the analysis of `test/append_through_delegating_reader.rb` (32 classes) takes 0.04 s on master and with this, against 13 s before that merge, and the same bus at 256 classes 0.5 s on both.

Of 196 programs around a delegating reader, six print a wrong answer on master that was right before the merge. With this all 196 print what they printed before it, and with `--share-strings` none changes.

## `make gate` (on this branch merged with current master)

```
not run in full here (it runs on the Mac before anything goes upstream). In the cloud, on this commit alone on master 669ffd906: make share-strings-test passes; tools/gate.rb check passes (no Ruby 4.0 here, so .expected was not compared).
cident: 6362 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against 669ffd906): the one is this test.
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; it prints six Strings)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
