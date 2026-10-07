<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def f9(a)
  a << 2.5
end
def f8(x)
  r = f9(x)
  return r
end
# ... f7 to f1 the same, each defined after the method it calls
x = []
r = f1(x)
p r     # [2.5] in CRuby, nil on master
```

8 methods are right. With an empty Hash filled at the far end, `f1(h)["k"]` crashes the program.

Where each callee is defined before its caller a parameter's type goes down one call a round, and the loop that binds parameters after the inference fixpoint (`infer_param_types` with the write and return re-runs, in `an_phase_method_backstops`) had eight rounds. Past them the local that takes the next method's value had no type. The late lift boxes such a local and gives a method the type of its tail, not of its `return`, so the method compiled to a void function and each caller took nil for the value.

What was chosen: the loop keeps its eight rounds, and goes on only in a program where one of them began with a `return` of a local that has no type. There it runs while the rounds move types, by the rule the fixpoint has (`an_round_cap_step`). Every other program gets master's rounds and master's C: a method none of whose values has a type is boxed whole by the backstops and is right, so a chain of `return f2(x)`, or one ending in the local with no `return`, stays as it is. The rounds cost what they cost the fixpoint, a round a method; in CPU seconds of `spinel -c`, each callee defined first:

| methods in the chain | 100 | 200 | 400 | 800 |
|---|---|---|---|---|
| `r = f2(x); return r` over `x = []`: master, nil from 9 | 0.02 s | 0.05 s | 0.08 s | 0.24 s |
| the same: this | 0.08 s | 0.32 s | 1.20 s | 5.45 s |
| the same chain over `x = [1]`, right on master: master | 0.13 s | 0.34 s | 1.71 s | 11.14 s |
| `return f2(x)`: master | 0.02 s | 0.03 s | 0.05 s | 0.14 s |
| the same: this, C identical | 0.02 s | 0.03 s | 0.08 s | 0.15 s |
| ending in `r`, no `return`: master | 0.02 s | 0.04 s | 0.06 s | 0.15 s |
| the same: this, C identical | 0.02 s | 0.03 s | 0.06 s | 0.19 s |

Defined caller first, the chain the pull request this depends on cures keeps its C. Its rounds are run by this loop now, which binds parameters in each: 800 methods take 3.05 s for the 2.40 s they take there.

Tests: `test/method_chain_return_local_callee_first.rb` has such chains of 9 to 30 methods over an Array and a Hash. Of its six sections, alone on master, two print nil, one does not build, one raises NoMethodError, one crashes and one (8 methods, and 12 ending in the local with no `return`) is right.

Generated C against master, with the pull request this depends on beneath (`make cident REF=8578e3fb`): `6354 identical, 2 differ, 0 refusal changes` (the two new tests). `tools/refusals.sh` passes (534 records). optcarrot's generated C is byte-identical. Programs, on master 8578e3fb with CRuby 3.3.6 as the reference and the pull request this depends on as the base: 5,310 chains of 3 to 100 methods, 2,590 of them with each callee defined first. 700 are right now: 472 that lost the value (nil printed, or NoMethodError or TypeError raised on it), 104 that did not build and 124 that were refused (100 an empty Hash filled at the far end, refused by name from 8 methods; 24 the value used as a condition). The other 4,610 are the same: 3,976 right, each with the C it had, 290 refused by name and 344 wrong. Of the 344, 128 have an Integer on another path of each method and read the Array through it, 192 are an empty Hash handed down 9 methods or more defined callee first, which raises TypeError at the store, 7 print nil where a `rescue` modifier takes that TypeError, and 17 are chains of 100 methods with `rescue` or `ensure` that end in SystemStackError.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Arrays, Integers, a String and true)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: the pull request "`return r` up a chain of 16 methods answers the Array, not nil"
