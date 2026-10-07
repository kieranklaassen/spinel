<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`to_i` and `to_f` on a String handle local that is nil died with SIGSEGV with gcc, and with clang answered from the bytes the local held before the nil.

```ruby
t = +""
t << "4"
t << "2"
t = nil if ARGV.empty?
p t.to_i     # master: SIGSEGV (gcc), 42 (clang). CRuby: 0
```

`to_i` and `to_f` only read the receiver's bytes, so `emit_scalar_recv_arms` hands them the handle's live buffer (`emit_strbuf_read_ref`): `sp_String_cstr(t)`, with no test of the handle, and nil is a NULL handle. Where the receiver is a local of its own the nil fact says may be nil and nil answers the method itself, the read is now `(t ? sp_String_cstr(t) : NULL)`, and the conversion of NULL is 0, as it is for a plain String local that is nil. A local the fact proves not nil, a parameter or a shared handle (another name writes through it), a read whose nil would be past an error the build does not raise (`nil_fact_unraised`), and every other method keep their C. It adds nothing to the codegen nil helpers and no guard.

Cost, by callgrind on master 8b3ba5c4: 2 instructions a call where the fact says the local may be nil (1,000,000 calls: 949,140,640 instructions before, 951,142,615 after); none elsewhere.

`tools/cident.sh` against the pull request this sits on, on master 8b3ba5c4: 6,369 identical, 1 differ, 0 refusal changes, of 6,370: this test.

Not here: `t.to_i(16)` on a nil handle local prints 0, as a plain String local's nil does on master; CRuby raises ArgumentError.

Depends on the pull request "A String handle local that may be nil reads as nil".

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
