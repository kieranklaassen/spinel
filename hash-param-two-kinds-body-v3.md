## What this changes

```ruby
def use(x)
  x["a"] = "q" if x
end
h = {"a" => "x"}
use(h)
use(nil)
```

compiles with `warning: type inference did not converge in 128 rounds`. The binding boxes `x` for the two kinds of argument, `infer_param_hash_value` types it String-keyed again from the store in its body, and the next round's binding boxes it again. `param_gets_boxed_arg`, which holds that narrowing back, counted only an argument that is itself boxed.

A boxed parameter now stays boxed where a call hands it a typed value of another kind than its store gives: nil, an Integer, a Hash of another kind, by position or by keyword. Where the calls agree in the end (one Hash that a block widens a round after the call first bound it) the parameter takes their variant, as it does with the store written without the block.

`test/infer/fixpoint_converges.rb` gains the four shapes. Each reaches the cap alone on master, and `make infer-test` fails there with the file as it is here.

On master dafa0d04: `make cident` reports 6,280 identical, 0 differ. Of 14,448 generated programs of this shape master reaches the cap in 5,328 and this in none; the 9,120 that settle on master get the same C in the same rounds.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no new test file; `test/infer` files have none and are checked by `make infer-test`)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
