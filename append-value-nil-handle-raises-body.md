<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An append that is the value of its method died with SIGSEGV when the String, held as a handle, was nil. The same append as a statement raises NoMethodError, as CRuby does. A method whose value is such an append, on a local the plan says may be nil there, pays 2 instructions a call: by callgrind on master 8dc55225, 100,000 calls take 137,317,092 instructions before and 137,516,016 after with gcc, 136,124,290 and 136,323,215 with clang. Every other append compiles to the same C.

```ruby
def app(clear)
  t = +""
  t << "a"
  t << "b"
  t = nil if clear
  t << "c"       # the method's value
end
app(true)        # master: SIGSEGV with gcc, no end with clang. CRuby: NoMethodError
```

Two appends in a row make `t` an `sp_String` handle, and nil is a NULL handle. As a statement the append is emitted behind the nil arm the call plan gives it (`emit_nil_target_stmt`) and raises. As the value of its body it goes through `emit_stmt_tail_inner`'s own arm (`src/codegen_stmt.c`), which called `emit_array_mutate_stmt` past that arm: the append did nothing on the NULL handle, and the read of `t` that the arm returns died. The tail arm now emits its append behind the same nil arm (`tail_append_nil_armed`). It calls `emit_nil_target_stmt` and adds nothing to it or to any other nil helper. It applies to a handle local, and only where the plan raises for the call; every other append keeps its C. A lambda's last line and the last line of a conditional that is the method's value go through the same arm.

`tools/cident.sh` against master 8dc55225: 6,446 identical, 1 differ, 0 refusal changes, of 6,447: this test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
