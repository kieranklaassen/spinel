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

That line is in `test/string_format_scalar_operands.rb`, and it raises there with gcc and with clang, the freed list's poisoned header read as frozen. Two more of the tests in the tree answer otherwise than their `.expected` at that level with clang, both exit 0: `packages/benchmark/test/benchmark_tms.rb` prints `0xDB` bytes for its times (`"#{$1}f" % @utime`), and `test/poly_string_dup_unfrozen.rb` prints `"a\xDB\xDBb"`. At `SPINEL_GC_STRESS=0` and `1` I found no freed byte read, the freed format not being taken again before it is read. What is wrong there is the order, with gcc: `"%#{w}d|" % (w += 1)` makes the list first and prints the width the argument wrote.

A format the statement makes itself (an interpolation, a concatenation) now goes into a rooted temporary ahead of the arguments, in each arm that emits the call (`emit_str_format_held`), with the nil check its arm had. It is a String nothing else can name, so it is held beside any argument, and it reads its parts before an argument writes them, as Ruby does.

A call's or a `yield`'s answer is held the same way only beside arguments that run none of the program's code: a read, a literal, arithmetic on numbers, an Array literal of those (`format_arg_is_inert`). The call may have answered a String the argument appends to:

```ruby
$fmt = +"%d"
def held = $fmt
def grow = ($fmt << "|x"; 1)
p held % (grow + 1)          # "2|x"
```

gcc makes the list first, so `grow` has appended by the time `held` is read, and master prints Ruby's line; clang reads `held` first and prints `"2"`. A temporary read ahead of the argument would print `"2"` with both. So beside an argument that runs a call, a `yield` or a write, a call's answer keeps master's C byte for byte (`str_format_left_alone`), and with it the order the C compiler gives the two. A format the statement has already run into a temporary of its own (`fmt(4) % sq(i)`, both of them calls) is left there.

A format something else holds is read where it stands, with master's C (`format_is_held`): a literal; a variable or a constant; an `attr_reader`'s or a Struct member's field (`o.fmt`); an Array's element by an Integer index, its first or its last; a Hash's value; and a choice between two of those (`c ? f : g`, `f || g`). A slot read counts only while the method is the builtin: where the program gives Array or Hash its own `[]`, `first` or `last`, or writes the reader by hand, the answer is a call's, and so is a Hash's value where a Hash of the program has a default block.

The list of a single argument is rooted where that argument is made by something that allocates (`"q" + i.to_s`, a call that answers a String). A single argument that is a read, or arithmetic on reads (`i`, `i + 1`, `i * 0.5`), leaves its list as it was, and so does one the statement already ran into a temporary. An Integer or a Float that runs code (`"%5d|" % sq(i)`, `"%5d|" % (c ? sq(i) : 0)`, a `yield`) is taken into a C temporary ahead of the list instead, boxed there by the call `emit_boxed` wrote for it, and nothing is rooted. In the arm for a list that is already boxed, the format is held only where the list is made in place too.

Cost (callgrind, instructions a statement over 100,000 statements, gcc and clang, on 74fa6d7c2 with the pull request below beneath). The first five were wrong at level 2 before:

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
| `"%5s\|" % lbl(i)`, with `def lbl(i) = i.to_s` | 1,144 to 1,163 | 1,089 to 1,107 |
| `"%8.2f\|" % half(i)`, with `def half(i) = i * 0.5` | 4,662 to 4,664 | 4,613 to 4,614 |
| `"%5d\|" % sq(i)`, with `def sq(i) = i * i` | 1,482 to 1,482 | 1,453 to 1,453 |

Rows six to ten are paid by statements that were right. Where it is held, a call's or a `yield`'s answer is held whether or not the call made the String, and the list of a single String is rooted for any call that answers it, whether or not it allocates. Neither is known where the statement is emitted; `expr_is_held_ref` draws the same line for an object, a call's result counted as fresh. A Float taken ahead of its list is kept across the list's making, two instructions with gcc and one with clang. An Integer a call or a `yield` answers costs nothing, and one out of a conditional (`i > 3 ? sq(i) : 0`) two with gcc and one fewer with clang.

These are the same C before and after: `"%5d|" % i`, `"%5d|" % (i + 1)`, `"%8.2f|" % (i * 0.5)`, `"%5s|" % name`, `"%5d %d|" % ints`, `"%5s %d|" % [name, i]`, a format in a local, `o.fmt % ints`, `o.fmt % i`, `fs[0] % ints`, `h[:k] % ints`, `(i.odd? ? f : g) % ints`, `(i.odd? ? f : g) % [i, 2]`, and four that master runs into temporaries itself: `fl % sq(i)`, `fl % lbl(i)`, `fl % $n`, and `fo.fmt % num(i)` with a reader written by hand.

The generated C of 7 of the 6,598 other programs under `test/`, `benchmark/` and `packages/*/test/` differs (on 74fa6d7c2 with the pull request below beneath), each one with such a statement: the three above, `benchmark_report`, `format_binary`, and the two `yield_operator_diverging_block_types` tests; optcarrot's is byte-identical. The three above pass in every lane with it; the other four answer in every lane as they did.

