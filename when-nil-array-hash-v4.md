<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`when nil` beside an Array or a Hash subject never matched, so one that was nil took the else.

```ruby
rows = [[1, 2], [3]]
p(case rows[9] when nil then :none else :row end)
```

Master (dafa0d047) prints `:row`. CRuby prints `:none`.

An Array and a Hash hold nil as NULL, as a String does. The arm that asks a String for it (upstream pull request 7492) now takes them too: its condition is widened, and the lines under it are as they were.

Not in this change: `when NilClass` beside that Array still misses the nil one. Where a `when nil` arm follows it, the nil subject took the else on master and takes the `when nil` arm here; CRuby takes the `when NilClass` arm.

Test: `test/case_when_nil_array_hash.rb`, 14 lines; 6 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
