<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
count = proc { |s| n = 0; s.each_line { |l| next if l.strip.empty?; n += 1 }; n }
p count.call("a\n\nb\n")
```

prints `nil` (`spinel diff`: output-diff). CRuby prints `2`. The `next` returned from the proc. Under a `begin` the same `next` pops the begin's rescue frame, so the `raise` after the loop is not rescued (exception-diff):

```ruby
begin
  "a\nbb\nc".each_line { |l| next if l.size > 2 }
  raise "late"
rescue => e
  puts e.message
end
```

Under an `ensure` it ends the whole loop and goes to the ensure; with an `ensure` inside the block it runs the ensure and then the rest of the turn; with a value of another kind than the map's, inside the block of a `map`, it does not build.

A String's `each_line`, `lines`, `each_char`, `chars`, `each_byte`, `bytes`, `each_codepoint`, `codepoints` and `each_grapheme_cluster` with a block, `Array#each_index` and `Array.new` with a block run the block inside a C loop of their own, and their emitters (`emit_iter_loop_stmts`, and `Array.new`'s own walk of the body) did not record that loop, so a `next` there was emitted for whatever stood around the call. They now record the loop as `emit_loop_body` does for the other iterators, for a block that holds a `next` of its own (one in a `while`, `until` or `for` inside the block is that loop's) and no `next`, `break` or `redo` under a rescue modifier (below). `"ab".each_char.each { |c| next if c == "a" }` under a `begin` and a `scan` used as a value in `Array.new`'s block were wrong the same way and are right.

With the loop recorded, a `next` under an ensure in such a block takes the ensure's deferred continue. That continue pops the frames it leaves only with the pull request this one depends on.

Cost: none at run time on a program that was right. The C changes only for a block that is recorded; any other block emits the C it did: no corpus program's generated C changes but the new test's (`tools/cident.sh`), and optcarrot's C is unchanged.

Checked on generated programs, C first and then by run against CRuby, with the pull request this depends on: 21,216 programs; of 698 run, 483 that were wrong or raised are right, 184 were right and are, 31 are wrong as before (below). None that was right is wrong, and none that raised or did not build prints a wrong answer. With a jump under a rescue modifier in the block, 650 more programs (ten loops, thirteen bodies, five places) compile to the C they did, and so do 441 with the block's only `next` in a `while`, `until` or `for` inside it.

Not in this change:
- A `next` under a rescue modifier. The modifier's frame is not counted where the emitter counts frames, so a `next` written as a C `continue` leaves it on the stack: `["a", "b"].each { |c| next if c == "a" rescue print "r"; print "t" }` under a `begin` that prints `z` and raises after the loop prints `tzrtz` before the message where CRuby prints `tz`. The same block in `each_char` under that `begin` is right today: its `next` pops one frame, meant for the begin's, and the modifier's is the one on top. Recording that loop would make it print what `each` prints. So a block with a `next`, a `break` or a `redo` under a rescue modifier is not recorded and compiles to the C it did; the frame itself is another pull request's (A return, next or break out of a rescue modifier's expression pops its frame).
- `Array.new` with a block whose `next` has a value of another kind than the block's last expression does not build: `p Array.new(3) { |i| next "s" if i == 0; i }` (the C compiler refuses the element's assignment; CRuby prints `["s", 1, 2]`). Inside a proc or a lambda it built, since the `next` returned from the proc: `pr = proc { Array.new(3) { |i| next "s" if i == 0; i } }; p pr.call` printed `nil`. It now fails to build there as it does everywhere else.
- A `redo` inside a `begin` with an `ensure` does not run the ensure, in these loops and in `each` alike: `n = 0; ["a", "bb", "c"].each { |x| begin; if n == 11 && x.size > 1; n += 1; redo; end; n += 1; ensure; n += 10; end }; p n` prints `34` where CRuby prints `44`. `Array.new`'s block refuses a `redo` as before.
- `String#scan` with a block keeps its own walk where its Regexp has groups or its value is used: `"ab".scan(/(.)/) { |m| next if m[0] == "a" }` and `x = "a1b2".scan(/\d/) { |v| next if v == "1" }` under a `begin` still lose the begin's frame.
- The 31 above: a raise that passes an inner `begin`/`ensure` is not caught by the `rescue` of the `begin` around it (`begin; begin; raise "in"; ensure; print "e"; end; rescue; print "r"; ensure; print "n"; end` prints `en` and dies where CRuby prints `ern`), and a `break` in a rescue clause skips the ensure of its `begin`. Both are so in `each` without a `next`; the programs print what the same nest prints in `each` on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: # the pull request "A next under an ensure pops the rescue frames it leaves"
