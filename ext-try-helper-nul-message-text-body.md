<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A regression of "An exception message that holds a NUL keeps its bytes": since it, a C host that calls an extension through `<init>_try` and reads the message of a raise is handed the seven bytes of the counted form where it was handed the message's text.

Depends on "An exception message that begins with the counted marker keeps its bytes". The helper takes a message for a counted one by `sp_cmsg_p`; without that fix a message that only begins with the six marker bytes reaches the host without its first ten bytes, and the fixture's second new line fails (` rest`, 5 bytes, where master hands out all 15).

Before, in the extension fixture:

```ruby
def self.refuse(s)
  raise ArgumentError, s if s.bytesize > 0
  s
end
```

called with `"left\0right"` by a C host through `Init_ext_kernel_try`, the host's `printf("raised %s: %s (%d bytes)\n", cls, msg, (int)strlen(msg))` prints

```
raised ArgumentError: ff fe 43 4d fd 01 0a (7 bytes)
```

(the seven bytes written here in hex). After:

```
raised ArgumentError: left (4 bytes)
```

which is what the host read before that pull request.

The try helper hands out the raise's own slot. A message with a NUL in it sits there in the counted form: six marker bytes, the length, then the text. The host's side of the contract is a C string, so the helper now hands out a counted message's text, and the host reads it to the NUL as it did.

An exception object can stand beside a counted slot. After a rescue and a bare `raise` the object was made from that slot. And an object can be raised whose own message is a counted message byte for byte, a NUL in its text: the raise of an object puts the object's message in the slot as it is. In both the object's message is the message, so where the slot holds a counted message and an object stands beside it the helper hands out the object's message.

Left alone: a slot that does not hold a counted message is handed out as it was, a raise with no message among them (the host reads the class name or `""` as before). The emitted line changes only inside `<init>_try`; a program built without `--ext-init` has no such helper, and the C of all 6,530 corpus programs is unchanged.

The CRuby shim re-raises with the same string (`rb_raise(k, "%s", msg)`), so by its source its exception's message was the seven bytes too and is `left` now; `ext-cruby-test` needs Ruby 4.0 and skips itself here.

Not here: the host reads the text to the NUL, not past it, and so does CRuby through the shim (a pure Ruby `refuse` gives `"left\0right"`). Handing the bytes past the NUL to a host needs a length the helper's signature does not carry.

The fixture gains three entries, `refuse`, `refuse_object` (the same raise as an object) and `refuse_again` (rescued, then a bare `raise`), in `test/ext/kernel.rb` and the `--ext-entry` list of `ext-test`, and six calls in `test/ext/host.c`: the message with a NUL; one with no NUL that begins with the six marker bytes, which reads whole; a message that is a counted message byte for byte with a NUL in its text, by class and as an object (7 bytes each, to its first NUL); and the first message as an object and raised again. `ext-cruby-test` keeps its entries and its driver. No test with an `.expected` is added: the fixture's `expected` is the C host's output.

Measured on master 9922a2c74 with the pull request beneath. `make ext-test` passes. With the fixture's new entries and calls alone, master fails two of the six new lines, the first and the one raised again (the seven bytes each); with this change and without the pull request beneath, the second alone (5 bytes for 15). `make backtrace-test` passes; the scale-test ratios are 4.73, 6.14 and 4.13, under their limits; `ruby tools/gate.rb check` with the change staged answers 0. One line of `codegen_program` changes.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit above the pull request beneath on master 9922a2c74: the build, `make ext-test` (and the fixture on master and without the pull request beneath), `ruby tools/gate.rb check` with the change staged, the C of all 6,530 corpus programs against master's, `make backtrace-test`, `make scale-test`, `make int-min-test`, and optcarrot's C by hash.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: the pull request "An exception message that begins with the counted marker keeps its bytes"
