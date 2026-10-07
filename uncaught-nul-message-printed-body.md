<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
raise TypeError, "left" + "\0right"
```

ends the program with these bytes on stderr:

```
ff fe 43 4d fd 01 0a 20 28 54 79 70 65 45 72 72 6f 72 29 0a
```

that is, seven bytes that are not the message, then ` (TypeError)`. After, as CRuby after its `file:line:in` prefix:

```
6c 65 66 74 00 72 69 67 68 74 20 28 54 79 70 65 45 72 72 6f 72 29 0a
```

`left`, the NUL, `right (TypeError)`. Before "An exception message that holds a NUL keeps its bytes" the line was `left (TypeError)`.

A message with a NUL in it travels from the raise in a counted form: six marker bytes, the length, then the text. Making the exception object decodes it, so a rescue reads the message right. An exception that nothing rescues never becomes an object: its last line is written from the raise's own slot with `%s`, which printed the marker and stopped at the length's first zero byte. The line for an at_exit hook that raises and the report of a thread that dies of its exception are written the same way.

Both printers now go through one writer, which writes a counted message's text by its length.

Left alone: any other message is written by the `fprintf` it had. The change is in lib/ only; no generated C changes.

The other readers of the raw slot were read one by one. The prefix tests in `sp_raise_cls` (a NameError's name), `sp_exc_resignal` ("SIGTERM") and the Fiber kill test compare from the first byte, and a counted message matches none of them, as it should. `sp_exc_cur_msg`, the saved exception context, Mutex#synchronize, and a Fiber's or a Thread's raise hand the message to another raise as it is; it is decoded where that one is rescued or printed.

Not here, each as before that merge: `raise TypeError.new("left\0right")`, an object and not a class with a message, ends with `left (TypeError)`, since the object's raise hands its message on as a bare C string; `warn e` and `abort` with such a message stop at the NUL. And one that is new with that merge: the `_try` helper of an extension hands its C host the counted form, marker first (it gave the text to the NUL).

Both tests send stderr to a file and read it back, so each `.expected` is CRuby's own output. One reads the lines of nine at_exit hooks that raise: one with no NUL, then plain, a leading and a trailing NUL, in a Fiber, under Mutex#synchronize, raised again, a built String, past an ensure and a rescue that does not match. The other reads a thread's report, and waits for the line, since a join can return before the report is written.

Measured on master a2bd89005: both tests are right at -O0 to -O3 and with clang (master: 8 of 11 lines wrong, and 1 of 3). The hooks test is right under both stress modes and in 100 plain runs; the thread test under stress mode 1 and in 300 plain runs. Under stress mode 2 the thread test aborts in about one run of eight, on master and here alike, and so does a thread that raises with no NUL in its message: the mark reaches the dead thread's freed message. That is master's own and not touched here. With `--debug` the line is the raising frame, then the whole message, then the `from` lines (master: the frame, then the marker). The 22 tests that pin stderr pass, and `make backtrace-test`. No corpus program's C changes (6,377 identical); the scale-test ratios are master's (1.71, 4.73, 6.05, 4.18).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
