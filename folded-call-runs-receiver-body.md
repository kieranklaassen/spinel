<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A call whose answer does not need its receiver's value never ran the receiver:

```ruby
class Shape; end
$n = 0
def bump = ($n += 1; 7)
p bump.size                           # 8
p bump.respond_to?(:abs)              # true
puts "no" unless bump.is_a?(Shape)    # no
p $n                                  # 3 in CRuby; 0 on master
```

`bump` is never called, and `(7 / z).size` with `z` zero answers 8 where CRuby raises ZeroDivisionError.

Three places emitted the answer alone:

- Six rows of `src/builtin_ops.c` did not name `$r`: Integer#size, and a Float Range's `cover?`, `include?`, `member?`, `===` and `eql?` given a non-number. They now name it as the table's other constant rows do, `((void)($r), ...)`.
- `respond_to?` with a literal name, answered from the receiver's type.
- An `if`, `unless` or ternary on that `respond_to?`, or on `is_a?`, `kind_of?` or `instance_of?` of a class the receiver's type rules out, which keeps only the live arm.

In the last two the receiver is emitted ahead of the answer only where `subtree_has_side_effect` says it can act; a receiver that is a variable, a constant or a literal compiles to the C it did.

Test: `test/folded_call_runs_receiver.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
