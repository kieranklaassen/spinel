<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`fmt % args` is emitted as one C call, `sp_str_format_polyarr(FORMAT, LIST)`, and both arguments can be made on the spot: a format written as an interpolation or returned by a call, and a list boxed from a typed Array, built from a literal, or made to carry a single argument. Nothing holds the one made first while the other is made, and C does not say which is first: clang makes the format first, gcc the list.

```ruby
def fmt(w) = "%" + w.to_s + "d %d|"
ints = [3, 4]
p fmt(4) % ints              # "   3 4|"
```

At `SPINEL_GC_STRESS=2` with clang the copy of `ints` into a boxed list collects the format, and the line prints seven `0xDB` bytes and exits 0; with gcc the call collects the list, and the line raises "too few arguments (ArgumentError)". With an interpolation, `"%#{w}d %d|" % ints`, clang prints the same seven bytes.

The one-element list a single argument goes into is held by nothing either while that argument is built, whichever the compiler:

```ruby
p("%.2f" % (1r/3))           # can't modify frozen Array (FrozenError)
```

That line is in `test/string_format_scalar_operands.rb`, and it raises there with gcc and with clang, the freed list's poisoned header read as frozen. Two more of the tests in the tree answer otherwise than their `.expected` at that level with clang, both exit 0: `packages/benchmark/test/benchmark_tms.rb` prints `0xDB` bytes for its times (`"#{$1}f" % @utime`), and `test/poly_string_dup_unfrozen.rb` prints `"a\xDB\xDBb"`. I found no wrong answer at `SPINEL_GC_STRESS=0` or `1`: 200,000 rounds of four such statements, and three programs whose argument allocates forty Strings, answer right with both compilers, the freed format not being taken again before it is read.

A format that may allocate where it is read (`operand_may_allocate`: an interpolation, a call's result, a `yield`) now goes into a rooted temporary ahead of the arguments, in each arm that emits the call (`emit_str_format_held`), with the nil check its arm had. The list of a single argument is rooted where that argument may allocate. In the arm for a list that is already boxed, the format is held only where the list may allocate too.

A statement whose format is a literal, or is read from a variable or a constant, keeps its C but for that root on a single argument's list: the generated C of 8 of the 6,419 programs under `test/`, `benchmark/` and `packages/*/test/` differs, the new test and seven that have such a statement (the three above, `benchmark_report`, `format_binary`, and the two `yield_operator_diverging_block_types` tests); optcarrot's is byte-identical.

Cost (callgrind, instructions a statement, gcc and clang, on 2a26683771 with the pull request below beneath):

| statement | gcc | clang |
|---|---|---|
| `"%#{w}d\|" % i` | 1,534 to 1,547 | 1,512 to 1,521 |
| `"%#{w}d %d\|" % ints` | 2,243 to 2,264 | 2,231 to 2,248 |
| `"%#{w}d %s\|" % [i, "x" + i.to_s]` | 2,482 to 2,493 | 2,431 to 2,444 |
| `fmt(4) % i` | 2,019 to 2,027 | 1,998 to 2,022 |
| `"%5s\|" % ("q" + i.to_s)` | 1,623 to 1,641 | 1,568 to 1,594 |

`"%5d|" % i`, `"%5d %d|" % ints`, `"%5s %d|" % [name, i]` and a format in a local count the same to the instruction. One hold is not needed and is paid: a format that a call or a `yield` returns without making it (`def rem = yield % 3` with the block `{ "%5d|" }`, 1,457 to 1,470). `expr_is_held_ref` draws the same line for an object, a call's result counted as fresh. Compiling optcarrot takes 8,113,125,888 instructions before and 8,113,037,512 after.

112 generated statements (the format as a literal, an interpolation, a call's result, a local assigned in place, a concatenation, a conditional and a reader off a new object; sixteen arguments, typed and mixed Arrays, literals, calls, one value of each kind): at `SPINEL_GC_STRESS=2` the base (2a26683771 with the pull request below) answers 40 otherwise than Ruby with gcc (each raises) and 40 with clang (33 print freed bytes and exit 0, 7 raise), 53 with one or the other. With this change all 112 are right at levels 0, 1 and 2 with both.

**Not in this change:** `format` and `sprintf`, which pass their arguments another way and are right on master in the fourteen forms tried; a format with named references (`%<a>d` with a Hash), which is taken only as a literal and is refused otherwise.

Test: `test/format_made_in_place_held.rb`, added to `GC_STRESS_TESTS`. On master it is right at levels 0 and 1; at `SPINEL_GC_STRESS=2` it raises at its seventh line with gcc, and with clang prints `0xDB` bytes for its first three lines and its sixth, then raises.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after)
- [ ] Depends on: # (the pull request "An Array a call returns is held while its elements are boxed": this is one commit above it, and the typed Array arm it changes is one of those this one opens)
