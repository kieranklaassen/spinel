<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A fix with a stated cost. A parent's Integer or Float parameter that a `super` can hand nil now tests for the nil sentinel where it is read, as the parameter of an ordinary call already does. A program pays that wherever the value can be nil by the analysis, whether or not a nil ever arrives. callgrind, instructions for one more loop turn that reaches the read, before and after:

| the parent reads | gcc | clang |
|---|---|---|
| an Integer it stored, two compares and an add | 20 to 17 | 16 to 16 |
| a Float, `k * 2.0` | 8 to 11 | 6.4 to 11 |
| a Float, `(k \|\| 2.5) + 1.0` | 11 to 11 | 12.5 to 16 |
| a Float, two compares and an add | 11 to 14 | 13 to 17 |

In the corpus the C of 23 tests changes: 22 through the bundled ffi and fiddle packages (`super(nt.kind, ...)`, where `nt.kind` can be nil by that analysis) and test/kw_nil_value_from_merged_hash.rb through its own `super(k1: nil, **nil)`. The 23 pass, and optcarrot's C is unchanged. The constructor through the `super` costs the same before and after under both compilers.

```ruby
class Account
  attr_reader :rate
  def initialize(rate)
    @rate = rate
  end
  def summary = ["rate", @rate]
end
class Savings < Account
  def initialize(rate) = super
end
p Savings.new(1.5).summary    # ["rate", 1.5]
p Savings.new(nil).summary    # ["rate", NaN]; CRuby prints ["rate", nil]
```

The same through `super(k)`, `super(k, &b)`, a keyword, a second parameter, a module's method and a chain of supers, wherever the parent boxes the value: an Array or a Hash it builds, a yield (`f.nil?` answered false), `k || 1.0`. An Integer read from an instance variable nothing set, handed on by `super(@n, &b)`, answered false to `nil?` in the block.

A Float or an Integer that can also be nil keeps its scalar slot with nil as the sentinel, and what boxes it asks the slot's mark whether it can be the sentinel. `mark_nullable_int_locals` hands that mark from a call's argument to the parameter it binds, for CallNodes only. A `super` is not one, so the parent's parameter never got the mark and its reads were boxed as a plain number.

The same round now walks every `super`. One with arguments hands them through `mark_nullable_params_of_call` to the method it calls. A bare `super` hands each of its method's parameters' marks to the parameter it fills: a positional one in order, a keyword by name. Analysis only: no box or helper changes. The mark goes on only where the value at the `super` can be nil by the analysis already there; `super(1, 2)` keeps its C.

Not here, wrong as before with the C unchanged: a splat (`def self.calc(*a) = super(*a)`), a bare `super` in a method with a rest parameter, and a Float read from an instance variable nothing set and handed on by `super(@n)` in a class method or a module's method.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
