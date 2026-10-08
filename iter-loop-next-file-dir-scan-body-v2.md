<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
File.open("lines.txt").each_line { |l| y ||= l; print y }
```

prints the file's first line once for every line it has (`spinel diff`: output-diff). CRuby prints the lines. The block's own local kept its value from one turn to the next. In the same loop a `next` under a `begin` pops the begin's rescue frame, so the `raise` after the loop is not rescued (exception-diff):

```ruby
n = 0
begin
  File.open("lines.txt").each_line { |l| next if l.size > 3; n += 1 }
  raise "late"
rescue => e
  puts e.message
end
```

Under an `ensure` the `next` ends the whole loop: with a, bbbb and c in the file, `n = 0; begin; File.open("lines.txt").each_line { |l| next if l.size > 3; n += 1 }; ensure; puts n; end` prints `1` for `2`. In a proc it returns from the proc: `pr = proc { n = 0; File.open("lines.txt").each_line { |l| next if l.size > 3; n += 1 }; n }; p pr.call` prints `nil` for `2`.

Each of these runs its block inside a C loop its emitter writes and did not record that loop, so a `next` there was emitted for whatever stood around the call: a File's `each_line`, `each`, `each_char`, `each_byte` and `each_codepoint`, `ARGF.each_line`, a Dir's `each`, `each_child` and `each_entry`; `product` with a block; `scan` with a block, read as a value or with groups in its Regexp; and, read as a value, `each.with_index` with a block and `each.with_index` followed by `each`.

The first commit is a refactor: `c_loop_enter` and `c_loop_leave` save, set and restore what a `next` or a `break` reads about its loop, and the six emitters that did so by hand call them. It changes no generated C (`tools/cident.sh`: every program of the corpus identical).

The second is the fix. The File, ARGF and Dir loops and the `scan` run the block through `emit_iter_loop_stmts`, as a String's `each_line` does; that call also makes the block's own locals new in every turn. `emit_iter_step_body` records the loop it runs in, for `product` and `each.with_index`, and `each.with_index` followed by `each` enters and leaves the loop around its walk of the body. The record is made for the blocks the String iterators record: one with a `next` of its own and no `next`, `break` or `redo` under a rescue modifier.

Cost: none at run time for a block with no local of its own and no `next`: it emits the C it did. A block with a local of its own sets it to nil at the head of each turn, as a String's loop does. Eight corpus programs' generated C changes beside the new tests' (`tools/cident.sh` against the first commit), each with a File or Dir loop or a `scan` whose block has locals of its own: benchmark/bm_io_wordcount.rb, test/io_each_block_param_typed.rb, test/loop_yield_root.rb and five tests of packages/shellwords, whose `shellsplit` walks its line with such a `scan`. All eight print what they did. Under callgrind bm_io_wordcount runs 236,811,287 instructions before and 236,691,455 after with gcc, 235,263,408 and 235,143,548 with clang; loop_yield_root 822,419,881 and 822,419,867 with gcc, 795,176,333 and 795,176,347 with clang; the other six whole runs, of 700,000 to 1,000,000 instructions, move by between 122 fewer and 14 more. optcarrot's C is unchanged.

Not changed: `break`, `break` with a value and `return` in these blocks answer as they did. Of 1,800 programs (these loops, fifteen places for one to stand, each left by `next`, `break`, `break` with a value, `redo` or `return`) 1,134 compile to the C they did. Of the other 666, the 204 that were right are right, and 177 with `next` that were wrong are right (105 raised or crashed, 72 printed a wrong answer).

The loops that take the block's value as their answer have the same `next` and are not in this change: `find` with a fallback proc, an Enumerator's `find`, `detect` and `take_while`, a boxed Array's `index` and `rindex`, `each.with_index` followed by `reduce`, `take_while.with_index`, and `slice_when`, `chunk` and `chunk_while` followed by `to_a`. They also drop the value a `next` carries, so recording the loop alone would turn the uncaught raise into a wrong answer.

A `redo` in the File, ARGF and Dir loops and in the `scan` was refused (`redo in this block (its iterator cannot re-run the body)`): the loop placed no label for it. `emit_iter_loop_stmts` places one, so a `redo` now builds and re-runs its turn, as in a String's loops: 227 of the probe's `redo` programs that were refused are right. 43 more were refused and now print a wrong answer that master prints already, each checked by script against its twin on master, line for line. In 34 the `redo` stands inside a `begin` with an `ensure`, and the ensure does not run, in `each` and in a String's loops alike (`n = 0; ["a", "bb", "c"].each { |x| begin; if n == 11 && x.size > 1; n += 1; redo; end; n += 1; ensure; n += 10; end }; p n` prints `34` where CRuby prints `44`); the twin is the same block in a String's loop, in `each` over the same names, or in the same `scan` as a statement (without the groups where the Regexp has them: beside groups that `scan` refuses a `redo`). In the other 9, and in 6 programs with `next` that ended in an uncaught raise before, one Dir is read by `each` twice and the second pass yields nothing (`d = Dir.new("."); a = 0; d.each { a += 1 }; b = 0; d.each { b += 1 }; p a == b` prints `false`); the twin is the same program without the `redo` or the `next`. The `redo`'s own emission and the Dir's reads are master's text.

A `redo` in a block with a `next`, a `break` or a `redo` under a rescue modifier stays refused in these loops. Its goto would leave the modifier's frame on the stack, as it does in a String's loop today: `r = 0; "ab".each_char { |c| (if c == "a" && r == 0; r = 1; redo; end) rescue print "r"; print "t" }` under a `begin` that prints `z` and raises after the loop prints `ttzrtz` before the message where CRuby prints `ttz`. So these loops place no label for such a block. Checked on 1,120 more programs (fourteen loops, five places, sixteen bodies: fifteen with a rescue modifier in the block and one with a plain `redo`): 745 compile to the C they did, 110 with a `redo` under a rescue modifier are refused as before, and of the other 265 the 44 that were right are right, 155 are right that were not (26 raised, 74 printed a wrong answer, the 55 with the plain `redo` were refused), and 66 are wrong before and after.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: # the pull request for a next under an ensure, or in a String iterator (its `emit_iter_loop_stmts` records the loop)
