<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`[*v]`, `[0, *v, 9]` and `x, y = *v` took a Range held in a boxed value, or any Enumerator, as one element, and a String Range held in a variable did not build:

```ruby
def lit(v) = [*v]
p lit(3..4), lit([8])   # [3..4] and [8]; CRuby [3, 4] and [8]
e = [4, 5].each
p [*e]                  # [#<Enumerator: ...>]; CRuby [4, 5]
v = ("a".."c")
p [*v]                  # the C compiler stops at "invalid initializer"; CRuby ["a", "b", "c"]
```

All three lower through the poly arm of the array literal. For a boxed operand it tested for a Hash in line and spliced an Array, so a Range or an Enumerator fell through as a single value; it now sends those two kinds, with the Hash, through `sp_splat_to_array`. An operand typed as an Enumerator had no arm and was pushed whole; it now spreads through the same function. A String Range was read as an Integer one unless it was a literal with its bounds in sight; held in a variable it now spreads through `sp_srange_to_a`.

A Range or an Array the compiler knows takes the arm it took before, and a boxed nil, scalar or Array answers as before. A boxed endless Range raises RangeError, as CRuby's splat does; one typed as an Integer Range still answers `[]`, as on master.

One test, `test/splat_range_and_enumerator_into_array_literal.rb`. On master c1d108abe with the pull requests this one depends on, it does not build; with this commit its 73 lines are right, under `SPINEL_GC_STRESS=1` and `=2` too.

**Generated C.** Of the 6,036 programs in `test/`, `benchmark/` and `packages/*/test/`, the C of 6,029 is the same as without this commit. The seven are the new test and six that splat a boxed value into an array literal, where the test of the operand's kind is reworded: `builtin_int_args_splat_runtime_length`, `hash_splat_to_a`, `method_rebound_local_layout`, `return_multi_in_ensure_poly`, `scalar_class_test_reads_nil` and `splat_poly_in_array_literal`. Each prints its `.expected` with and without this commit. One line of optcarrot's generated C changes the same way (the set-up of the opcode dispatch table). Measured on this commit against the one before it, on the master they were written on (08bf767fb), with gcc 13.3 on x86-64 under callgrind: 2,376,701,842 instructions before, 2,376,706,871 after (5,029 more, 0.0002%), checksum 59662 both times.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (one line changed; the numbers are above, checksum 59662)
- [ ] Depends on: #FIRST_SPLAT_PR, #SECOND_SPLAT_PR, #THIRD_SPLAT_PR (the three splat pull requests below this one: the empty array literal, the boxed Range and Enumerator, the Range into a method's arguments)
