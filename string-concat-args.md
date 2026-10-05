<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

With two arguments or more, `String#concat` and `String#prepend` read them in the C compiler's order, and lost one of them under the stress lane:

```ruby
n = 0
s = +"s"
p s.concat((n = 1; "x"), n.to_s)    # "sx1" in Ruby; "sx0" on master built with gcc

s = +"r"
x = s.concat("a#{1}", "b#{2}")      # master at SPINEL_GC_STRESS=2, gcc and clang:
                                    # "the mark reached a freed heap string"
```

The value arm of `concat` and `prepend` (`emit_str_mutator_call`, `src/codegen_call_recv.c`) and `prepend` on a String two names hold (`emit_string_handle_append`, `src/codegen_call_string.c`) nested the arguments in one C expression:

```c
const char *_t2 = sp_str_concat(sp_str_concat(_t3, A), B);
```

C leaves it open whether `A` or `B` is built first; gcc builds `B` first. And whichever is built first is held by nothing while the other allocates: `sp_str_concat` roots its parameters only once entered. A receiver that is no plain local takes the same arm for a statement, and so does `prepend` on a local, so `q[0].concat(a, b)`, `mk.prepend(a, b)` and `s.prepend(a, b)` as statements stop the same way.

Such arguments are now joined one statement each into one rooted temp, in their order (`emit_str_args_joined`):

```c
const char *_t2 = sp_str_concat(_t3, A); SP_GC_ROOT_STR(_t2); _t2 = sp_str_concat(_t2, B);
```

The receiver is taken first as it was, then each argument is evaluated where it stood. Ruby hands `concat` the String itself and reads its text when the call runs, after every argument, so a String that a later argument changes is read late (`str_arg_read_late`):

```ruby
s = +"s"; t = +"t"
p s.concat(t, (t << "z"; "a"))      # "stza" in Ruby and on master built with gcc; "sta" built with clang
```

A plain read of a local that a later argument names, and none assigns, is read in the join, where an ordinary call on master leaves it; the other arguments run first, each into a rooted temp of its own. For a String two names hold, a local or an instance variable, the handle is taken where the argument stands and its text is read in the join, which is right whether the later argument appends to the String or assigns the variable (`s.concat(@buf, grow)`).

The join can read late only those two. So three kinds of call keep the nested C they had, byte for byte (`str_args_nested`):

- Arguments that make nothing and run nothing (`str_args_plain`), and a single argument: String literals, plain reads of a String, and arguments master's operand-order rewrite already ran into rooted temps ahead of the call, which it does when two or more of them are calls (`s.concat(f(i), g(i))`). A read of a String two names hold is not among them: that read builds a copy, and `s.concat(@a, @b)` lost one copy while the other was built.
- A call where an argument may be a String made before the call, read some other way (a global, a constant, an attribute, an element, a conditional, a boxed local, an instance variable only one name holds, the result of a method the program defines), and an argument after it runs code. The join would read that String's text where the argument stands; gcc's master, building the last argument first, reads it after the later argument has appended to it, as Ruby does (`s.concat($t, ($t << "z"; "a"))` is "stza"). Joined, that right answer would turn wrong, so the call is left as it was: right with gcc where its order is Ruby's read, wrong with clang, and stopped at level 2. An argument made where it stands is not such a String: a literal, an interpolation, an Integer, and a builtin that builds a new String from a String, an Integer, a Float or an Array (`"a" + i.to_s`, `i.to_s`, `u.upcase`, `a.join`; `str_call_builds`), unless the program defines a method of that name.
- A call of more than 32 arguments.

`test/string_concat_args_held.rb` goes 300 times through a local, a receiver that is no variable, an element of a general Array and of a String Array, an instance variable and an Integer among the arguments, as a value and as a statement, and counts the results that are not Ruby's; reads three pairs of arguments where the first assigns what the second reads; then fourteen calls where a later argument appends to, replaces or assigns a String an earlier one reads; and counts 300 rounds of two reads of Strings two names hold. On master (ebb73f701, Linux x86-64) built with gcc a plain run prints `"sx0"`, `"x0t"`, `["abcx0", "d"]` and `"snewa"`; built with clang it prints nine of the late reads early (`"sta"`); level 1 counts wrong results with gcc; both abort at level 2. With this change it prints Ruby's output at plain, level 1, level 1 with `SPINEL_GC_VERIFY=1` and level 2 with both compilers. It is added to `GC_STRESS_TESTS`.

