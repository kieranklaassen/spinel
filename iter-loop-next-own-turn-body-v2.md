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

Under an `ensure` it ends the whole loop and goes to the ensure: `n = 0; begin; "a\nbb\nc".each_line { |l| next if l.size > 2; n += 1 }; ensure; puts n; end` prints `1` for `2`. With an `ensure` inside the block it runs the ensure and then the rest of the turn: `n = 0; [1, 2, 3].each_index { |i| begin; next if i == 1; n += 1; ensure; n += 10; end; n += 100 }` leaves `332` for `232`. With a value, inside the block of a `map`, it does not build: `[1, 2].map { |x| "ab".each_char { |c| next "q" if c == "a" }; x }`.

A String's `each_line`, `lines`, `each_char`, `chars`, `each_byte`, `bytes`, `each_codepoint`, `codepoints` and `each_grapheme_cluster` with a block, `Array#each_index` and `Array.new` with a block run the block inside a C loop of their own. Their emitters, `emit_iter_loop_stmts` and `Array.new`'s own walk of the body, did not record that loop, so a `next` there was emitted for whatever stood around the call: the frame base of an outer loop or of none, the ensure around the call, the proc body, the value slot of the block around it. Now they record the loop as `emit_loop_body` does for the other iterators: the frame depth and the ensure depth at its entry, the C loop depth, and no value slot (`Array.new` keeps its own, for the element).

Cost: none at run time: the change is in what the emitter writes for such a `next`, and a block without one emits the C it did. No corpus program's generated C changes but the new test's (cident on e527d205d274), and optcarrot's C is unchanged.

Not changed: `break`, `redo` and `return` in these blocks, and a `next` under a rescue modifier, were right and are. Of 1,440 programs (twenty such loops, fifteen places for one to stand, each left by `next`, `break`, `break` with a value, `redo` or `return`) the 160 that were wrong, all with `next`, are right, and the other 1,280 answer as they did. A `redo` in an `Array.new` block is refused as before. A `redo` inside a `begin` with an `ensure` does not run the ensure, in these loops and in `each` alike: `n = 0; ["a", "bb", "c"].each { |x| begin; if n == 11 && x.size > 1; n += 1; redo; end; n += 1; ensure; n += 10; end }; p n` prints `34` where CRuby prints `44`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
