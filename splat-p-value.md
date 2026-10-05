<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Where the value of `p` is used, a splat among its arguments was taken as one argument, with nothing said:

```ruby
one = [8]
x = p(*one)           # printed [8], x held an address; CRuby prints 8, x is 8
def last(v) = p(*v)
last([8, 9])          # printed [8, 9]; CRuby prints 8 and 9
x = p(0, *one)        # printed 0 and [8], x was [0, [8]]; CRuby 0, 8 and [0, 8]
```

The call was typed by the Array's element. With the Array written in place, `x = p(*[8])`, the answer was right.

As a value, `p` with one argument answers it and `p` with several answers their array, and both arms took a splat as one argument. How many arguments a splat gives is known only at run time, so a call with one among them now has its own arm (`emit_p_splat_value`): the arguments are gathered, a splat through `sp_splat_to_array`, each is printed, and the answer is nil for none, the argument for one and the array for more. Such a call is typed as a boxed value.

A call with no splat takes the arms it took before.

One test, `test/p_value_with_splat_argument.rb`. On master c1d108abe with the pull requests this one depends on, 51 of its 72 lines are missing or wrong; with this commit all 72 are right, under `SPINEL_GC_STRESS=1` and `=2` too. Of the 6,038 programs in `test/`, `benchmark/` and `packages/*/test/`, the generated C of 6,037 is the same as without this commit; the one that differs is the new test.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (CRuby 4.0.7 with that flag prints exactly the test's `.expected`)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical, compared at 08bf767fb where this commit was written)
- [ ] Depends on: #FIRST_SPLAT_PR, #SECOND_SPLAT_PR, #THIRD_SPLAT_PR, #FOURTH_SPLAT_PR, #FIFTH_SPLAT_PR (the five splat pull requests below this one)
