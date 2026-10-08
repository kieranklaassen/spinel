<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Depends on "An exception message that begins with the counted marker keeps its bytes". The writer added here takes a message for a counted one by `sp_cmsg_p`; without that fix a message that only begins with the six marker bytes has its next four bytes read as a length, and the two tests' lines for such messages fail.

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

`left`, the NUL, `right (TypeError)`. Before "An exception message that holds a NUL keeps its bytes" the line was `left (TypeError)`, and for an exception object, `raise TypeError.new("left" + "\0right")`, it still is; after this it is the whole line too.

A message with a NUL in it travels from the raise in a counted form: six marker bytes, the length, then the text. Making the exception object decodes it, so a rescue reads the message right. An exception that nothing rescues never becomes an object: its last line is written from the raise's own slot with `%s`, which printed the marker and stopped at the length's first zero byte. The raise of an exception object puts the object's own message in that slot as a C string, so there the line stopped at the NUL. The line for an at_exit hook that raises and the report of a thread that dies of its exception are written the same way.

These lines now go through one writer (`sp_exc_write_uncaught`), which writes a counted message's text by its length. The three places that write one, the end of the program (`sp_raise_cls` with no frame left), an at_exit hook that raised and the thread's report, hand it the object's own message, counted, when an object was raised and its message holds a NUL, or is a counted message byte for byte, which the slot's readers would take for its payload (`sp_exc_uncaught_msg`, in lib/sp_exc.c beside the function that builds a counted message). At the end of the program it is taken before the hooks run, as the exit status is: the hooks may allocate.

Left alone: a message the slot does not hold counted is written by the `fprintf` it had, and that is every message with no NUL, raised by class or as an object, but one that is a counted message byte for byte; one that only begins with the marker bytes is among those left alone. A raise that is rescued is not touched. Measured against the pull request beneath (callgrind, gcc -O2, 1,000,000 raises each, eight programs): seven are within 12,000 instructions in one to four thousand million, and a class raised alone runs 5 instructions a raise fewer (1,801,307,774 to 1,796,306,646); the one line added to `sp_raise_cls` is on its branch with no frame left. The change is in lib/ only; no generated C changes.

The other readers of the raw slot were read one by one. The prefix tests in `sp_raise_cls` (a NameError's name), `sp_exc_resignal` ("SIGTERM") and the Fiber kill test compare from the first byte, and a counted message matches none of them, as it should. `sp_exc_cur_msg`, the saved exception context, Mutex#synchronize, and a Fiber's or a Thread's raise hand the message to another raise as it is; it is decoded where that one is rescued or printed.

Not here, each the same on master: `warn e` and `abort` with such a message stop at the NUL. And one that came with that merge: the `_try` helper of an extension hands its C host the counted form, marker first (it gave the text to the NUL); "The extension try helper hands the host a message with a NUL as text" takes it.

The two tests send stderr to a file under `Dir.tmpdir` and read it back, so their `.expected` is CRuby's own output. The first reads the lines of twelve at_exit hooks that raise a class and a message: one with no NUL, then plain, a leading and a trailing NUL, in a Fiber, under Mutex#synchronize, raised again, a built String, past an ensure and a rescue that does not match, a message with no NUL that begins with the six marker bytes, one that is a counted message byte for byte, and the same of 16,843,019 bytes with no NUL in it (16,843,030 bytes on stderr with its class; master prints that one right). The second reads the lines of twelve hooks that raise an object: one with no NUL, then `TypeError.new` with a NUL, an object made earlier, a class of the program whose initialize calls super, an exception rescued and raised again as an object, in a Fiber, a leading and a trailing NUL, and the same marker-led and byte-for-byte messages, one of those with a NUL in its text, and the 16,843,019 bytes (master prints it ten bytes short).

The thread's report has no test. On master a thread that dies of a plain exception, no NUL in it, aborts under `SPINEL_GC_STRESS=2` in 27 of 80 runs here ("the mark reached a freed heap string", in the phase `globals:exceptions`), and a test of the report would abort for that cause. Run by hand, `Thread.new { raise TypeError, "left" + "\0right" }` reports the six marker bytes, a newline and ` (TypeError)` on master, and `left (TypeError)` with `TypeError.new`; here both report `left`, the NUL, `right (TypeError)`.

Measured on master 9922a2c74 with the pull request beneath. Both tests are right at -O0 to -O3, with clang and under both stress modes; master has 9 of the first test's 14 lines wrong and 13 of the second's 15, in each of its five builds. `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit above the pull request beneath on master 9922a2c74: the build, the two tests in the seven builds, `ruby tools/gate.rb check` with the change staged, `make int-min-test`, the eight cost programs under callgrind, and the two thread programs by hand. The compiler is not touched, so no corpus program was compiled again; optcarrot was, and its C is master's by hash.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: the pull request "An exception message that begins with the counted marker keeps its bytes"
