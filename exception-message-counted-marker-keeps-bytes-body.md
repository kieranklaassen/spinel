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

The message that came back was a gigabyte of whatever followed the String in memory. With `"ab"` after the six bytes it was 25,185 bytes, and with nothing after them it came back empty. With `\x02` for the sixth byte, the form a frozen String's message takes, it came back the same way.

A message that holds a NUL, and a frozen String's, travels from the raise as a counted message: six marker bytes, the payload's length, the payload. Every reader took a message for a counted one by the six bytes alone (`sp_cmsg_p`), so a String of the program that begins with them had its next four bytes read as a length.

`sp_cmsg_p` now also asks the string for its own length, which for a counted message is the header's ten bytes plus the payload's. It reads that length only once the six bytes match, and only a String, with its own header, has them. A String that is such a message byte for byte would still be read as its own payload, so `sp_exc_msg_given` sends it counted itself, as it sends one that holds a NUL. With no NUL in it such a String is sixteen megabytes long, each byte of its length nonzero; rescued, it came back ten bytes short on master and is whole here.

Left alone: every message that does not begin with the six bytes. `sp_cmsg_p` answers no for it on the first byte, as before. The change is in `lib/sp_alloc.h` and `lib/sp_exc.h`; the compiler is not touched, so no generated C changes.

Cost (callgrind, gcc -O2, 1,000,000 raises each, the rescue reading the message's size), paid where a counted message is read, since `sp_cmsg_p` now asks it for its own length: a raise of a literal pays 38 instructions (2,291,281,058 to 2,329,279,932, 1.7%); a class with a String built at run time, 4 (1,921,380,086 to 1,925,378,958, 0.2%); a class alone, 7 (1,794,311,158 to 1,801,307,774, 0.4%); a message that holds a NUL, 101 (2,032,703,074 to 2,133,704,202, 5.0%), and the same 101 with 1,000 bytes before the NUL (3,972,287,135 to 4,073,282,623, 2.5%). An exception object raised pays 1 (1,051,753,184 to 1,052,753,211), and one whose message holds a NUL, 29 (1,708,416,990 to 1,737,419,246, 1.7%).

Not here, each the same on master:

- A frozen String that is a whole counted message byte for byte, sixteen megabytes of it: raised by itself or with a class, it comes back ten bytes short.
- A binary message comes back as UTF-8: `m = "\xFFab".b`, raised and rescued, has `e.message.encoding` UTF-8 and `e.message == m` false, though its bytes are m's. The test compares bytes.
- Uncaught, a message that holds a NUL prints the marker bytes: "An uncaught exception whose message holds a NUL prints the message".

The test raises twelve messages (the next four bytes a gigabyte, nothing after the six, two bytes after, a whole counted message, the same with a NUL in its payload, a NUL after the six, the sixteen megabytes, three of these with `\x02` for the sixth byte, and two literals), each six ways (raised, raised with a class, made and then raised, raised again, as a cause, from a callee), and one of them 300 times.

Measured on master 9922a2c74. The test is right at -O0 to -O3, with clang and under both stress modes. Master prints the wrong sizes from its first line (`long: raised 1094795585 false`) and is still copying when it is stopped after 20 seconds, in each of its five builds. `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit on master 9922a2c74: the build, the test in the seven builds, `ruby tools/gate.rb check` with the change staged, `make int-min-test`, and the eight cost programs under callgrind. The compiler is not touched, so no corpus program was compiled again; optcarrot was, and its C is master's by hash.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none
