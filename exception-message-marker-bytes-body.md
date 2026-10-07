<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
m = "\xFF\xFECM\xFD\x01AAAA rest".b
begin
  raise m
rescue => e
  p e.message.bytesize
end
```

prints `1094795585`. After, as CRuby: `15`.

The message that came back was a gigabyte of whatever followed the String in memory. With `"ab"` after the six bytes it is 25,185 bytes, with `"abcd"` it is 1.6 gigabytes, or a segmentation fault where the message is a literal, and with nothing after the six bytes the message comes back empty.

A message that holds a NUL travels from the raise as a counted message: six marker bytes, the payload's length, the payload. Every reader (`sp_msg_heapify` at the raise, `sp_exc_msg_copy` when the object is made) took a message for a counted one by the six bytes alone. A String of the program can begin with the same six bytes, and then its next four bytes were read as a length: `AAAA` is 0x41414141.

`sp_cmsg_p` now also asks the String for its own length, which for a counted message is the header's ten bytes plus the payload's. The own length is read only once the six bytes match, which only a String, with its own header, does; the four length bytes are read only when the String has ten. The test is in the reader, not only where a message is given, because a raised exception object hands its message on as it is (`e = RuntimeError.new(m); raise e`): wrapping at the raise alone would leave those reading a made-up length.

One String still reads as counted by that test: one that is such a message byte for byte (the marker, a length, exactly that many bytes). `sp_exc_msg_given` gives it as the payload of a counted message, as it does a String with a NUL, so it comes back whole too.

Left alone: every message that does not begin with the six bytes. `sp_cmsg_p` answers no for it on the first byte, as before. The C of all 6,406 corpus programs is identical (the change is in `lib/`).

Cost, in instructions (callgrind, -O2, 1,000,000 raises each, against master):

| | master | here | a raise, in the functions changed |
|---|---|---|---|
| `raise "a literal"` | 1,985,575,440 | 1,946,575,433 | 5 more |
| `raise ArgumentError, m`, m a built String | 1,855,977,714 | 1,861,977,734 | 6 more |
| the same, a NUL in m | 1,938,532,807 | 2,000,533,955 | 62 more |
| `raise IOError`, no message | 1,723,864,095 | 1,718,864,113 | 4 more |

The totals also move with libc's string compares, whose count depends on where a build puts the class names (`strcmp` runs 44 fewer a raise in the first row, `strncmp` 9 fewer in the last), so the last column counts the functions of this change. Any message pays 4 in `sp_msg_heapify`, and 1 or 2 where it is given, for the look at its first byte. A counted message pays the String's own length read against the header's: at the raise (`sp_raise_cls` 13, `sp_msg_heapify` 34) and when the object is made (`sp_exc_msg_copy` 15).

Not here, each the same on master:

- An exception object that nothing rescues prints its message to the first NUL: `raise RuntimeError.new("a\0b")` ends with `a (RuntimeError)`. The object's message goes to the uncaught line as a C string. The same path prints a String that is a counted message byte for byte as its six marker bytes and one more.
- `Exception#exception(m)` cuts m at its first NUL.
- A binary message comes back as UTF-8: `m = "\xFFab".b`, raised and rescued, has `e.message.encoding` UTF-8 and `e.message == m` false, though its bytes are m's. The test compares bytes.

Measured on master 4f8b737c1. The test is right at -O0 to -O3, with clang and under both stress modes. On master it does not finish in 20 seconds at any level: it compares gigabyte messages. It raises five messages (the next four bytes a gigabyte, nothing after the six, two bytes after, a whole counted message, a NUL after the six) each six ways (raised, raised as a class, made and then raised, raised again, as a cause, from a callee), then one of them 300 times. Of 612 generated programs (17 messages: the five of the test, the marker before `abcd`, as a literal, built from parts, a counted message with no payload, with one byte too few and one too many, of 258 bytes, one inside another, five of the six bytes, the six bytes after an `x`, and two plain ones, one with a NUL; each rescued 21 ways and ending uncaught 15 ways), master is right for 336: the others are a wrong size, a segmentation fault where the message is a literal, or no end in ten seconds. Here 484 are right and none that master had right is lost. The 128 left are the 8 messages that hold a NUL: uncaught (120, master's bytes; the line an uncaught exception ends with is not touched here), and through `Exception#exception` (8: five print master's bytes, three had a wrong size on master and are cut at the NUL like the rest). `make backtrace-test` passes; the scale-test ratios are master's (1.71, 4.74, 6.13, 4.17); `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
