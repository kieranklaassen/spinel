<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A regression of "An exception message that holds a NUL keeps its bytes": since it, a C host that calls an extension through `<init>_try` and reads the message of a raise is handed the seven bytes of the counted form where it was handed the message's text.

Depends on "An exception message that begins with the counted form's marker keeps its bytes". The helper takes a message for a counted one by `sp_cmsg_p`; without that fix a message that only begins with the six marker bytes reaches the host without its first ten bytes, and the fixture's second new line fails (` rest`, 5 bytes, where master hands out all 15).

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

Left alone: a slot that does not hold a counted message is handed out as it was, a raise with no message among them (the host reads the class name or `""` as before). The emitted line changes only inside `<init>_try`; a program built without `--ext-init` has no such helper, and the C of all 6,419 corpus programs is identical.

The CRuby shim re-raises with the same string (`rb_raise(k, "%s", msg)`), so its exception's message was the seven bytes too and is `left` now.

Not here: the host reads the text to the NUL, not past it, and so does CRuby through the shim (a pure Ruby `refuse` gives `"left\0right"`). Handing the bytes past the NUL to a host needs a length the helper's signature does not carry.

The fixture gains three entries, `refuse`, `refuse_object` (the same raise as an object) and `refuse_again` (rescued, then a bare `raise`), in `test/ext/kernel.rb` and the `--ext-entry` list of `ext-test`, and six calls in `test/ext/host.c`: the message with a NUL; one with no NUL that begins with the six marker bytes, which reads whole; a message that is a counted message byte for byte with a NUL in its text, by class and as an object (7 bytes each, to its first NUL); and the first message as an object and raised again. `ext-cruby-test` keeps its entries and its driver.

Measured on master 9274c732e, above the fix this depends on. `make ext-test` passes (master, and the fix this depends on alone: the first and the last new line are the seven bytes). A host that calls eight entries (a raise by class, of a String alone, of an object, of a class of the program, rescued and raised again as an object, rescued and raised bare, past an ensure, of an object made earlier) with 19 messages reads the right C string in 93 of 152 calls on master, in 108 above the fix this depends on and in all 152 here; none is lost. Eleven raises with no message read as on master. `ext-cruby-test` skips here for want of Ruby 4.0; built by hand against Ruby 3.3.6 with the three entries added to its list, the shim's driver prints `expected_cruby`, and through the shim `ExtKernel.refuse("left\0right")` and `refuse_again` raise an ArgumentError whose message is `left` (master: the seven bytes), as `refuse_object` did; the marker-led message comes back whole and a plain one as it was. `make backtrace-test` passes; the scale-test ratios are master's (1.71, 4.74, 6.13, 4.17); function sizes are unchanged (the emitted line is replaced in place in `codegen_program`); `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (none: the fixture's `expected` is a C host's output)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: "An exception message that begins with the counted form's marker keeps its bytes"
