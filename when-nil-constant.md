<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A constant that holds nil was not read as a `when nil` arm.

```ruby
NOTHING = nil
p(case 0 when NOTHING then :hit else :miss end)
```

Spinel prints `:hit`. CRuby prints `:miss`. Beside an Integer or a Float the constant was compared as a number, nil read as 0, and matched 0 and 0.0. Beside a String, an Array or a Hash it never matched one that was nil.

Only the literal `nil` took the arm that asks the subject for its own nil. A constant that holds nil, bare or under a module (`Cfg::NONE`), now takes the same arm.

Checked:

- `test/case_when_nil_constant.rb` fails on master and on the pull request this depends on, and passes here, also under `SPINEL_GC_STRESS=1` and `2`.
- The same 858 generated programs (13,368 cases), each against CRuby, with the pull request this depends on as the base: 324 cases go from wrong to right and no other case changes.
- Generated C, `tools/cident.sh` against master: only the two new tests' C differs (this one and the one it depends on); the other 6,104 programs, optcarrot and the benchmarks among them, are byte-identical.

Left alone. A Symbol and a boolean subject are not touched here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
