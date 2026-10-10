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
p("%.2f" % (1r/3))
```

That line is in `test/string_format_scalar_operands.rb`, and it raises there, "can't modify frozen Array (FrozenError)", with gcc and with clang, the freed list's poisoned header read as frozen. Two more of the tests in the tree answer otherwise than their `.expected` at that level with clang, both exit 0: `packages/benchmark/test/benchmark_tms.rb` prints `0xDB` bytes for its times (`"#{$1}f" % @utime`), and `test/poly_string_dup_unfrozen.rb` prints `"a\xDB\xDBb"`. At `SPINEL_GC_STRESS=0` and `1` I found no freed byte read, the freed format not being taken again before it is read. What is wrong there is the order, with gcc: `"%#{w}d|" % (w += 1)` makes the list first and prints the width the argument wrote.

A format the statement makes itself (an interpolation, a concatenation) now goes into a rooted temporary ahead of the arguments, in each arm that emits the call (`emit_str_format_held`), with the nil check its arm had. It is a String nothing else can name, so it is held beside any argument, and it reads its parts before an argument writes them, as Ruby does. An interpolation counts as made here only where it has a part to evaluate and its parts show a new String: one of them is a literal that is not empty (`"#{s}|"`), or it has one part alone and that part is embedded (`"#{s}"`). Ruby answers the embedded String itself for `"#{s}#{""}"`, so every other interpolation keeps master's C. One of literal parts alone (`"%d " "%d|"`, a squiggly heredoc whose lines indent differently) has nothing to evaluate: master folds it into one literal, and it is read as a literal is.

A call's or a `yield`'s answer is held the same way only beside arguments that run none of the program's code: a read, a literal, arithmetic on numbers, an Array literal of those; an index or an operator only while it is the builtin's (`format_arg_is_inert`). The call may have answered a String the argument appends to:

```ruby
$fmt = +"%s"
def held = $fmt
def grow = ($fmt << "|x"; "a")
p held % (grow + "b")        # "ab|x"
```

gcc makes the list first, so `grow` has appended by the time `held` is read, and master prints Ruby's line; clang reads `held` first and prints `"ab"`. A temporary read ahead of the argument would print `"ab"` with both. So beside an argument that runs a call, a `yield` or a write, a call's answer keeps master's C byte for byte (`str_format_left_alone`), and with it the order master gives the two. A format the statement has already run into a temporary of its own is left there: `fmt(4) % sq(i)`, both of them calls, and beside a number in parentheses, `held % (grow + 1)`, where master reads the format first itself and prints `"2"` for Ruby's `"2|x"`, with gcc and with clang, on master and here.

An index or an operator in the argument counts as the builtin's only where that can be shown (`format_name_is_builtin`), and the showing is master's (`an_prog_never_gives`), asked by the name alone, whatever the class. It reads the program as the parser wrote it: no `def` and no Symbol of that name anywhere; nothing that names, makes or loads a method by something the text does not spell (a `send` or a `define_method` of a computed name, an eval, a `&` handed a value); no module mixed in; and no file the compiler did not read. A reader in the argument is never shown: its name is the Symbol its `attr_reader` is given, or a `def`. An operator counts only where its operand is a number or a boolean by its type: an Integer's `>` hands any other operand to that operand's own `coerce`. Otherwise the argument may run the program's code:

```ruby
$fmt = +"%.1f"
class Float
  def +(o) = ($fmt << "|x"; 7.5)
