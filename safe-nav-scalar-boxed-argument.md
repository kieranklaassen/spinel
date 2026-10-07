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
- Now: `undefined method 'clamp' for an instance of Float (NoMethodError)`.
- CRuby: `1.2`.

That change left every `&.` call to a scalar method written in Ruby (`builtins/integer.rb`, `builtins/comparable.rb`) on the typed emitter, so that a nil receiver answers nil. The typed emitter does not serve a boxed argument. With one, and a receiver that is not nil, three things that were right are not: `f&.clamp(id(1.0), id(1.2))` raises, `i&.between?(id(1), id(20))` does not build (`invalid operands to binary >=`), and `i&.remainder(id(5.0))` answers `2` for `2.0`.

Now a `&.` call with a boxed argument is moved onto its builtins definition after all, as `(t = recv; t.nil? ? nil : copy(t, args))`: the receiver runs once and no argument runs under a nil one. It is the shape `desugar_builtin_enum_calls` gives a `&.` call. Every other `&.` call stays on the typed emitter, and its C is master's.

Not here: an argument that is not boxed and runs code still runs under a nil receiver, `z&.clamp(lg(1), lg(5))` with `lg` typed Integer, as on master.

Test: `test/safe_nav_scalar_boxed_argument.rb`, 29 lines; it does not build on master.

Generated C against master (`make cident REF=a39414338`): 6369 identical, 1 differ, 0 refusal changes. The one is the new test. optcarrot's generated C is byte-identical.

47 small programs written for this change (the ten methods of `builtins/integer.rb` and `builtins/comparable.rb` under `&.`, on an Integer and on a Float, with literal, local and boxed arguments, each with a receiver that is nil and one that is not), with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`: 42 are right in all six on master, 47 here, and none loses a cell. The 21 `safe_nav_*` tests on master pass in all six.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
