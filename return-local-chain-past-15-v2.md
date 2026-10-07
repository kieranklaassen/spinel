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

What was chosen: the loop keeps its eight rounds. A ninth and each one after it runs only while it begins with a `return` whose value is still untyped, and those go on while they move types, by the rule the fixpoint has (`an_round_cap_step`, which now keeps its states from half of the cap it is given; for the fixpoint's 128 that is the 64 it was). A program whose `return`s have their types when the eighth round ends gets master's rounds and master's C, whatever else in it is still moving: a chain that ends in `r` with no `return` is right on master, its methods boxed, and keeps its C alone and beside a chain that has a `return`. The rounds cost what they cost the fixpoint, a round a method; in CPU seconds of `spinel -c`:

| methods in the chain | 100 | 200 | 400 | 800 |
|---|---|---|---|---|
| `return r` over `x = []`: master, nil from 16 | 0.01 s | 0.03 s | 0.06 s | 0.19 s |
| the same: this | 0.02 s | 0.06 s | 0.45 s | 2.55 s |
| the same chain over `x = [1]`, right on master: master | 0.13 s | 0.40 s | 1.81 s | 9.36 s |
| ending in `r`, no `return`: master | 0.01 s | 0.02 s | 0.06 s | 0.21 s |
| the same: this, C identical | 0.01 s | 0.02 s | 0.08 s | 0.18 s |
| that chain beside 8 methods of `return r`: master | 0.01 s | 0.03 s | 0.08 s | 0.19 s |
| the same: this, C identical | 0.02 s | 0.03 s | 0.07 s | 0.12 s |

Tests: `test/method_chain_return_local_long.rb` has chains of 16 to 40 methods over an Array and a Hash, top-level and instance methods. Of its seven sections, alone on master, four print nil, one does not build, one crashes and one (15 methods, and 20 ending in the local with no `return`) is right.

Generated C against master (`make cident REF=4f8b737c`): `6407 identical, 1 differ, 0 refusal changes` (the new test). `tools/refusals.sh` passes (536 records). optcarrot's generated C is byte-identical. Programs of ours, on master 4f8b737c with CRuby 3.3.6 as the reference: 2,720 chains of 3 to 100 methods defined caller first. 366 are right now, all of 16 methods or more: 310 that lost the value (nil printed, or NoMethodError raised on it), 38 that did not build and 18 that were refused. The other 2,354 are the same: 1,974 right, each with master's C, 340 refused by name, 24 that do not build and 16 wrong. The 24 are this chain with the value appended to where it comes back (`q = f1(x); q << 3`), from 16 methods: the local that takes the value has no type when the rounds stop. Of the 16, 8 are this chain with each callee defined before its caller, nil from 9 methods (another loop's eight rounds), and 8 are chains of 100 methods with `rescue` or `ensure` that end in SystemStackError. 2,590 more chains with each callee defined first keep master's C, all of them.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Arrays, Integers, a String and true)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
