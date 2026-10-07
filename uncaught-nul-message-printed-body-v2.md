<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Depends on "An exception message that begins with the counted form's marker keeps its bytes". The writer added here takes a message for a counted one by `sp_cmsg_p`; without that fix a message that only begins with the six marker bytes has its next four bytes read as a length, and the test's last line fails.

Before:

```ruby
raise TypeError, "left" + "\0right"
```

ends the program with these bytes on stderr:

```
ff fe 43 4d fd 01 0a 20 28 54 79 70 65 45 72 72 6f 72 29 0a
```

that is, the six bytes that mark a counted message and the low byte of its length (`0a`, the ten bytes of the message), then ` (TypeError)`. After, as CRuby after its `file:line:in` prefix:

```
6c 65 66 74 00 72 69 67 68 74 20 28 54 79 70 65 45 72 72 6f 72 29 0a
```

`left`, the NUL, `right (TypeError)`. Before "An exception message that holds a NUL keeps its bytes" the line was `left (TypeError)`.

A message with a NUL in it travels from the raise in a counted form: six marker bytes, the length, then the text. Making the exception object decodes it, so a rescue reads the message right. An exception that nothing rescues never becomes an object: its last line is written from the raise's own slot with `%s`, which printed the marker and stopped at the length's first zero byte. The line for an at_exit hook that raises and the report of a thread that dies of its exception are written the same way.

Both printers now go through one writer, which writes a counted message's text by its length.

Left alone: any other message is written by the `fprintf` it had, and that is every message with no NUL, one that begins with the marker bytes among them. The change is in lib/ only; no generated C changes (all 6,406 corpus programs identical).

The other readers of the raw slot were read one by one. The prefix tests in `sp_raise_cls` (a NameError's name), `sp_exc_resignal` ("SIGTERM") and the Fiber kill test compare from the first byte, and a counted message matches none of them, as it should. `sp_exc_cur_msg`, the saved exception context, Mutex#synchronize, and a Fiber's or a Thread's raise hand the message to another raise as it is; it is decoded where that one is rescued or printed.

Not here, each as before that merge: `raise TypeError.new("left\0right")`, an object and not a class with a message, ends with `left (TypeError)`, since the object's raise hands its message on as a bare C string; `warn e` and `abort` with such a message stop at the NUL. And one that is new with that merge: the `_try` helper of an extension hands its C host the counted form, marker first (it gave the text to the NUL).

The test sends stderr to a file under `Dir.tmpdir` and reads it back, so its `.expected` is CRuby's own output. It reads the lines of ten at_exit hooks that raise: one with no NUL, then plain, a leading and a trailing NUL, in a Fiber, under Mutex#synchronize, raised again, a built String, past an ensure and a rescue that does not match, and a message with no NUL that begins with the six marker bytes.

The thread's report has no test here. A thread that dies of an exception aborts now and then under `SPINEL_GC_STRESS=2` on master, with or without a NUL in its message (2 of 80 runs of a seven-line program whose thread raises a plain message: "the mark reached a freed heap string", in the exceptions' roots), so a test of the report cannot sit in the gate until that is fixed. Read by hand, the report of `Thread.new { raise ArgumentError, "in a\0thread" }` ends with `in a`, the NUL, `thread (ArgumentError)` (master: the marker and one byte).

Measured on master 4f8b737c1, above the fix this depends on. The test is right at -O0 to -O3, with clang, under both stress modes and in 100 plain runs (master: 8 of 12 lines wrong, and the fix this depends on alone the same 8). Of the 612 generated programs of the fix this depends on (17 messages, each rescued 21 ways and ending uncaught 15 ways), master is right for 336 and that fix for 484; with this 588 are right and none is lost. The 24 left: `Exception#exception(m)` cuts m at its first NUL (8), and an exception object that nothing rescues (16, the first point of "Not here"): its message is cut at the NUL as on master, or, where the message is a counted message byte for byte, printed by its payload (master: the marker and one byte). With `--debug` the line is the raising frame, then the whole message, then the `from` lines (master: the frame, then the marker). The 22 tests that pin stderr pass, and `make backtrace-test`. The scale-test ratios are master's (1.71, 4.74, 6.13, 4.17); `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: "An exception message that begins with the counted form's marker keeps its bytes"
