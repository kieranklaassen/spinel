<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A fix with a stated cost. A parent's Integer or Float parameter that a `super` can hand nil now tests for the nil sentinel where it is read, as the parameter of an ordinary call already does. In the corpus that changes the C of 23 tests, all through the bundled ffi and fiddle packages (`super(nt.kind, ...)`, where `nt.kind` can be nil by that analysis); the 23 pass, and optcarrot's C is unchanged. callgrind on a method of that shape (two compares and an add on the stored value): 20 instructions a call before and 17 after under gcc, 16 and 16 under clang. The constructor through the `super` costs the same before and after under both.

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

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
