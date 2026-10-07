## What this changes

`to_i` and `to_f` on a String handle local that is nil died with SIGSEGV, with and without `--share-strings`.

```ruby
t = +""
t << "4"
t << "2"
t = nil if ARGV.empty?
p t.to_i     # master: SIGSEGV. CRuby: 0
```

Both only read the receiver's bytes, so `emit_scalar_recv_arms` hands them the handle's live buffer (`emit_strbuf_read_ref`): `sp_String_cstr(t)`, with no test of the handle, and nil is a NULL handle. Where the nil fact says the receiver may be nil and nil answers the method itself, the read is now `(t ? sp_String_cstr(t) : NULL)`, and the conversion of NULL is 0, as it is for a plain String local that is nil. The buffer is still read in place; a receiver the fact proves not nil, and every other method, keep their C.

`tools/cident.sh` against master b06496ff: 6,337 identical, 1 differ, 0 refusal changes, of 6,338: this test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
