<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
row = [5, "q"]
x = row[0]
p x.i
```

```
spinel diff: exception-diff
  program: unit.rb
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): NoMethodError: undefined method 'i' for an instance of Integer

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +0,0 @@
-(0+5i)
```

A boxed number answers `real`, `imaginary`, `conj`, `rect`, `polar` and `to_c` through the `sp_poly_*` helpers. `i` was in none of the boxed arms: the call was left untyped and emitted as a missing method.

It is typed and emitted beside `conj` now, where no class of the program has an `i` of its own. `sp_poly_imag_unit` answers the imaginary number an Integer or a Float answers unboxed and raises NoMethodError for any other value, as before. Beside a class with its own `i` (a common reader name) the call is typed and emitted as it was, so that program keeps its C and pays nothing.

Not in this change: a boxed Rational's `i` still raises. Unboxed it answers a Float part (`Rational(1, 2).i` prints `(0+0.5i)` where CRuby prints `(0+(1/2)*i)`), and the boxed call does not take that answer. And beside a class with its own `i` a boxed Integer's still raises.

On master a3941433: `make cident` reports 6,369 identical, 1 differ, the new test, which builds on master and raises at its first `i`. `make infer-test` passes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
