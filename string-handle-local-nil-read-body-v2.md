<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A String local held as a handle (two appends in a row, or one in a loop) died with SIGSEGV when it was read while nil.

```ruby
t = +""
t << "a"
t << "b"
t = nil
p t          # master: SIGSEGV. CRuby: nil
```

```ruby
if ARGV.size > 5
  t = +""
  t << "a"
  t << "b"
end
p t.size     # master: SIGSEGV. CRuby: NoMethodError
```

Nil is a NULL handle. The local read in `emit_local_ivar_write_expr` copies `sp_String_cstr(t)` and tested the handle only for a parameter, a dynamic handle and a shared one; it now tests it wherever the nil fact says the local may be nil (`Repr.may_nil`), so `p t` prints nil. The fact's definite-assignment seed in `an_nil_facts` skipped a `TY_STRBUF` local, so a handle read before its first write had no fact and a call on it no nil target; the seed now covers it, and `t.size` raises NoMethodError as it does for a handle assigned nil. A local the fact proves not nil keeps its C.

Cost, by callgrind on master ae2c38c7, only for a local the fact says may be nil: 1 instruction more an append and a value read, 2 more a call (the guard). Any other local pays nothing.

`tools/cident.sh` against master ae2c38c7: 6,338 identical, 4 differ, 0 refusal changes, of 6,342: this test, and three tests where one such local's read gains the test or its calls the guard; each prints what it printed.

Not covered: `t.to_i` and `t.to_f` on a nil handle local still crash, as on master; so does a read after `t = ENV["X"]`, which the fact takes as not nil. Five uses that crashed now answer as a plain String local's nil does on master, which is not CRuby's answer: `p Array(t)`, `p [*t]` and `a = *t; p a` print `[nil]` (CRuby `[]`), and `t.eql?(nil)` and `t.equal?(nil)` are false (CRuby true).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
