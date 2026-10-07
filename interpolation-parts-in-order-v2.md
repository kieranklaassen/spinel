<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class R                                  # reads tokens off a queue
  def initialize(t) = @t = t
  def nxt = @t.shift
  def item(tok) = tok == "(" ? "[" + item(nxt) + "]".tap { nxt } : tok
end
r = R.new(%w[( a ) b])
puts "#{r.item(r.nxt)} #{r.item(r.nxt)}"   # "[a] b" in Ruby, "[)] a" on master
```

The parts of an interpolation run out of order. In `"#{a.f(x1)} #{b.g(x2)}"` both arguments run first, then `f`, then `g`; CRuby runs x1, `f`, x2, `g`. So a later part's argument does not see what an earlier part's call did, and `"#{m}#{k.f(m += 1)}"` reads `m` after the assignment.

Now each part runs to its end before the next part's arguments start. `interp_plan` (`src/codegen_expr.c`) put what a part's call hoists into the statement's prelude, ahead of every part; it now stays in the part's place.

What was chosen: the move is made only where a list proves it right, and anywhere else the C is master's, byte for byte. Three things decide (`interp_may_move`).

- All the parts or none. A part's hoists still go ahead where that changes nothing (`interp_part_stays`: every earlier part is a literal or a read they cannot change); every other part's stay in place. One left ahead while another moves would run in neither order: `"#{m} #{k.f(m += 1)} #{k.f(m -= 1)}"` is right on master only because two early assignments cancel. So an interpolation around one that does not move does not move either.
- In a part's place a hoist runs after whatever is still in the prelude, and beside whatever stands in the same C expression. So the interpolation must be sequenced against its statement (`interp_sequenced`: a statement's value, an assigned or returned value, a condition, an argument beside plain reads, the last link of a `<<` chain) with nothing written after it there that hoists. Master's order stays beside a call, an element read, a String or a variable a part assigns (`pair("#{k.f(lg(1))} #{k.g(lg(2))}", lg(91))`, `"...".center(n + 12, "*")`), before a later link of a `<<` chain, another value of a `case`'s `when`s or a later part of an interpolation around this one, and beside a read of an instance, class or global variable where a default argument of the program's runs a call or an assignment.
- CRuby reads a String part when it joins the parts, so a later part that changes that String in place shows: `"#{s}#{k.two((s << "x").size, 1)}"` begins `sx`. Master gets that right because the operand runs first. So in a program that changes a String in place anywhere (a `<<`, a bang method or another String mutator on what may be a String), an interpolation with a part that may be a String before a part whose operands have an effect does not move.

An interpolated Symbol, `:"#{k.f(lg(1))}/#{k.g(lg(2))}"`, runs in order here and prints bytes that are not its name under `SPINEL_GC_STRESS=2`, as on master.

Not here: the order inside one part. `recv.note(arg)`, with `note` added to Float or String, runs `arg` before `recv`, as on master.

Cost: a receiver temp that moves is rooted by a pushed root in place of a frame slot, 2 instructions an evaluation (callgrind, 200,000 evaluations of `"#{k.name} #{k.two(id(i), 2).name} #{k.two(id(i), 3).name}"`: 108,470,746 on master, 108,870,747 here); with no receiver temp, none (83,026,366 on both). Compile cost, instructions of `spinel -c` under callgrind, master then here: 2,000 statements with an interpolation that moves, 4.52 and 4.55 thousand million; 4,000 of them in a program that reopens `Integer#to_s`, 9.44 and 9.50; one interpolation of 4,000 parts, 5.81 and 5.83.

Tests: `test/interpolation_parts_run_in_order.rb`, 22 lines, 9 of them wrong on master; it is in `GC_STRESS_TESTS`. `test/interpolation_appended_parts_run_in_order.rb`, the `<<` form in a program that changes Strings, 4 lines, 1 wrong on master. `test/interpolation_later_sibling_hoists.rb` pins places where nothing may move; it passes on master and its C is master's.

Generated C against master (`make cident REF=06064727f`): 6295 identical, 41 differ, 0 refusal changes. The 41 are the first two tests and 39 programs: one line of `packages/ffi/ffi.rb` compiled into 13 ffi tests, 8 fiddle tests and `test/ffi_gem_compat.rb`; `packages/fileutils/test/fileutils_test.rb` and 3 logger tests; and 13 tests under `test/`. Each of the 39 prints what it prints on master, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`: seven ffi and fiddle tests abort under stress 2 on both, and `test/gc_roots_beyond_array.rb`, changed only in the `raise` it reaches when it fails, runs past 60 s under stress on both. optcarrot's generated C is byte-identical.

Two sets of small programs written for this change, on 06064727f, with gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`. 1,920 with an interpolation in 40 places and something written after it: 1,120 have master's C; in the 800 that differ none loses a cell, and 292 are right in all six on master, 800 here. 2,880 with a first part that reads, a second whose operands have an effect and a third that may undo it: 1,474 have master's C; in the 1,406 that differ none loses a cell, and 1,190 are right in all six on master, 1,406 here.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
