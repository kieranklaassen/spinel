<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def f1(x)
  r = f2(x)
  return r
end
# ... f2 to f15 the same
def f16(a)
  a << 2.5
end
x = []
p f1(x)     # [2.5] in CRuby, nil on master
```

15 methods are right. With an empty Hash filled at the far end, `f1(h)["k"]` crashes the program.

An empty Array takes its kind after the inference fixpoint, from the method that fills it, and the kind comes back up as each method's return type one method a round, in a loop of eight rounds (`infer_write_types` and `infer_return_types` in `an_phase_method_backstops`). Past them the methods at the top had no return type and compiled to void functions, and each caller took nil for the value.

What was chosen: the loop keeps its eight rounds, and goes on only in a program where one of them began with a `return` whose value was still untyped. There it runs while the rounds move types, by the rule the fixpoint has (`an_round_cap_step`, which now keeps its states from half of the cap it is given; for the fixpoint's 128 that is the 64 it was). A program with no such `return` gets master's rounds and master's C: a chain that ends in `r` with no `return` is right on master, its methods boxed, and stays as it is. The rounds cost what they cost the fixpoint, a round a method; in CPU seconds of `spinel -c`:

| methods in the chain | 100 | 200 | 400 | 800 |
|---|---|---|---|---|
| `return r` over `x = []`: master, nil from 16 | 0.03 s | 0.03 s | 0.09 s | 0.22 s |
| the same: this | 0.05 s | 0.13 s | 0.60 s | 2.77 s |
| the same chain over `x = [1]`, right on master: master | 0.09 s | 0.32 s | 1.74 s | 10.53 s |
| ending in `r`, no `return`: master | 0.01 s | 0.03 s | 0.06 s | 0.18 s |
| the same: this, C identical | 0.01 s | 0.03 s | 0.06 s | 0.19 s |

Tests: `test/method_chain_return_local_long.rb` has chains of 16 to 40 methods over an Array and a Hash, top-level and instance methods. Of its eight sections, alone on master, four print nil, two do not build, one crashes and one (15 methods, and 20 ending in the local with no `return`) is right.

Generated C against master (`make cident REF=8578e3fb`): `6354 identical, 1 differ, 0 refusal changes` (the new test). `tools/refusals.sh` passes (534 records). optcarrot's generated C is byte-identical. Programs, on master 8578e3fb with CRuby 3.3.6 as the reference: 2,720 chains of 3 to 100 methods. 394 are right now, all of 16 methods or more: 310 that lost the value (nil printed, or NoMethodError raised on it), 62 that did not build and 22 that were refused. The other 2,326 are the same: 1,974 right, 336 refused by name, 16 wrong. Of the 1,974, 45 have other C, all at 15 methods, where the top-level local was boxed and is the Array now. Of the 16, 8 are this chain with each callee defined before its caller, nil from 9 methods (another loop's eight rounds), and 8 are chains of 100 methods with `rescue` or `ensure` that end in SystemStackError.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Arrays, Integers, a String and true)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
