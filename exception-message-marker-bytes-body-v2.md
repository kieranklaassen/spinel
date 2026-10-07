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

`sp_cmsg_p` now asks two more things of a String that begins with the six bytes. Its own length must be the header's ten bytes plus the payload's. And the payload must hold a NUL: that is the only reason a counted message is ever built. `sp_exc_msg_given` is the one place that builds one, and only for a message with a NUL in it (`git grep sp_exc_msg_counted -- lib src` finds its definition, its declaration and that one call). The own length is read only once the six bytes match, which only a String, with its own header, does; the payload is read only when the lengths agree.

How a message is given is not touched. So a String that is such a message byte for byte and holds a NUL, as every one shorter than sixteen megabytes does in its length bytes, is still given as the payload of a counted message and comes back whole, as on master. One with no NUL anywhere, each byte of its length a 1, is 16,843,019 bytes long; it is a plain message now:

```ruby
m = "\xFF\xFECM\xFD\x01\x01\x01\x01\x01".b + "x" * 16_843_009
raise m
```

Uncaught, it ends the program with 16,843,035 bytes on stderr on master and here (m, then ` (RuntimeError)`): its slot holds the same bytes as before, and so with `raise TypeError, m`, in an at_exit hook and in a thread's report. Rescued, `e.message` came back ten bytes short on master (its "payload") and is whole here; so is the line of `raise RuntimeError.new(m)`, 16,843,025 bytes on master and 16,843,035 here.

Left alone: every message that does not begin with the six bytes. `sp_cmsg_p` answers no for it on the first byte, as before. The change is in `lib/sp_alloc.h` only; no generated C changes.

Cost, in instructions for a loop of a million raises, each rescued (callgrind, -O2). With a literal message, a built one of 46 bytes or none, raised by class or as an object, the totals are master's to within 14 instructions and no function's count moves. A message that holds a NUL pays a scan up to its first NUL each time it is read, twice at the raise and once where the object is made: 168 instructions a raise (1,939 to 2,107) with the NUL at the seventh of 51 bytes, 688 (3,881 to 4,569) with 1,000 bytes before it.

Not here, each the same on master:

- `Exception#exception(m)` cuts m at its first NUL: `RuntimeError.new("first").exception("AAAAAAAAAA\0tail")` has a message of 10 bytes, on master and here (CRuby: 15). With the marker in front, `"\xFF\xFECM\xFD\x01AAAA\0tail".b`, master read the cut message's `AAAA` as a length (1094795585 bytes); here it is the same 10 bytes as its twin.
- A binary message comes back as UTF-8: `m = "\xFFab".b`, raised and rescued, has `e.message.encoding` UTF-8 and `e.message == m` false, though its bytes are m's. The test compares bytes.

Measured on master 9274c732e. The test is right at -O0 to -O3, with clang and under both stress modes (0.6 s at `SPINEL_GC_STRESS=2`, the sixteen megabytes with it). On master it does not finish in 20 seconds at any level: it compares gigabyte messages. It raises seven messages (the next four bytes a gigabyte, nothing after the six, two bytes after, a whole counted message, the same with a NUL in its payload, a NUL after the six, and the 16,843,019 bytes) each six ways (raised, raised as a class, made and then raised, raised again, as a cause, from a callee), then one of them 300 times. Of 720 attack programs (20 messages: the marker alone, with two and four bytes after it, whole counted messages with and without a NUL in them, one inside another, the two of sixteen megabytes, plain ones; each rescued 21 ways and left uncaught 15 ways) master is right on 388 and this on 560; none is lost. The 160 left are the ten messages that hold a NUL, uncaught (150: "An uncaught exception whose message holds a NUL prints the message" takes them) and through `Exception#exception(m)` (10). 154 of them print master's bytes; the six that do not are `exception(m)` with a marker-led message, cut at the NUL as their twins are. `make backtrace-test` passes; the scale-test ratios are master's (1.71, 4.74, 6.13, 4.17); `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
