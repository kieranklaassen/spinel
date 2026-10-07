<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A builtin whose C names its receiver twice called the receiver twice. A receiver that is more than a read is now read into a temp first: it pays that one temp and loses the second call. A receiver that only reads (`subtree_is_pure_read`: a variable, a literal, a field) emits the C it did.

```ruby
$n = 0
def bump = ($n += 1; -17)
p bump.divmod(7)
p bump.nonzero?
p $n
```

```
spinel diff: output-diff
  program: once.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,3 @@
 [-3, 4]
 -17
-2
+4
```

Three places repeat the receiver. A row of `builtin_ops.c` that names `$r` twice repeats its text, and one with `$R` emits it again: `emit_op_template` now binds the temp for both. The `Integer#divmod` arm printed it for the quotient and for the remainder, and the Bignum `abs2` arm for each factor.

| receiver | methods | witness | runs on master |
|---|---|---|---|
| Integer | `divmod`, `nonzero?`, `magnitude`, `abs2`, `polar` | `bump.divmod(7)` | 2 (`polar` 3) |
| Float | `nonzero?`, `abs2`, `polar`, `infinite?` | `half.polar` | 2 |
| Rational | `to_i`, `to_int`, `truncate` | `frac.to_i` | 2 |
| Bignum | `abs2` | `huge.abs2` | 2 |
| Addrinfo | `ipv4?`, `ipv6?`, `ip?`, `unix?` | `addr.ipv4?` | 2 |

Cost: where the receiver runs code, a million `bump.abs2 + bump.divmod(7)[1]` take 337,308,002 instructions where they took 358,308,002. Where it only reads, the C is the same.

Not here:

- `bump&.nonzero?`: under `&.` the receiver is already held in a temp for the nil test and ran once. The three Rational rows are the exception (`frac&.to_i` ran it twice) and are cured with the rest.
- `a&.ipv4?` on an Addrinfo that may be nil does not build (`_sn_1` undeclared), before and after.
- The other arms of `int_arms_round_divide` (`div`, `fdiv`, `modulo`, `remainder`, `pow`, `ceildiv`, the rounding four with digits) run the receiver once already.

Test: `test/builtin_receiver_runs_once.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (the test is marked: it squares 2**70)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
