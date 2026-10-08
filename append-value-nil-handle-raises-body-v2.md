<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An append that is the value of its method does nothing when the String, held as a handle, is nil, and the method answers nil. The same append as a statement raises NoMethodError, as CRuby does. A method whose value is such an append, on a local the plan says may be nil there, pays 2 instructions a call: by callgrind on master 3d629868, 100,000 calls take 137,517,882 instructions before and 137,717,882 after with gcc, 136,225,106 and 136,425,106 with clang. Every other append compiles to the same C.

```ruby
def app(clear)
  t = +""
  t << "a"
  t << "b"
  t = nil if clear
  t << "c"       # the method's value
end
p app(true)      # master: nil. CRuby: NoMethodError
```

Two appends in a row make `t` an `sp_String` handle, and nil is a NULL handle. As a statement the append is emitted behind the nil arm the call plan gives it (`emit_nil_target_stmt`) and raises. As the value of its body it goes through `emit_stmt_tail_inner`'s own arm (`src/codegen_stmt.c`), which takes that nil arm only under `--share-strings`: in the default build the append did nothing on the NULL handle, and the arm answered its read of `t`, nil. The tail arm now emits its append behind the same nil arm in the default build too (`tail_append_nil_armed`). It calls `emit_nil_target_stmt` and adds nothing to it or to any other nil helper. It applies to a handle local, and only where the plan raises for the call; every other append keeps its C. A lambda's last line and the last line of a conditional that is the method's value go through the same arm.

`tools/cident.sh` against master 3d629868: 6,497 identical, 1 differ, 0 refusal changes, 0 refused by both, of 6,498: this test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
