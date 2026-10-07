<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def id(x) = x
id(:s)
def flt(v) = v ? 1.5 : nil
f = flt(true)
p f&.clamp(1.0, id(1.2))
```

- Before "v&.fdiv(2) and the other Ruby-defined Integer methods keep the &.": `1.2`.
- Master: `undefined method 'clamp' for an instance of Float (NoMethodError)`.
- Here and CRuby: `1.2`.

`i&.between?(id(1), id(20))`, on an Integer or a Float, does not build on master (gcc: `invalid operands to binary >=`; clang: `invalid operands to binary expression`). That change left every `&.` call to a scalar method written in Ruby on the typed emitter, so that a nil receiver answers nil. The typed emitter has no arm for `between?`, or for a Float's `clamp`, with a boxed bound.

Those two calls, with a boxed bound, are moved onto their `builtins/comparable.rb` definition after all, as `(t = recv; t.nil? ? nil : copy(t, args))`: the receiver runs once and no argument runs under a nil one. It is the shape `desugar_builtin_enum_calls` gives a `&.` call. Every other `&.` call stays on the typed emitter, a Bignum receiver among them, and its C is master's.

Not here, and as on master:

- A bound typed Bignum is not a boxed one: `f&.between?(1, 2**70)` does not build and `f&.clamp(1, 2**70)` raises NoMethodError.
- The methods of `builtins/integer.rb` keep the typed emitter's arm under `&.`: `i&.remainder(id(5.0))` answers `2` for `2.0`, `i&.gcdlcm(2**70)` answers `[12, 0]` and `i&.clamp(2**70, 2**71)` answers `12`.
- `between?` in `builtins/comparable.rb` compares with both bounds before it answers. `i&.between?(id(20), id("a"))`, which did not build, now raises ArgumentError where CRuby answers `false`, as `i.between?(id(20), id("a"))` does on master.

Test: `test/safe_nav_scalar_boxed_argument.rb`, 44 lines, 33 expected; it does not build on master.

Generated C against master (`make cident REF=3cb8982d8`): 6391 identical, 1 differ, 0 refusal changes. The one is the new test. optcarrot's generated C is byte-identical.

315 small programs written for this change (`between?` on an Integer that is 12, 0 or -7 and on a Float, and a Float's `clamp`, with one bound or both boxed and holding an Integer, a Float, a Bignum, nil or a String), each beside the same call with a `.`, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`. On master none of the 252 `between?` programs builds and each of the 63 `clamp` programs raises NoMethodError. Here 176 are right in all six; 111 raise where CRuby raises; 28 raise where CRuby answers `false` (the third point above). Each of the 315 prints what its `.` twin prints on master. 24 more with a receiver that is nil (the `clamp` call as a statement, a value, a condition, an argument, a receiver, in a block, a method and an interpolation): 22 are right in all six on master, 24 here; in the two, master ran the arguments under the nil receiver.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
