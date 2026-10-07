<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Two commits for two faults of `next`. The second needs the first.

```ruby
begin
  ["a", "b"].each { |c|
    begin
      begin
        next if c == "a"
      ensure
        print "e"
      end
    rescue
      print "r"
    end
  }
  raise "late"
rescue => ex
  puts ex.message
end
```

prints `eerlate` (`spinel diff`: output-diff). CRuby prints `eelate`. A `next` under an `ensure` ran the ensure and then the loop's C `continue`, and the frame of the `begin`/`rescue` around the ensure stayed on the exception stack. The raise after the loop landed in it: the rescue clause of a turn that was over ran. One frame stays for every such `next`, so a loop of two hundred turns ends in SystemStackError with no raise in it. The deferred `break` beside it already pops the frames it leaves, down to the enclosing ensure's or down to the loop's; the first commit makes the deferred `next` pop the same counts, where the loop's body owns the `begin`.

```ruby
count = proc { |s| n = 0; s.each_line { |l| next if l.strip.empty?; n += 1 }; n }
p count.call("a\n\nb\n")
```

prints `nil` (output-diff). CRuby prints `2`. The `next` returned from the proc. Under a `begin` the same `next` pops the begin's rescue frame, so the `raise` after the loop is not rescued (exception-diff):

```ruby
begin
  "a\nbb\nc".each_line { |l| next if l.size > 2 }
  raise "late"
rescue => e
  puts e.message
end
```

Under an `ensure` it ends the whole loop and goes to the ensure; with an `ensure` inside the block it runs the ensure and then the rest of the turn; with a value, inside the block of a `map`, it does not build. A String's `each_line`, `lines`, `each_char`, `chars`, `each_byte`, `bytes`, `each_codepoint`, `codepoints` and `each_grapheme_cluster` with a block, `Array#each_index` and `Array.new` with a block run the block inside a C loop of their own, and their emitters (`emit_iter_loop_stmts`, and `Array.new`'s own walk of the body) did not record that loop, so a `next` there was emitted for whatever stood around the call. The second commit records the loop as `emit_loop_body` does for the other iterators, for a block that holds a `next` of its own. With the loop recorded, a `next` under an ensure in such a block takes the ensure's deferred continue, which is why the first commit comes first. `"ab".each_char.each { |c| next if c == "a" }` under a `begin` and a `scan` used as a value in `Array.new`'s block were wrong the same way and are right.

Cost: none at run time on a program that was right. The first commit changes the C only after an ensure that holds a `next` of the loop its `begin` stands in: the `continue` there is now `sp_exc_top -= N; continue;`. The second changes the C only for a block with a `next` of its own. Any other `begin` and any other block emit the C they did: no corpus program's generated C changes but the two new tests' (`tools/cident.sh`), and optcarrot's C is unchanged.

Checked on generated programs, C first and then by run against CRuby. First commit alone: 19,992 programs (17 loops, 14 nests of begin, rescue and ensure, 7 ways out, with and without a raise after the loop, in 6 places); the C changes in 2,520; of 1,195 of those run, 816 that were wrong or ended in SystemStackError are right, 151 were right and are, and 228 are wrong as before, each with a `redo` inside a `begin` (below). Both commits: 21,216 programs; of 698 run, 483 that were wrong, raised or did not build are right, 184 were right and are, 31 are wrong as before. In both sets none that was right is wrong, and none that raised or did not build prints a wrong answer.

Not in this change:
- The block of `each_with_index`, `map` or `select` goes through another emitter and leaves the frame as before: the first program with `each_with_index` for `each` still prints `eerlate`.
- A `redo` inside a `begin` with an `ensure` does not run the ensure, in these loops and in `each` alike: `n = 0; ["a", "bb", "c"].each { |x| begin; if n == 11 && x.size > 1; n += 1; redo; end; n += 1; ensure; n += 10; end }; p n` prints `34` where CRuby prints `44`. `Array.new`'s block refuses a `redo` as before.
- `String#scan` with a block and groups keeps its own walk: `"ab".scan(/(.)/) { |m| next if m[0] == "a" }` under a `begin` still loses the begin's frame.
- The 31 above: a raise that passes an inner `begin`/`ensure` is not caught by the `rescue` of the `begin` around it (`begin; begin; raise "in"; ensure; print "e"; end; rescue; print "r"; ensure; print "n"; end` prints `en` and dies where CRuby prints `ern`), and a `break` in a rescue clause skips the ensure of its `begin`. Both are so in `each` without a `next`; the programs print what the same nest prints in `each` on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
