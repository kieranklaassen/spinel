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

That line is in `test/string_format_scalar_operands.rb`, and it raises there with gcc and with clang, the freed list's poisoned header read as frozen. Two more of the tests in the tree answer otherwise than their `.expected` at that level with clang, both exit 0: `packages/benchmark/test/benchmark_tms.rb` prints `0xDB` bytes for its times (`"#{$1}f" % @utime`), and `test/poly_string_dup_unfrozen.rb` prints `"a\xDB\xDBb"`. I found no wrong answer at `SPINEL_GC_STRESS=0` or `1`: 200,000 rounds of four such statements, and three programs whose argument allocates forty Strings, answered right with both compilers (run on 2a26683771), the freed format not being taken again before it is read.

A format that may allocate where it is read (`operand_may_allocate`: an interpolation, a call's result, a `yield`) now goes into a rooted temporary ahead of the arguments, in each arm that emits the call (`emit_str_format_held`), with the nil check its arm had. The list of a single argument is rooted where that argument may allocate. In the arm for a list that is already boxed, the format is held only where the list may allocate too.

A statement whose format is a literal, or is read from a variable or a constant, keeps its C but for that root on a single argument's list: the generated C of 7 of the 6,514 programs under `test/`, `benchmark/` and `packages/*/test/` differs (on master 9c7ea3ce0 with the pull request below beneath), each one with such a statement (the three above, `benchmark_report`, `format_binary`, and the two `yield_operator_diverging_block_types` tests); optcarrot's is byte-identical. The three above pass in every lane with it; the other four answer in every lane as they did.

Cost (callgrind, instructions a statement, gcc and clang, on 3ab4539fc with the pull request below beneath):

| statement | gcc | clang |
|---|---|---|
| `"%#{w}d\|" % i` | 1,529 to 1,542 | 1,507 to 1,513 |
| `"%#{w}d %d\|" % ints` | 2,238 to 2,258 | 2,220 to 2,247 |
| `"%#{w}d %s\|" % [i, "x" + i.to_s]` | 2,477 to 2,488 | 2,425 to 2,437 |
| `fmt(4) % i` | 2,014 to 2,021 | 1,995 to 2,014 |
| `"%5s\|" % ("q" + i.to_s)` | 1,617 to 1,635 | 1,573 to 1,587 |

`"%5d|" % i`, `"%5d %d|" % ints`, `"%5s %d|" % [name, i]` and a format in a local are the same C and count the same (within 40 instructions over a run of 100,000 statements). One hold is not needed and is paid: a format that a call or a `yield` returns without making it (`def rem = yield % 3` with the block `{ "%5d|" }`, 1,452 to 1,465 with gcc, 1,428 to 1,437 with clang). `expr_is_held_ref` draws the same line for an object, a call's result counted as fresh. Compiling optcarrot takes 8,347,344,673 instructions before and 8,346,966,901 after.

112 generated statements (the format as a literal, an interpolation, a call's result, a local assigned in place, a concatenation, a conditional and a reader off a new object; sixteen arguments, typed and mixed Arrays, literals, calls, one value of each kind): at `SPINEL_GC_STRESS=2` the base (3ab4539fc with the pull request below) answers 40 otherwise than Ruby with gcc (each raises) and 40 with clang (33 print freed bytes and exit 0, 7 raise), 53 with one or the other. With this change all 112 are right at levels 0, 1 and 2 with both. So is the statement the pull request below names as not in it, `"#{i & 1} #{FMT}" % ints(i)`: its clang build printed freed bytes at that level and is right here in the eight runs, gcc and clang.

**Not in this change:** `format` and `sprintf`, which pass their arguments another way and are right on master in the fourteen forms tried; a format with named references (`%<a>d` with a Hash), which is taken only as a literal and is refused otherwise.

Test: `test/format_made_in_place_held.rb`, added to `GC_STRESS_TESTS`. On master (3ab4539fc) it is right at levels 0 and 1; at `SPINEL_GC_STRESS=2` it raises at its seventh line with gcc, and with clang prints `0xDB` bytes for its first three lines and its sixth, then raises.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit, one above the pull request it depends on, on master 9c7ea3ce0, built from nothing: the test in the seven collector lanes with gcc and clang, with and without `--share-strings` (master raises or prints poisoned bytes at `SPINEL_GC_STRESS=2`; this change is right in every one); `ruby tools/gate.rb check`; the generated C of the 6,514 programs against the commit below, changed in the seven named above, each of them run in the seven lanes; optcarrot, checksum 59662; `make share-strings-test` and `make int-min-test`, both pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal`; CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change: byte-identical before and after. It depends on the pull request "An Array a call returns is held while its elements are boxed": this is one commit above it, and the typed Array arm it changes is one of those this one opens.
