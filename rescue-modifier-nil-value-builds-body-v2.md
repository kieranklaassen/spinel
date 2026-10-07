<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def none; nil; end
x = (none rescue nil)
p x
```

does not build: `error: variable or field '_t1' declared void`. CRuby prints `nil`.

After: `nil`.

A rescue modifier used as a value keeps its result in a C temporary of the modifier's type. When both arms are always nil that type is nil, which has no C type to be stored in, and the temporary was declared `void`. It is now held boxed, as the temporary of `begin ... rescue ... end` in the same function is.

Left alone: `!` and `&.` on such a modifier (`p !(none rescue nil)`), which build on master and do not run it.

Measured on master 8684d54ce: the test builds at no level on master and is right at every level, with clang and under `SPINEL_GC_STRESS=1` and `2`. Of 448 generated programs (16 always-nil modifiers in 28 uses) master builds 33; this builds all 448, the 415 new ones right in a plain run and under `SPINEL_GC_STRESS=2`, the 33 as they were (28 of them the `!` and `&.` uses). The C of the 6,341 corpus programs and of optcarrot is unchanged; scale-test keeps master's four ratios.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
