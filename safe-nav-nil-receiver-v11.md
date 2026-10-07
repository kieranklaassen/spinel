<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
$log = []
def lg(x) = ($log << x; x)
def name(v) = v ? "ab" : nil
s = name(false)
r = s&.rjust(lg(5), lg("b"))
p r, $log
```

- Master: `nil`, then `[5, "b"]`.
- CRuby: `nil`, then `[]`.

A call to a builtin method has its operands ordered ahead of it, in a statement expression, wherever one of them has an effect (`emit_operands_in_order`). For a `&.` call that was ahead of the nil guard too: the arguments ran, or raised, on the very nil the guard stops. A method of the program's own was right; a String, Array or Hash method was not. It is not left by this week's guard changes: 06064727f prints the same.

The guard already re-enters the call's emission under its nil test, with the receiver in its temp. So the ordering now waits for that re-entry (`sn_guard_ahead`) where a guard will run, a boxed receiver and the typed ones the guard tests, and where the call's value can stay in its place (`sn_stays_in_place`, from the two changes this depends on). There the ordered operands land where the call is written, after what the statement has before it. Elsewhere the C is master's.

Two commits. The first moves the test the typed arm makes before it guards into `sn_typed_nil_recv` and changes no generated C (`make cident` against the change this depends on: 6393 identical, 0 differ). The second is the fix: 21 lines, 4 of them in `emit_operands_in_order`.

Not here:

- A call with more after it in its statement than literals and reads of numbers, Symbols, `true`, `false` or `nil`: `p s&.rjust(lg(5), lg("b")), $log`, `[lg(0), s&.rjust(lg(5), lg("b")), lg(9)]` and `(s&.rjust(lg(3), lg("x")) || "")` still run the arguments for a nil `s`, as on master. Left in place there, the call could run after what is written after it.
- A String receiver that its own argument appends to: `s&.center(grow(s), "*")` for a `grow` that does `s << "x"` centers the String from before the append, on master and here. With a `.` it is right.
- A method the program adds to String (`class String; def pair(a)`) still runs on a nil, arguments and all.

Test: `test/safe_nav_nil_receiver_runs_no_operand.rb`, 46 lines; 14 of them are wrong on master.

Generated C against the first commit (`make cident`, the stack on 3cb8982d8): 6393 identical, 1 differ, 0 refusal changes. The one is the new test. optcarrot's generated C is byte-identical.

Four sets of small programs, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`, on 3cb8982d8 with the two changes this depends on. 462 with a `&.` call on a typed receiver (each kind of argument, in each place a statement puts it, the receiver nil and not): 430 have those changes' C; of the 32 that differ, 16 are right in all six there and 30 here. 462 with the same calls on a boxed receiver: 32 differ, 16 and 30. 291 from the nil receiver work: 232 and 244. 1,280 with the guarded call first and a later operand of each kind: 1,050 have master's C; of the 230 that do not, 228 and the same 228, and no program's result differs. No program loses a cell in any of the four. The two of the 32 left in each 462 print what they print on master: `"#{o.size} #{o&.push([n].size, lg(1))&.size}"` and its multiple assignment, where the receiver of the second `&.` runs ahead of the statement.

12 of the 291 raise there and print a wrong line here. Each runs the second "Not here" line three times, for a String, a nil and a String. There the first prints the wrong line and the second raises, in the argument, on the nil. Here the second prints `nil`, as CRuby does, and the third prints what the first prints.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (the pull requests of "A `&.` call whose value hoists builds, and runs in its place" and "A `&.` call on a boxed receiver runs in its place")