Measured with both compilers built on ebb73f701 (the branch merged with it), each program with gcc and clang at plain, level 1, level 1 with verify and level 2:

- 221 programs. No program right on master under a setting is wrong there with this change. 98 that fail on master are right under all eight, 59 are right before and after, and 45 fail the same way before and after: 12 do not build, 21 print the same wrong answer or raise under every setting, and 12 abort at level 2 or answer in gcc's order as before (calls that keep the nested C, and other arms). One more is right at level 2 with clang, where master aborted, and prints gcc's order with gcc before and after. In the other 18 a plain run is not right before or after and master aborted at level 2; level 2 now does what the plain run does: 16 print what master's plain run prints (two of those under gcc print this change's plain answer, nearer Ruby's by the order of the arguments) and two raise as the plain run does.
- Among them, 32 are the forms (seven kinds of receiver, `concat` and `prepend`, value and statement, two made arguments): 28 abort at level 2 on master and none with this change; the four that pass on master are `concat` as a statement, two other arms: on a local or an instance variable each argument goes into a rooted temp already, and through a String two names hold `sp_String_append` takes one argument at a time.
- 269 more, written for the order of reads: an earlier argument that reads a String through each kind of expression before one that appends to it, assigns it or replaces it, and calls of 31, 32, 33 and 40 arguments. None right on master under a setting is wrong with this change. 132 that fail on master are right under all eight, 31 are right before and after, and 101 fail the same way before and after: 57 keep the nested C and are right with gcc and wrong with clang as before, six are wrong with gcc alone as before, and 38 print the same wrong answer with both compilers or do not build. In the other five, master aborted at level 2 with clang where its plain run was already wrong, and level 2 now prints what the plain run prints.
- Generated C: 2 of the 5,826 programs in `test/*.rb` change (`concat_self_alias_snapshot`, `shift_slice_values_at_recv_root`), each by the joined form; both pass at plain, level 1, level 1 with verify and level 2 before and after, with both compilers. The 64 programs in `benchmark/`, the 156 package tests and optcarrot are byte-identical.
- Cost (callgrind, 200,000 rounds). The C is master's, and so is the count, for `s.concat("ab", "cd")`, `s.concat(i.to_s)`, `s.concat(i.to_s, i.to_s)` (237,048,310) and the same `prepend`. Where the joined form is written it is one root: `s.concat("a#{i}", "b#{i}")` 235,722,421 to 238,590,217, 14 instructions a call; three interpolations 16; a read and an interpolation 17; `prepend` of two interpolations 12; `q[0].concat(..)` as a statement 15. A late read costs a temp for each argument that runs: `s.concat(t, (t << "z"; "a"))` 263,351,130 to 269,555,033, 31 a call.

Not in this change:

- A call that keeps the nested C for a String read before an argument that runs code, or for its 33 arguments: its order and its level 2 abort are master's. Curing those needs the String handed over and read when the call runs, which only a local and a String two names hold allow today.
- `Array#concat` with several arguments is another arm and another commit.
- `emit_poly_builtin_method` (`src/codegen_call.c`) writes the same nest for `prepend` on a boxed receiver. No program I wrote reaches it (a boxed receiver takes the typed arm through the dispatch), so it is left as it is.
- `t.concat(a, b)` as a statement on a String two names hold does not build on master ("lvalue required as left operand of assignment"), before and after.
- An argument that appends to the receiver, as a value (`p s.concat((s << "z"; "a"), "b")` is "szab" in Ruby and "sab" here; as a statement on a local or an element it is right), `s.concat(a, b) << "c"` leaving `s` without the "c", and a boxed nil argument appended as "" where Ruby raises TypeError: the same before and after.
- `p c.s.concat(a, b)` through a reader of a String two names hold prints nil, before and after; with one argument it is right.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it is two lines of `0`, seventeen lines of Strings, one Array of Strings and four Integers)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on ebb73f701)
- [ ] Depends on: # (nothing)
