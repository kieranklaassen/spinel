<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`when nil` beside an Array or a Hash subject never matched, so one that was nil took the else.

```ruby
rows = [[1, 2], [3]]
p(case rows[9] when nil then :none else :row end)
```

Spinel prints `:row`. CRuby prints `:none`. The same happened for an Array or a Hash read from an instance variable that was never written.

An Array and a Hash hold nil as NULL, as a String does. The arm that asks a String for it (#7492) now takes them too: its condition is widened, and the three lines under it are as they were.

Checked:

- `test/case_when_nil_array_hash.rb` fails on master and passes here, also under `SPINEL_GC_STRESS=1` and `2`. It has an empty Array beside a nil one: empty is not nil.
- 858 generated `case` programs with a nil arm (13 kinds of subject, 22 sources of the nil, 3 forms; 13,368 cases), each against CRuby: 198 cases go from wrong to right (126 with an Array, 72 with a Hash) and no other case changes.
- Generated C, `tools/cident.sh` against master: only the new test's C differs; every other program, optcarrot and the benchmarks among them, is byte-identical.

Left alone:

- `when NilClass` beside an Array or a Hash still misses a nil one, as on master. Where a `when nil` arm follows it, a nil subject took the else on master and takes the `when nil` arm here; CRuby takes the `when NilClass` arm. Wrong before and after, with another answer.
- A constant that holds nil (`NOTHING = nil`, `when NOTHING`) is not this arm yet. That is the next pull request.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
