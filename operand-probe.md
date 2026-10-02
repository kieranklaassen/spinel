<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Adds `tools/operand_probe.rb`, a hand-run probe like `call_binding_probe` and `order_probe`, and its section in `tools/README.md`. Nothing under `src/` or `lib/` changes.

Ruby runs a call's receiver, then its arguments left to right, each once, and then the call. Spinel hands the operands of most calls to one C call, whose order C leaves open, and binds them in order first where it sees that the order shows (`emit_operands_in_order`, and the arms that do it by hand). An arm that does neither answers wrong only for a program whose operands have effects, and few programs of the suite have two in one call, so the suite does not say which arms are left. They have been found one at a time, by hand.

The probe gives every operand an effect: it writes each test again with every operand `e` of every call spelled `__opN(e)`, `def __opN(v)` a method that logs N to stderr and answers v, runs that program under ruby and under spinel, and reads the two logs call by call. A call is a finding when one of its operands ran another number of times than the others (`count`), when an operand was logged with the one before it still to run (`order`), or when an operand of a call written inside one of its operands was logged before the operand ahead of that one (`nested`). A builtin that calls its block in another sequence than ruby's is no finding.

On 2e243ba7 with gcc 13.3, a run over `test/*.rb` asks 22,505 calls in 2,968 programs and finds 1,712 in 670 (1,259 order, 281 nested, 172 count), in 212 families of class and method. The largest is `recv << arg` (674 calls in 308 programs), then `push`, `[]=` and `first`. 351 of the 356 calls asked again with only that call wrapped are still findings. Three of them with no wrapping at all:

```ruby
out << nxt.call << nxt.call          # nxt hands out "a" then "b": out is ["b", "a"]
tm == t(5)                           # tm a call answering a Time: it never runs
f(s.byteslice(a, b)) + g(s.byteslice(c, d))   # c and d run before f
```

The run was made with ruby 3.3.6, which does not print the `.expected` of 778 programs, so those were left out; under 4.0 more are asked. What the probe does not see is in the README section.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