end
def held = $fmt
f = 1.5
p held % (f + 1.0)           # "7.5|x"
```

Master's list of plain reads takes `f + 1.0` for one by the types alone. Here the statement keeps master's C, and its answer: Ruby's line with gcc and `"7.5"` with clang at levels 0 and 1, and a stop by the collector's own check (exit 134) at level 2 with both. A concatenation is the statement's own only while `+` passes the same test.

A format something else holds is read where it stands, with master's C (`format_is_held`): a literal, and an interpolation of literal parts alone (`interp_is_literal_fold`, the test master's `emit_interp` folds on); a variable or a constant; an `attr_reader`'s or a Struct member's field (`o.fmt`); an Array's element by an Integer index, its first or its last; a Hash's value; and a choice between two of those (`c ? f : g`, `f || g`). A variable or a constant that is read as a copy is not held (master's `operand_may_allocate` says which reads those are: a String two names hold, and with `--share-strings` a global or a constant changed in place): the copy is a String made where it is written, and is held as a call's answer is. With `KF = +"%5d"` and `KF << "|"`, `KF % i` was wrong in 300 rounds of 300 at `SPINEL_GC_STRESS=2` under `--share-strings` built with clang; built with gcc it was right, and pays 13 instructions a statement for the hold (19 with clang). A slot read counts only while the method is the builtin: where the program gives Array or Hash its own `[]`, `first` or `last`, or writes the reader by hand, the answer is a call's, and so is a Hash's value where a Hash of the program has a default block.

The list of a single argument is rooted where that argument is made by something that allocates (`"q" + i.to_s`, a call that answers a String). A single argument that is a read, or arithmetic on reads (`i`, `i + 1`, `i * 0.5`), leaves its list as it was, and so does one the statement already ran into a temporary. An Integer or a Float that runs code (`"%5d|" % sq(i)`, `"%5d|" % (c ? sq(i) : 0)`, a `yield`) is taken into a C temporary ahead of the list instead, boxed there by the call `emit_boxed` wrote for it, and nothing is rooted. In the arm for a list that is already boxed, the format is held only where the list is made in place too.

Cost (callgrind, instructions a statement over 100,000 statements, gcc and clang; measured on master 74fa6d7c2 with the boxed-Array change master has since merged). The first five were wrong at level 2 before:

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

The generated C of 7 of the 6,809 other programs under `test/`, `benchmark/` and `packages/*/test/` differs (on master 82cfb601d), each one with such a statement: the three above, `benchmark_report`, `format_binary`, and the two `yield_operator_diverging_block_types` tests; optcarrot's is byte-identical. The three above pass in every lane with it; the other four answer in every lane as they did.

112 generated statements (the format as a literal, an interpolation, a call's result, a local assigned in place, a concatenation, a conditional and a reader off a new object; sixteen arguments, typed and mixed Arrays, literals, calls, one value of each kind): at `SPINEL_GC_STRESS=2` master (82cfb601d) answers 40 otherwise than Ruby with gcc (33 raise, 7 are stopped by the collector's own check, exit 134) and 40 with clang (33 print a wrong line and exit 0, 7 are stopped by that check), 53 with one or the other. With this change all 112 are right at levels 0 and 1. At level 2, 105 are right with gcc and 108 with clang, and none prints a wrong line: the seven left end as on master, with the same C (four stopped by that check with both compilers, three that raise with gcc alone). Each of them has a call's answer as its format, directly or through a local written in the statement, a conditional or a reader off a new object, beside an argument that runs a call, a block or a concatenation.

The order is probed in the test. An interpolation reads its variable before an argument writes it: `"%#{w}d|%d" % [(w += 1), 2]`, `"%#{w}d|" % (w += 1)` and `"%#{w}d|%d" % (w += 1; ints)`. A format made from a String is a String of its own, and does not see what an argument then appends to the one it was made from: `"#{sb}" % (grow_s(sb) + 1)`, `"#{sb}|" % (grow_s(sb) + 1)` and `(sb + "") % (grow_s(sb) + 1)`. Master prints another line with gcc, in a plain run, for the last five but `(sb + "") % (grow_s(sb) + 1)`. `held % [grow, 2]`, where `grow` appends to the String `held` answers, keeps master's C and its answer, and so does `counted % $n`, where the call that answers the format counts in the global the argument reads.

Fifteen programs put the question of the example above to the other arms: the argument an Integer, a Float, a String, two conditionals, two typed Arrays and a mixed one, each from a call that appends to the format; a reader written by hand; a `yield`; five of them in a loop. Each is master's C byte for byte, and answers as on master in every cell. Thirteen print the format without the append at every level, with gcc and with clang: master reads the format into a temporary of its own ahead of such an argument. The two whose argument is a String are right with gcc and print the format without the append with clang at levels 0 and 1, and with either compiler are stopped by the collector's own check at level 2. They are not in the test, having other answers than Ruby's.

Thirty programs put the program's own method under such an argument, by each way of defining one: a `def` of `[]` on Array (under Integer and Float arithmetic, with a `yield` as the format, and alone), of `+`, `-`, `*` and `/` on Float, of `+` on Integer, of `&` on `true`, and of `==` on Integer under `!=`; an `alias` and an `alias_method` on Array and on Float; `define_method` with a literal name and with a computed one; a module prepended in the class's body; a singleton `def`; a subclass of Array; a module the Array is extended with; a reader given another body by a `def` and by `alias_method`; String's `+` by a `def` and by `alias_method`; and `Array.define_method`, `Array.prepend`, `Array.send(:define_method, ...)`, `Array.class_eval` and `Array.alias_method`, each rescued. Twenty-nine are master's C byte for byte and answer as on master in every cell, gcc and clang; the extended one does not build, on master or here. Four more look from the other side, and are right with master's C: the builtin's index, a reader, `t + i` in a program that says `inject(:+)`, and `v.x + i` beside a `def` of `+` in a class of the program's own, far from the argument: the name is asked as the program writes it, a Symbol or a `def`, whatever the class.

Eleven more programs put the two questions to other formats with an Array literal as the list (a local, a reader, an element, a Hash's value, a call's answer). Five are right on master and here. Six are wrong or raise on master and here alike, in a plain run: an Array literal as the list runs ahead of the format's read (`fs[0] % [fs.shift.size, 2]` prints `"5"` for `"5|2"`), which is master's order and is not touched here. They print the same line in every cell, before and after, but one: `f % [$n, 2]`, with `def f = ($n += 1; "%d|" + "%d")`, prints `0xDB` bytes on master at level 2 with clang and its plain run's line here.

Sixteen programs have a format of literal parts alone: two or three adjacent literals, one of them empty, a squiggly heredoc of mixed indents, such a format as one side of a choice and of an `||`; beside a typed Array, an Integer, arithmetic, an Array literal, a write, a String made in place and a call's number. Eleven are master's C byte for byte. The five whose argument is a String made in place or a call's Integer or Float differ as the same statement does with its format written as one literal. Thirteen of the sixteen were written that way too, and the C of each pair is the same, on master and here. All sixteen are right in every cell here. Eight more put a part to evaluate among the literals (`"%#{w}d " "%d|"`, a heredoc with one, a concatenation): they are held ahead as before.

**Not in this change:**

- A call's answer as the format beside an argument that runs code, where master does not run both into temporaries itself: `fmt(4) % ("q" + i.to_s)` prints `0xDB` bytes or is stopped by the collector's own check (exit 134) at `SPINEL_GC_STRESS=2`, with gcc and with clang, on master and here (the same C). The argument is not one this change can show to leave the format's String alone.
- The index alone as the argument, under the program's own `Array#[]` (`class Array; def [](i) = ($fmt << "|x"; 7); end`): `held % ar[0]` prints `"7"` for `"7|x"` with gcc and with clang, on master and here (the same C).
- An argument with an index or an operator the proof does not show to be the builtin's, any reader, and an operator whose operand is no number or boolean by its type: the statement keeps master's C, and where master was wrong it still is. That is a program with a `def` or a Symbol of the name anywhere (`inject(:+)` beside a `+`), one that names a method by a value, and one that mixes a module in.
- An interpolation that is not shown to be a new String by its parts: `"#{s}#{""}"` is `s` itself in Ruby, and `"#{""}#{s}"`, `"#{s}#{nil}"` and `"#{s}#{t}"`, which are new Strings, are not told apart from it. With `s = +"a%d"` and an argument that appends `"!"` to `s`, `"#{""}#{s}" % bump(s)` prints `"a1!"` for Ruby's `"a1"` with gcc, on master and here (the same C).
- The mirror of the example above, a format whose making has an effect the argument reads: with `def fmtc = ($n += 1; "%d|")`, `fmtc % ($n + 0)` prints 0 for Ruby's 1 with gcc and is right with clang, on master and here (the same C). The two are arguments of one C call, and master leaves their order to the C compiler.
- A single argument that is an Integer on one side of a conditional and a String made in place on the other, `"%5s|" % (c ? i : "s" + i.to_s)`: at `SPINEL_GC_STRESS=2` the String arm prints `0xDB` bytes, with any format, a literal too, on master and here (the same C). The argument is boxed, and it is the box's String that nothing holds.
- A `def` or a Symbol of the name in the arm of a `RUBY_ENGINE` test the compiler drops: the program is read as it is written, the name counts, and the statement keeps master's C and its answer. An interpolation as the format is held ahead whatever its argument, in the order of the program as compiled: with `Array#[]` defined in such an arm and `def bump = ($ar[0] = 9; 5)`, `"%#{bump}d|" % (ar[k] + i * m)` prints `"   15|"` here and with clang on master; master with gcc made the list first and printed `"    7|"`, the line of CRuby, which runs the arm.
- A program that may load a file the compiler did not read (a `require` it warns about and ignores, one under a `RUBY_ENGINE` test it drops, a changed `$LOAD_PATH`, a `load`): nothing in it is shown to be the builtin's, and the statement keeps master's C and its answer. Under `test/`, `benchmark/` and `packages/*/test/` no statement is given back for either: two ask the proof, in the two `yield_operator_diverging_block_types` tests, and both are shown.
- `format` and `sprintf`, which pass their arguments another way and are right on master in the fourteen forms tried (on 9c7ea3ce0; not run again).
- A format with named references (`%<a>d` with a Hash), which is taken only as a literal and is refused otherwise.

Test: `test/format_made_in_place_held.rb`, registered for the stress lanes by its header line (`# spinel: gc-stress`). Its last two lines are a constant and a global changed in place as the format, which are right on master without `--share-strings`. On master (82cfb601d) it is right at levels 0 and 1 with clang, and with gcc prints another line for the four named above; at `SPINEL_GC_STRESS=2` it is stopped after its sixth line by the collector's own check (exit 134) with gcc and with clang, and with clang its first three lines and its sixth are `0xDB` bytes.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master 82cfb601d, built from nothing: the test in the seven collector lanes with gcc and clang, with and without `--share-strings` (right in every one); `ruby tools/gate.rb check`; the generated C of the 6,809 other programs, changed in 7 (three more print the path of the build's own directory and differ in that alone), the five of them under `test/` run in the seven lanes and the two under `packages/` too; optcarrot, checksum 59662, its C byte-identical; `make share-strings-test` and `make int-min-test`, both pass; the 112 statements and the probes above with gcc and clang at levels 0, 1 and 2; the compiler's own instructions on the test, 91,067,496 on master and 91,383,120 here, and over 1,000 and 2,000 lines of one statement that keeps master's C: `p held % (ar[k] + i * m)`, 4,433,989,495 and 4,433,757,872 at 1,000 (-0.01%), 8,873,756,262 and 8,873,248,766 at 2,000 (-0.01%); `p held % (o.a_rather_long_reader + i)`, an `attr_accessor`'s reader in the argument, 3,457,821,922 and 3,458,134,670 at 1,000 (+0.01%), 6,915,692,202 and 6,916,317,862 at 2,000 (+0.01%); a literal format beside the same argument, `p "%5d|" % (o.a_rather_long_reader + i)`, 3,097,488,167 and 3,120,040,579 at 1,000 (+0.73%), 6,193,841,552 and 6,238,943,776 at 2,000 (+0.73%); and the dearest measured, the reader alone as that argument, `p "%5d|" % o.a_rather_long_reader`, 1,268,376,158 and 1,289,577,895 at 1,000 (+1.67%), 2,532,533,332 and 2,574,942,204 at 2,000 (+1.67%), with master's C. What is paid in those two is one more call of the walk that shows the argument makes nothing (master's `subtree_is_pure_read`), about 21,200 to 22,600 instructions a statement. The cost table was measured on 74fa6d7c2 and is not run again.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal`; CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change: byte-identical before and after. It depends on no other pull request: the proof that a name is the builtin's (`an_prog_never_gives`) is in master.