112 generated statements (the format as a literal, an interpolation, a call's result, a local assigned in place, a concatenation, a conditional and a reader off a new object; sixteen arguments, typed and mixed Arrays, literals, calls, one value of each kind): at `SPINEL_GC_STRESS=2` the base (74fa6d7c2 with the pull request below) answers 40 otherwise than Ruby with gcc (each raises) and 40 with clang (33 print a wrong line and exit 0, 7 raise), 53 with one or the other. With this change all 112 are right at levels 0 and 1. At level 2, 105 are right with gcc and 108 with clang, and none prints a wrong line: the seven left raise as on the base, with the same C (four with both compilers, three with gcc alone). Each of them has a call's answer as its format, directly or through a local written in the statement, a conditional or a reader off a new object, beside an argument that runs a call, a block or a concatenation.

The order is probed in the test. An interpolation reads its variable before an argument writes it: `"%#{w}d|%d" % [(w += 1), 2]`, `"%#{w}d|" % (w += 1)` and `"%#{w}d|%d" % (w += 1; ints)`. A format made from a String is a String of its own, and does not see what an argument then appends to the one it was made from: `"#{sb}" % (grow_s(sb) + 1)` and `(sb + "") % (grow_s(sb) + 1)`. Master prints another line for the last four with gcc, in a plain run. `held % [grow, 2]`, where `grow` appends to the String `held` answers, keeps master's C and its answer, and so does `counted % $n`, where the call that answers the format counts in the global the argument reads.

Fifteen programs put the question of the example above (`held % (grow + 1)`) to the other arms: the argument an Integer, a Float, a String, two conditionals, two typed Arrays and a mixed one, each from a call that appends to the format; a reader written by hand; a `yield`; five of them in a loop. Each is master's C byte for byte. With gcc all fifteen are right at levels 0 and 1, and seven raise at level 2; with clang all fifteen print the format without the append at levels 0 and 1, and the same seven raise at level 2; on master and here alike. They are not in the test, having one answer with gcc and another with clang.

Eleven more programs put the two questions to other formats with an Array literal as the list (a local, a reader, an element, a Hash's value, a call's answer). Five are right on master and here. Six are wrong or raise on master and here alike, in a plain run: an Array literal as the list runs ahead of the format's read (`fs[0] % [fs.shift.size, 2]` prints `"5"` for `"5|2"`), which is master's order and is not touched here. They print the same line in every cell, before and after.

**Not in this change:**

- A call's answer as the format beside an argument that runs code, where master does not run both into temporaries itself: `fmt(4) % ("q" + i.to_s)` prints a wrong line at `SPINEL_GC_STRESS=2` with gcc and raises with clang, on master and here (the same C). The argument is not one this change can show to leave the format's String alone.
- The mirror of the example above, a format whose making has an effect the argument reads: with `def fmtc = ($n += 1; "%d|")`, `fmtc % ($n + 0)` prints 0 for Ruby's 1 with gcc and is right with clang, on master and here (the same C). The two are arguments of one C call, and master leaves their order to the C compiler.
- A single argument that is an Integer on one side of a conditional and a String made in place on the other, `"%5s|" % (c ? i : "s" + i.to_s)`: at `SPINEL_GC_STRESS=2` the String arm prints `0xDB` bytes, with any format, a literal too, on master and here (the same C). The argument is boxed, and it is the box's String that nothing holds.
- `format` and `sprintf`, which pass their arguments another way and are right on master in the fourteen forms tried (on 9c7ea3ce0; not run again).
- A format with named references (`%<a>d` with a Hash), which is taken only as a literal and is refused otherwise.

Test: `test/format_made_in_place_held.rb`, added to `GC_STRESS_TESTS`. On master (74fa6d7c2 with the pull request below) it is right at levels 0 and 1 with clang, and with gcc prints another line for the four named above; at `SPINEL_GC_STRESS=2` it raises at its seventh line with gcc, and with clang prints `0xDB` bytes for its first three lines and its sixth, then raises.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here, built from nothing, on 74fa6d7c2 with the pull request below beneath: the test in the seven collector lanes with gcc and clang, with and without `--share-strings` (right in every one); `ruby tools/gate.rb check`; the generated C of the 6,598 other programs, changed in 7, the five of them under `test/` run in the seven lanes and the two under `packages/` too; optcarrot, checksum 59662; `make share-strings-test` and `make int-min-test`, both pass; the cost table; the 112 statements and the probes above with gcc and clang at levels 0, 1 and 2. Its merge with master 84f5b5020 is clean, with the pull request below in it, and was built from nothing too: the test, the test of the pull request below and the two tests under `test/` named at the top are right there in the seven lanes with gcc and clang, with and without `--share-strings`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: the pull request "An Array a call returns is held while its elements are boxed"

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal`; CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change: byte-identical before and after. It depends on the pull request "An Array a call returns is held while its elements are boxed": this is one commit above it, and the typed Array arm it changes is one of those this one opens.
