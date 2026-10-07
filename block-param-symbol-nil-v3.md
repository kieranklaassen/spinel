<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A literal nil yielded into a block parameter that holds a Symbol was written as 0, the id of the program's first Symbol.

```ruby
def marks
  yield nil
  yield :a
end
marks { |m| p m }
```

Master (dafa0d047) prints `:marks` and `:a`. CRuby prints `nil` and `:a`.

An Integer and a Float parameter take their own nil at that line of `emit_block_arg_coerced`. A Symbol had no line there and now takes the Symbol's nil, `(sp_sym)-1`. `when nil` beside a Symbol subject compared with 0, the same mistake from the other side, and now asks for the Symbol's nil. The two are one commit because either alone turns `case m when nil` for the yielded nil from right to wrong.

Not in this change: what a Symbol slot holding nil gets wrong wherever its nil came from (`m == nil`, `!m`, `m.class`, `in nil`) stays as on master.

Test: `test/block_param_symbol_nil.rb`, 33 lines; 14 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
