<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
g = { "a" => "x\ny\nz\n", "n" => 1 }
g["a"].each_line { |l| y ||= l; print y }
```

prints `x` three times (`spinel diff`: output-diff). CRuby prints `x`, `y`, `z`. The block's own local kept its value from one turn to the next. In the same loops a `next` under a `begin` pops the begin's rescue frame, so the `raise` after the loop is not rescued (exception-diff):

```ruby
g = { "a" => "a\nbb\nc", "n" => 1 }
begin
  g["a"].each_line { |l| next if l.size > 2 }
  raise "late"
rescue => e
  puts e.message
end
```

Under an `ensure` the `next` ends the whole loop: `n = 0; begin; g["a"].each_line { |l| next if l.size > 2; n += 1 }; ensure; puts n; end` prints `1` for `2`. In a proc it returns from the proc: `pr = proc { |h| n = 0; h["a"].each_line { |l| next if l.size > 2; n += 1 }; n }; p pr.call(g)` prints `nil` for `2`.

A String whose class is known only at run time has loops of its own for `each_line` with and without arguments, `each_char`, `each_grapheme_cluster`, `each_byte`, `each_codepoint` and `scan` with a block. Each walked the block's statements itself, where the typed String's loops call `emit_iter_loop_stmts`: nothing reset the block's locals and nothing recorded the loop for a `next`. Now they make that call. The stale local needs nothing more; the `next` is right once `emit_iter_loop_stmts` records its loop, which is the pull request this one depends on.

Cost: none at run time for a block with no local of its own and no `next`: it emits the C it did. A block with a local of its own sets it to nil at the head of each turn, as the typed String's loop does. One corpus program's generated C changes beside the new test's (`make cident` against the commit this stands on, on a785162aa79a: 6,414 of 6,416 programs identical): test/poly_each_line_boxed_block_param.rb sets its block's two locals to nil at the head of each turn and prints what it did. optcarrot's C is unchanged.

Not changed: `break`, `break` with a value and `return` in these blocks were right and are. Of 1,008 programs (fourteen such loops, fifteen places for one to stand, each left by `next`, `break`, `break` with a value, `redo` or `return`) the 104 with `next` that were wrong are right (65 raised or crashed, 39 printed a wrong answer), and the 638 that were right answer as they did.

A `redo` in these blocks was refused (`redo in this block (its iterator cannot re-run the body)`): the loop placed no label for it. `emit_iter_loop_stmts` places one, so a `redo` now builds and re-runs its turn, as in the typed String's loops: 182 of the probe's 210 `redo` programs are right. The other 28 print a wrong answer that master prints already. In 26 the `redo` stands inside a `begin` with an `ensure`, and the ensure does not run, in `each` and in the typed String's loops alike (`n = 0; ["a", "bb", "c"].each { |x| begin; if n == 11 && x.size > 1; n += 1; redo; end; n += 1; ensure; n += 10; end }; p n` prints `34` where CRuby prints `44`); each of the 26 prints, line for line, what master prints for the same block in the typed String's loop or in `each` over the same pieces. The other 2 are the `scan` below, and their `redo` is never reached.

`scan` with a block through such a receiver yields the whole match for a Regexp with groups, where CRuby yields the groups (`g["a"].scan(/(.)(.)/) { |x| p x }`); that is in what the loop reads, not in how it walks the block, and is as it was: 55 of the probe's programs, wrong before and after. One more is: `v = g["a"].scan("b") { |x| break 7 if x == "q" }` leaves nil in `v` when the `break` is not taken.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: # the pull request for a next in a String iterator, each_index or Array.new (its `emit_iter_loop_stmts` records the loop)
