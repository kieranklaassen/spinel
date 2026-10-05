## What this changes

```ruby
def use(x)
  x["a"] = "q" if x
end
h = {"a" => "x"}
use(h)
use(nil)
```

compiled with `warning: type inference did not converge in 128 rounds`. The binding boxes `x` for the two kinds of argument, `infer_param_hash_value` types it String-keyed again from the store in its body, and the next round's binding boxes it again. `param_gets_boxed_arg`, which holds that narrowing back, counted only an argument that is itself boxed.

The same happens with an Integer, a Hash of another kind or a literal of one in the second call, with a keyword parameter, and with a single call whose Hash a block widens a round after the call first bound it:

```ruby
def use(x) = x["a"] = "q"
h = {"a" => "x"}
[1].each { |k| h[k] = "s" }
use(h)
```

A boxed parameter now stays boxed where a call hands it a typed value of another kind than its store gives. Where the calls agree in the end, as in the second program, the parameter takes their variant (`sp_PolyPolyHash *`), as it already did with the store written without the block.

`test/infer/fixpoint_converges.rb` gains the four shapes. Each reaches the cap alone on master, and `make infer-test` fails there with the file as it is here.

### Measured

On master c2dadf49, against CRuby 3.3.6, plain and under `SPINEL_GC_STRESS=1` and `2`:

- 14,448 generated programs: a Hash of seven kinds, widened or not by a store, a block, `merge!` or a method, handed to a method that stores into its parameter (eight forms), once, twice, beside a second Hash or beside a literal. On master 5,328 reach the cap; here none does, and they settle in 4 to 6 rounds.
- The 9,120 that settle on master get the same C in the same number of rounds.
- Of the 5,328, 4,335 get the C master wrote at the cap. The other 993 type the parameter where master boxed it: all 993 are right in the three runs, here and on master.
- Four more sets with a second name for the Hash and other callees (21,837 programs): master has 648 at the cap, here none. 126 of those get a typed parameter and are right in the three runs on both sides; every program that settles on master gets the same C in the same rounds.
- Eight programs with a keyword parameter: five at the cap on master, none here. Two of them raise TypeError at run time on master and here (below).
- `make cident REF=c2dadf49`: 6,129 identical, 0 differ, 0 refusal changes (tests, benchmarks and packages). Of the tests, `test/ptr_array_set_poly_value.rb` reaches the cap on master and here, for another reason.
- Compile time: a 1,043-line test with the second program appended takes 1.44 s on master and 0.22 s here; the test alone costs 1,820,353,777 instructions on master and 1,820,353,741 here (callgrind).
- `ruby tools/order_probe.rb test/infer/fixpoint_converges.rb`: 0 findings.
- Replayed on master 9c4eec71 (no conflict): with the file as it is here, `make infer-test` fails on that master at 128 rounds and passes on this commit at 6; `make cident REF=9c4eec71`: 6,135 identical, 0 differ, 0 refusal changes.

### Not changed

A keyword parameter that stores into a Hash of another kind than its first caller's still raises at run time, on master and here; the positional form widens the caller's Hash and is right:

```ruby
def use(x:) = x["a"] = "q"
h = {"a" => "x"}
k = {"c" => 3}
use(x: h)
use(x: k)   # TypeError: cannot store a String key with a String value into a hash Spinel typed as String-keyed with Integer values
```

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no new test file; the shapes are added to `test/infer/fixpoint_converges.rb`, which has none)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
