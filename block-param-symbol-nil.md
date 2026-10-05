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

Spinel prints `:marks` and `:a`. CRuby prints `nil` and `:a`. Inside the block `m.nil?` was false, `m` was truthy, `m || :none` was `:marks` and `"#{m}"` was `"marks"`.

An Integer and a Float parameter take their own nil at that line of `emit_block_arg_coerced`. A Symbol had no line there and now takes the Symbol's nil, `(sp_sym)-1`.

`when nil` beside a Symbol subject made the same mistake from the other side. It compared with 0, so it took that parameter for nil, and the program's first Symbol with it, and it missed a Symbol that was nil another way (an element past the end, an instance variable never written). The arm, and a constant holding nil the same, now asks for the Symbol's nil. The two halves are one commit because either alone turns `case m when nil` for the yielded nil from right to wrong.

Checked:

- `test/block_param_symbol_nil.rb` fails on master and passes here, also under `SPINEL_GC_STRESS=1` and `2`.
- 858 generated `case` programs with a nil arm (13 kinds of subject, 22 sources of the nil, 3 forms; 13,368 cases), each against CRuby: 24 cases go from wrong to right and no other case changes.
- Generated C, `tools/cident.sh` against master: only the new test's C differs; the other 6,104 programs, optcarrot and the benchmarks among them, are byte-identical.

Left alone. A Symbol slot holding nil, wherever its nil came from, is still wrong where master is: `m == nil` is false, `!m` is false, `m.class` is Symbol, `m&.to_s` is `""` and `in nil` misses, and the class tests (`m.is_a?(NilClass)`, `when NilClass`) and the other methods nil has take it for a Symbol.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
