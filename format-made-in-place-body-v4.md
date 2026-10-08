<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** `fmt % args` is emitted as one C call, `sp_str_format_polyarr(FORMAT, LIST)`, and both arguments can be made on the spot: a format written as an interpolation or returned by a call, and a list boxed from a typed Array, built from a literal, or made to carry a single argument. Nothing holds the one made first while the other is made, and C does not say which is first: clang makes the format first, gcc the list.

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

That line is in `test/string_format_scalar_operands.rb`, and it raises there with gcc and with clang, the freed list's poisoned header read as frozen. Two more of the tests in the tree answer otherwise than their `.expected` at that level with clang, both exit 0: `packages/benchmark/test/benchmark_tms.rb` prints `0xDB` bytes for its times (`"#{$1}f" % @utime`), and `test/poly_string_dup_unfrozen.rb` prints `"a\xDB\xDBb"`. I found no wrong answer at `SPINEL_GC_STRESS=0` or `1`: the programs below are all right at those levels on master, the freed format not being taken again before it is read.

A format made where it is written (an interpolation, a concatenation, a call's or a `yield`'s answer) now goes into a rooted temporary ahead of the arguments, in each arm that emits the call (`emit_str_format_held`), with the nil check its arm had. The list of a single argument is rooted where that argument is made by something that allocates (`"q" + i.to_s`, a call). In the arm for a list that is already boxed, the format is held only where the list is made in place too.

A format something else holds is read where it stands, with master's C (`format_is_held`): a literal; a variable or a constant; an `attr_reader`'s or a Struct member's field (`o.fmt`); an Array's element by an Integer index, its first or its last; a Hash's value; and a choice between two of those (`c ? f : g`, `f || g`). A slot read counts only while the method is the builtin: where the program gives Array or Hash its own `[]`, `first` or `last`, or writes the reader by hand, the answer is a call's and is held, and so is a Hash's value where a Hash of the program has a default block. A single argument that is a read, or arithmetic on reads (`i`, `i + 1`, `i * 0.5`), leaves its list as it was.

Cost (callgrind, instructions a statement over 100,000 statements, gcc and clang, on 0e8befeb3 with the pull request below beneath). The first five were wrong at level 2 before:

| statement | gcc | clang |
|---|---|---|
| `"%#{w}d\|" % i` | 1,529 to 1,542 | 1,507 to 1,513 |
| `"%#{w}d %d\|" % ints` | 2,238 to 2,258 | 2,220 to 2,247 |
| `"%#{w}d %s\|" % [i, "x" + i.to_s]` | 2,477 to 2,488 | 2,425 to 2,437 |
| `fmt(4) % i` | 2,014 to 2,021 | 1,995 to 2,014 |
| `"%5s\|" % ("q" + i.to_s)` | 1,617 to 1,635 | 1,573 to 1,587 |
| `fl % ints`, with `def fl = "%5d %d\|"` | 2,165 to 2,186 | 2,136 to 2,154 |
| `fh % ints`, with `def fh = $f` | 2,169 to 2,185 | 2,136 to 2,154 |
| `yield % 3`, with the block `{ "%5d\|" }` | 1,452 to 1,465 | 1,428 to 1,437 |
| `"%5d\|" % sq(i)`, with `def sq(i) = i * i` | 1,482 to 1,495 | 1,453 to 1,480 |

The last four are paid by statements that were right: a call's or a `yield`'s answer is held whether or not the call made the String, and the list of a single argument is rooted for any call, whether or not it allocates. Neither is known where the statement is emitted; `expr_is_held_ref` draws the same line for an object, a call's result counted as fresh.

These are the same C before and after, and count the same to the instruction: `"%5d|" % i`, `"%5d|" % (i + 1)`, `"%8.2f|" % (i * 0.5)`, `"%5s|" % name`, `"%5d %d|" % ints`, `"%5s %d|" % [name, i]`, a format in a local, `o.fmt % ints`, `o.fmt % i`, `fs[0] % ints`, `h[:k] % ints`, `(i.odd? ? f : g) % ints` and `(i.odd? ? f : g) % [i, 2]`.

The generated C of 7 of the 6,565 other programs under `test/`, `benchmark/` and `packages/*/test/` differs (on master 0e8befeb3 with the pull request below beneath), each one with such a statement: the three above, `benchmark_report`, `format_binary`, and the two `yield_operator_diverging_block_types` tests; optcarrot's is byte-identical. The three above pass in every lane with it; the other four answer in every lane as they did.

112 generated statements (the format as a literal, an interpolation, a call's result, a local assigned in place, a concatenation, a conditional and a reader off a new object; sixteen arguments, typed and mixed Arrays, literals, calls, one value of each kind): at `SPINEL_GC_STRESS=2` the base (74fa6d7c2 with the pull request below) answers 40 otherwise than Ruby with gcc (each raises) and 40 with clang (33 print a wrong line and exit 0, 7 raise), 53 with one or the other. With this change all 112 are right at levels 0, 1 and 2 with both.

Two probes of the order are in the test: a format held ahead of its arguments is the String they change in place (`held % [grow, 2]`, where `grow` appends to the String `held` answers), and an interpolation reads its variable before an argument writes it (`"%#{w}d|%d" % [(w += 1), 2]`). Eleven more programs put the same two questions to other formats (a local, a reader, an element, a Hash's value, a call's answer). Five are right on master and here. Six are wrong or raise on master and here alike, in a plain run: an Array literal as the list runs ahead of the format's read (`fs[0] % [fs.shift.size, 2]` prints `"5"` for `"5|2"`), which is master's order and is not touched here. They print the same line in every cell but one: at level 2 with clang one of them printed freed bytes on master and prints its plain-run line here.

**Not in this change:**

- A single argument that is an Integer on one side of a conditional and a String made in place on the other, `"%5s|" % (c ? i : "s" + i.to_s)`: at `SPINEL_GC_STRESS=2` the String arm prints `0xDB` bytes, with any format, a literal too, on master and here (the same C). The argument is boxed, and it is the box's String that nothing holds.
- `format` and `sprintf`, which pass their arguments another way and are right on master in the fourteen forms tried (on 9c7ea3ce0; not run again).
- A format with named references (`%<a>d` with a Hash), which is taken only as a literal and is refused otherwise.

Test: `test/format_made_in_place_held.rb`, added to `GC_STRESS_TESTS`. On master (0e8befeb3 and 74fa6d7c2) it is right at levels 0 and 1; at `SPINEL_GC_STRESS=2` it raises at its seventh line with gcc, and with clang prints `0xDB` bytes for its first three lines and its sixth, then raises.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here, built from nothing, on two masters, each with the pull request below beneath. On 0e8befeb3: the test in the seven collector lanes with gcc and clang, with and without `--share-strings` (right in every one); `ruby tools/gate.rb check`; the generated C of the 6,565 programs, changed in 7, each of them run; optcarrot, checksum 59662; `make share-strings-test` and `make int-min-test`, both pass. The test's two probe lines and one comment's wording came after the corpus and the two legs; the test's lanes were run again with them. On 74fa6d7c2, where this commit is the same change replayed (the same patch but for the place of its line in the Makefile's list): the build, the test in the seven lanes with gcc and clang, with and without `--share-strings`, `ruby tools/gate.rb check`, and the 112 statements above.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: the pull request "An Array a call returns is held while its elements are boxed"

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal`; CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change: byte-identical before and after. It depends on the pull request "An Array a call returns is held while its elements are boxed": this is one commit above it, and the typed Array arm it changes is one of those this one opens.
