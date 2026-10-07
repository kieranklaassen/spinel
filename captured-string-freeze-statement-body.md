<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = "qr".dup
t = s
t.freeze
l = -> { t << "x" }
begin
  l.call
rescue FrozenError => e
  p e.class     # FrozenError
end
p s.frozen?     # true
```

Before: does not build, `error: 'lv_t' undeclared`.

After: FrozenError and true.

The statement arm of `freeze` froze a shared String local by its C name, `sp_gc_freeze((void *)lv_t)`. A local a proc captures is in its cell, so that C local does not exist, outside the proc (above) or inside it (`l = -> { t.freeze; 1 }`). The arm now takes the handle through `emit_local_ref`, which reads the cell or the capture. `freeze` in value position already went through `strbuf_slot_ref` and is unchanged. No cost: a local no proc captures writes the same C.

Measured with gcc against CRuby 3.3.6, on master 8dc5522541bb:

- 63 programs that freeze a captured String on one side of a proc and change it on the other (`<<`, `replace`, `insert`, `slice!`, `setbyte`, `upcase!`, `clear`; a lambda, a proc, a captured parameter; frozen outside and changed inside, and the reverse): 19 were right and 44 did not build; the 63 are right.
- 490 more programs that change a captured String in place, with this statement or without: 457 were right and stay right; the 10 that did not build have the statement and are right; 23 fail as before for another cause (10 are refused, 13 print another line).
- `make cident REF=8dc5522541bb`: `6447 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`; the one that differs is the new test, whose C master writes and the C compiler rejects.
- `test/captured_string_freeze.rb`: master does not build it. With the change it prints its `.expected` with gcc and clang, with `--int-overflow=promote`, and under `SPINEL_GC_STRESS=1` and `2`; `make reject-test` and `tools/refusals.sh` pass.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
