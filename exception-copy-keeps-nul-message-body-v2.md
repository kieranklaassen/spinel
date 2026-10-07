<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
e = RuntimeError.new("first")
p e.exception("AAAAAAAAAA\0tail").message.bytesize
p e.exception("\0abc").message.bytesize
```

prints `10` and `12`. After, as CRuby: `15` and `4`.

Stated cost: an `exception(m)` whose m is not a literal pays the scan of m for a NUL that a raise pays for its message. A built String of 46 bytes costs 71 instructions more a call and one of 1,000 bytes 182. The figures are under "Cost" below. A literal with no NUL is the call it was, at its cost.

The copy's message stopped at the NUL. With the NUL first nothing was left of it, and a copy with no message answers its class name: `RuntimeError`, 12 bytes.

A raise hands its message through `sp_exc_msg_given`, which sends a String that holds a NUL in the counted form (six marker bytes, the length, the payload), so its length survives the `const char *` the exception path carries. `Exception#exception(m)` handed m as it was, and `sp_exc_exception` read it as a C string. A literal with no NUL is that C string, and its call stays as it was. Any other String now goes to `sp_exc_exception_given`. A message that holds a NUL it gives as a raise does; any other it passes on as it came. Then it calls `sp_exc_exception`, which reads a counted message already and is not touched. `sp_raise_poly_msg`, which gives its message itself when the receiver of `raise e, m` is known only at run time, calls it as before. The counted message is built in the runtime and not in the generated C, where it would stand unrooted while the receiver is evaluated (the test's `twice` line under `SPINEL_GC_STRESS=2`).

Left alone: a message with no NUL reaches `sp_exc_exception` as it did, a literal by the same C. Of 6,447 corpus programs the C of 6,446 is identical; the one that changes is the new test.

Cost, in instructions for a loop of a million `e.exception(m).message.bytesize` (callgrind, -O2), master then this: m a literal of 13 bytes, 524 a turn on both; a built String of 46 bytes, 552 to 623; one of 1,000 bytes, 1,136 to 1,318. The rise is the new entry (32 instructions) and its `memchr`; no other function's count moves.

Not here, each the same on master:

- An empty message: `e.exception("")` and `raise e, ""` have the class name for a message (CRuby: an empty one). It reaches `sp_exc_exception` as before.
- A message that begins with the counted form's six marker bytes and holds no NUL is read as a counted message, here as at a raise: "An exception message that begins with the counted form's marker keeps its bytes" cures both. One that does hold a NUL is right with this change alone.
- The copy raised and not rescued: its last line stops at the NUL. "An uncaught exception whose message holds a NUL prints the message" writes it whole: with both, the 78 such programs of the attack set are right (run on master 9274c732e).
- A copy that was raised and rescued, compared by `==` with an exception that never was, answers true; CRuby answers false, for the backtrace. Backtraces are empty by design (docs/limitations.md), so `==` compares the class and the message. On master `raise e.exception("a\0b")` rescued and compared with `RuntimeError.new("a\0b")` was false only because the message was cut; with `raise RuntimeError, "a\0b"` in its place master answers true as well.

The test makes copies with a literal message, a built one, a NUL first, last and twice, and a plain one; of an instance of a class of the program, whose field and whose receiver's message it reads; with a message taken from an Array of mixed values; raises a copy and rescues it; copies a copy; and sums the lengths of 300 more.

Measured on master 8dc552254. The test is right at -O0 to -O3, with clang and under both stress modes; master prints 11 of its 15 lines wrong at every level. Of 1,525 attack programs (15 messages: a NUL in the middle, first, last, alone and twice, in a built String, an interpolated one, a binary one, a long one and one of two-byte characters, after the six marker bytes, in a whole counted message, and three with no NUL; copied from six receivers: a local, a fresh object, an instance of a class of the program, a rescued exception, one with no message, one held in an instance variable; read fourteen ways; the message a String, a value from a mixed Array, or one that may be nil) master is right on 211 and this on 1,286; none is lost. Of the 239 left, 139 have the empty message and 78 leave the copy uncaught, the first and third items above; 22 raise a copy of the program's class and compare what the rescue got with `equal?`, which is false on master with a plain message too. 199 of them print master's bytes; the other 40 have a NUL message that is right now, beside the fault that stays. `make backtrace-test` passes. The scale-test ratios are master's (1.71, 4.74, 6.13, 4.17); `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
