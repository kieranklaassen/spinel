<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A constant that holds nil was not read as a `when nil` arm.

```ruby
NOTHING = nil
p(case 0 when NOTHING then :hit else :miss end)
```

Master (dafa0d047) prints `:hit`. CRuby prints `:miss`.

Only the literal `nil` took the arm that asks the subject for its own nil. Beside an Integer or a Float the constant was compared as a number, nil read as 0, and matched 0 and 0.0; beside a String, an Array or a Hash it never matched one that was nil. A constant that holds nil, bare or under a module (`Cfg::NONE`), now takes the same arm.

Not in this change: `when NilClass` still misses a nil Array (`rows[9]` past the end). With the constant's arm after it, that subject took the else on master and takes the constant's arm here; CRuby takes the `when NilClass` arm.

Test: `test/case_when_nil_constant.rb`, 30 lines; 12 of them fail on master.

This sits on the pull request for `when nil` beside an Array or a Hash: both edit the one condition of that arm.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
