<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

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

The loop goes on, by the rule of the pull request this depends on, also in a program where a round began with a method that has its return type from one value while another has none. A nil return type does not count: it is lifted late together with the untyped value, and master is right there.

What this costs: which type the untyped value will have is not known before the rounds run. So a chain whose two values turn out the same type (`return x if x.size > 99; f2(x)`) runs the rounds too. Master is right on it, with the methods past the eighth boxed; here they are typed all the way down, at the cured chain's cost. In CPU seconds of `spinel -c`, each callee defined first:

| methods in the chain | 100 | 200 | 400 | 800 |
|---|---|---|---|---|
| `return 1 if c; f2(x)` over `x = []`: master, 0 from 9 | 0.04 s | 0.07 s | 0.20 s | 0.54 s |
| the same: this | 0.10 s | 0.28 s | 1.32 s | 5.22 s |
| `return x if c; f2(x)`, right on master: master | 0.04 s | 0.07 s | 0.16 s | 0.45 s |
| the same: this, other C | 0.07 s | 0.22 s | 1.25 s | 5.73 s |
| `return f2(x)`: master | 0.02 s | 0.03 s | 0.05 s | 0.14 s |
| the same: this, C identical | 0.02 s | 0.03 s | 0.06 s | 0.15 s |
| `r = f2(x); return r` over `x = [1]`, right on master: master | 0.13 s | 0.34 s | 1.71 s | 11.14 s |

Tests: `test/method_chain_return_mixed_callee_first.rb` has such chains of 9 and 12 methods. Of its seven sections, alone on master, four print 0, one prints the Array as a String, one raises TypeError and one (8 methods, the parameter on the other path, nil on the other path) is right.

Generated C against master, with the two pull requests beneath (`make cident REF=8578e3fb`): `6354 identical, 3 differ, 0 refusal changes` (the three new tests). `tools/refusals.sh` passes (534 records). optcarrot's generated C is byte-identical. Programs, on master 8578e3fb with CRuby 3.3.6 as the reference and the pull request this depends on as the base: 5,310 chains of 3 to 100 methods, 2,590 of them with each callee defined first. 128 are right now, all of 9 methods or more defined callee first: they read the Array through the Integer's type (0 printed for it, or a wrong size after an append). The other 5,182 are the same: 4,676 right, 290 refused by name and 216 wrong, the Hash chains and the chains of 100 methods the pull request this depends on names. Of the 4,676, 16 have other C: the chain that returns its parameter on the other path, from 9 methods.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Arrays and true)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: the pull request "`return r` up 9 methods defined callee first answers the Array, not nil"
