<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A method that stores into its parameter and is handed two kinds of value ran the inference to its 128-round cap. This settles it, at one cost: a program master builds only at the cap can be refused. The smallest found:

```ruby
def put(x, k, v)
  x[k] = v
end
hh = Hash.new
gg = hh
hh[1] = 2
if ARGV.size > 5
  put(gg, "k", "s")
end
p gg["k"]
```

Master builds it only at the cap, under `warning: type inference did not converge in 128 rounds`. It refuses the same program when the last line reads through the other name (`p hh["k"]`), with the message this change gives the ten lines ("a typed Hash is passed to `put`'s parameter `x`, which the method stores keys or values of other types into"), and with 10 of the 11 other reads tried in that place (all but `gg.fetch("k", 0)`). And the binary master builds keeps the Hash Integer-keyed under both names: run with six arguments, so that the call runs, it raises TypeError ("the hash was not widened for this store") where CRuby prints "s". Here the rounds settle in 5 and the program is refused.

Counted around those ten lines, on master b4d30a1d: 9,720 programs (one name or two; the first store, the call and the read each through either name; 12 reads; the call unguarded, guarded and run, guarded and not run; three kinds of first store, three of the call's; `Hash.new` and `{}`), each run with no argument and with six. Master builds 70 at the cap. 15 are right on every run and are right here. 55 are refused here, and each of them raises that TypeError on master whenever its call runs: 44 answer right only on the run where the guard keeps the call out, 11 have no guard. The other 9,650 are as on master: 7,835 with the same C, 1,815 refused by both. None gets a wrong answer or a crash.

The loop itself:

```ruby
def use(x)
  x["a"] = "q" if x
end
h = {"a" => "x"}
use(h)
use(nil)
```

The binding boxes `x` for the two kinds of argument, `infer_param_hash_value` types it String-keyed again from the store in its body, and the next round's binding boxes it again. `param_gets_boxed_arg`, which holds that narrowing back, counted only an argument that is itself boxed.

A boxed parameter now stays boxed where a call by the method's name hands it a typed value of another kind than its store gives: nil, an Integer, a Hash of another kind, by position or by keyword. Where the calls agree in the end (one Hash that a block widens a round after the call first bound it) the parameter takes their variant, as it does with the store written without the block.

Not here: a call the name match does not see still runs to the cap, with master's C: `K.new(h)` for a parameter of `initialize`, `method(:use).call(h)`, a call through an `alias_method` name, `[h].each(&method(:use))`, a keyword handed by `**opts`.

`test/infer/fixpoint_converges.rb` gains the four shapes. Each reaches the cap alone on master, and `make infer-test` fails there with the file as it is here.

On master b4d30a1d: `make cident` reports 6,373 identical, 0 differ. Of 14,448 generated programs with a call by name master reaches the cap in 5,328 and this in none, and all 5,328 build here; the 9,120 that settle on master get the same C in the same rounds. A program that was at the cap can get other C: 993 of the 5,328 type the parameter where the last round had left it boxed, and one master refused there (`$g = h; $g[1] = "s"` beside the store) compiles and is right.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no new test file: `test/infer` files have none and are checked by `make infer-test`; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
