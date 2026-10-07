<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A fix with a cost, which is yours to weigh: a chain that returns its parameter on one path (`return x if c; f2(x)`), each callee defined first, is right on master and compiles there in 0.03, 0.07, 0.20 and 0.43 s at 100, 200, 400 and 800 methods. Here it takes 0.07, 0.36, 1.30 and 5.74 s, to other C that is right too. The pull request this depends on stands without this one.

```ruby
def f9(a)
  a << 2.5
end
def f8(x)
  return 1 if x.size > 99
  f9(x)
end
# ... f7 to f1 the same, each defined after the method it calls
x = []
r = f1(x)
p r     # [2.5] in CRuby, 0 on master
```

8 methods are right. With a String on the other path `p r` prints `"[2.5]"`, a String; with a Float the program raises TypeError.

Where each callee is defined before its caller a parameter's type goes down one call a round, and the loop that binds parameters after the inference fixpoint had eight rounds. Past them a method had its return type from the Integer alone, its caller's local took that type, and the value the backstops box later was read through it.

The loop goes on, by the rule of the pull request this depends on, also while a round begins with a method that has its return type from one value while another has none. A nil return type does not count: it is lifted late together with the untyped value, and master is right there.

Why the cost: which type the untyped value will have is not known before the rounds run. A chain whose two values turn out the same type looks, when the eighth round ends, like the one that answers 0, so it runs the rounds too. Master is right on it, with the methods past the eighth boxed; here they are typed all the way down, at the cured chain's cost. In CPU seconds of `spinel -c`, each callee defined first:

| methods in the chain | 100 | 200 | 400 | 800 |
|---|---|---|---|---|
| `return 1 if c; f2(x)` over `x = []`: master, 0 from 9 | 0.05 s | 0.08 s | 0.16 s | 0.46 s |
| the same: this | 0.07 s | 0.28 s | 1.26 s | 5.28 s |
| `return x if c; f2(x)`, right on master: master | 0.03 s | 0.07 s | 0.20 s | 0.43 s |
| the same: this, other C | 0.07 s | 0.36 s | 1.30 s | 5.74 s |
| `return f2(x)`: master | 0.01 s | 0.03 s | 0.05 s | 0.11 s |
| the same: this, C identical | 0.02 s | 0.03 s | 0.08 s | 0.12 s |
| ending in `r`, no `return`, beside 9 methods of `return 1 if c; g2(x)`: master | 0.03 s | 0.05 s | 0.06 s | 0.18 s |
| the same: this | 0.02 s | 0.05 s | 0.09 s | 0.17 s |
| `r = f2(x); return r` over `x = [1]`, right on master: master | 0.12 s | 0.35 s | 2.24 s | 11.55 s |

Tests: `test/method_chain_return_mixed_callee_first.rb` has such chains of 9 and 12 methods. Of its seven sections, alone on master, four print 0, one prints the Array as a String, one raises TypeError and one (8 methods, the parameter on the other path, nil on the other path) is right.

Generated C against master, with the two pull requests beneath (`make cident REF=4f8b737c`): `6407 identical, 3 differ, 0 refusal changes` (the three tests). `tools/refusals.sh` passes (536 records). optcarrot's generated C is byte-identical. Programs of ours, on master 4f8b737c with CRuby 3.3.6 as the reference and the pull request this depends on as the base: 5,310 chains of 3 to 100 methods, 2,590 of them with each callee defined first. 128 are right now, all of 9 methods or more defined callee first: they read the Array through the Integer's type (0 printed for it, or a wrong size after an append). The other 5,182 are the same: 4,667 right, 299 refused by name and 216 wrong, the Hash chains and the chains of 100 methods the pull request this depends on names. Of the 4,667, 16 have other C: the chains that return their parameter on the other path, from 9 methods.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Arrays and true)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: the pull request "`return r` up 9 methods defined callee first answers the Array, not nil"
