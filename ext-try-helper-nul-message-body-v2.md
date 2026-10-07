<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A regression of "An exception message that holds a NUL keeps its bytes": since it, a C host that calls an extension through `<init>_try` and reads the message of a raise is handed the seven bytes of the counted form where it was handed the message's text.

Depends on "An exception message that begins with the counted form's marker keeps its bytes". The helper takes a message for a counted one by `sp_cmsg_p`; without that fix a message that only begins with the six marker bytes reaches the host without its first ten bytes, and the fixture's last line fails (` rest`, 5 bytes, where master hands out all 15).

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

The try helper hands out the raise's own slot. A message with a NUL in it sits there in the counted form: six marker bytes, the length, then the text. The host's side of the contract is a C string, so the helper now hands out a counted message's text, and the host reads it to the NUL as it did. Any other message is handed out as it was: the emitted line changes only inside `<init>_try`.

The CRuby shim re-raises with the same string (`rb_raise(k, "%s", msg)`), so its exception's message was the seven bytes too and is `left` now.

Left alone: a program built without `--ext-init` has no such helper; the C of all 6,406 corpus programs is identical.

Not here: the host reads the text to the NUL, not past it, and so does CRuby through the shim (a pure Ruby `refuse` gives `"left\0right"`). Handing the bytes past the NUL to a host needs a length the helper's signature does not carry.

The fixture gains the entry `refuse` (`test/ext/kernel.rb`, the `--ext-entry` list of `ext-test`) and two calls in `test/ext/host.c`: the message with a NUL, and one with no NUL that begins with the six marker bytes, which reads whole. `ext-cruby-test` keeps its entries and its driver.

Measured on master 4f8b737c1, above the fix this depends on. `make ext-test` passes (master: the first new line is the seven bytes). `ext-cruby-test` skips here for want of Ruby 4.0; built by hand against Ruby 3.3.6 with `refuse` added to its entries, the shim's driver prints `expected_cruby`, and `ExtKernel.refuse("left\0right")` raises an ArgumentError whose message is `left` (master: the seven bytes), the marker-led message comes back whole and a plain one as it was. `make backtrace-test` passes; the scale-test ratios are master's (1.71, 4.74, 6.13, 4.17); function sizes are unchanged (the emitted line is replaced in place in `codegen_program`); `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (none: the fixture's `expected` is a C host's output)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: "An exception message that begins with the counted form's marker keeps its bytes"
