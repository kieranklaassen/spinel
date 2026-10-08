<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Fix with a cost on a program master ran right: a `K === x` that answered `false` and was right now runs the comparison it names, where master wrote the constant `false`. In instructions a call, gcc 13.3 / clang 18.1 (callgrind over 300,000 turns of `n += 1 if K === v`, every answer `false`): an Integer Range against a literal Integer, the pair of the example below, 81 / 81; a String 34 / 54; a Float Range 39 / 37; an Integer Array 27.5 / 29.5; an object with a `===` of its own 29 / 37; a Float 11 / 13; an Integer 15 / 17. A Symbol costs 272 / 296 fewer: master's class test of a Symbol was a call. Nothing where the two kinds cannot be equal (an Integer or a Float against a String, a String against an Integer or a Float, a Symbol against an Integer or a String): the count is master's. Against the same value in a local the call is within 2 instructions either way, but for the object, which costs 16 / 20 more than through a local. Compiling such a line runs about 3,700 more instructions where `K` holds an Integer and 5,100 to 6,400 where it holds a String (callgrind over `spinel -c --no-line-map`, the compiler alone). Measured on programs of ten lines that set `LIMIT = 9`, `NAME = "abc"`, `TAG = :ok`, `RATE = 2.5`, a local of each kind (`v = 3`, `s = "abd"`, `t = :no`, `f = 1.5`), `n = 0` and `x = false`, then 2,000 lines, then one `p`: with every line `x = LIMIT === v` the compile runs 0.42% more instructions; with `x = NAME === s`, 0.76%; with the bare `NAME === s`, 0.98%; with `n += 1 if LIMIT === v`, `n += 1 if NAME === s`, `n += 1 if TAG === t` and `n += 1 if RATE === f` in turn, 0.50%. A Range or an object with a `===` of its own costs more, counted the same way on programs of 2,000 lines of one kind (`t += 1 if KR === 9` and the like, behind a few lines that set the constants and a local of each kind): a line runs 18,200 more instructions for `KR === 9` with `KR = 1..5` (2.3% of that compile), 18,300 to 21,300 for a String Range against a String (2.4% to 2.7%), 31,000 to 33,200 for a Float Range against a Float (4.0% to 4.3%), and 65,700 to 70,500 for an object whose class defines `===` (7.4% to 8.0%). That is the price of writing the comparison where master wrote `false`, and master pays the like today where the same constant is asked by name: 2,000 lines of `KR.cover?(9)` compile in 1,602,108,373 instructions on master, 2,000 of `KR === 9` in 1,593,900,474 here. One line that asks such an object, in a program where no local holds an object of its class, adds 0.6% to the whole compile whatever its length (38,400,000 instructions among 8,000 lines): the call roots its receiver, and master lays out the function's frame of roots once, as it does for any call on that constant (2,000 lines with one `KO.check(xi)` among them compile in 1,706,871,048 instructions on master, the same lines with one `KO === xi` in 1,706,905,171 here). A line the change leaves in the class arm, a Range against an Integer in a variable, costs about 400.

```ruby
LIMIT = 1..5
NAME = "abc"
p(LIMIT === 3, NAME === "abc")
p(["x", "abc"].select { |v| NAME === v })
```

prints `false`, `false` and `[]` (`spinel diff`: output-diff). CRuby prints `true`, `true` and `["abc"]`.

`emit_call_identity_arms` reads every `K === x` with a bare constant for its receiver as `Class === x`, the test whether `x` is an instance of the class `K` names. A constant the program gave a value names no class, so no `x` passed and the call was written as `false`. The same value in a local was asked its own `===`, and so were `when LIMIT`, `grep(LIMIT)` and `M::LIMIT === x`.

`const_value_eqq` takes such a call out of the class arm, and the `===` a local reaches answers: a Range covers, a number, a String, a Symbol, an Array and a Hash compare by `==`, an object with a `===` of its own is asked. A class constant is still the class test.

It takes the call only where `x` is one node that runs nothing: a number, a String or a Symbol written out, `nil`, `true`, `false`, `self`, a local, an instance or a class variable, a constant of the program. The value's `===` reads the constant in one C expression with `x`, in the order the C compiler picks, so an `x` that changes the constant's String in place (`NAME === (NAME << "c"; "ab")`) or binds the constant anew would be read before the constant by one compiler and after it by the other; master's `false` is CRuby's answer there with both. Under that condition no answer that was right changes: eight such programs, the operand in parentheses, a method, an index or an operator the program defines anew, print CRuby's `false` with gcc and clang, as on master.

It answers for the kinds of `K` and `x` it lists, the ones where that `===` answers as CRuby does on master. I ran every pair of 24 values of `K` and 27 of `x`, with `x` in a local, in the constant form and in the local form (1,296 programs): 28 of the 648 constant forms go from `false` to CRuby's answer, 2 stay `false` where CRuby answers `true` (the String Range against a boxed String, below), no answer that was right changes with gcc or with clang, and the local forms compile to the same C.

Every other call stays in the class arm with its `false`, right or wrong as before:

- an `x` that runs something or is more than one node: `K === f(n)`, `K === h["k"]`, `K === n + 1`, `K === [1, 2]`, a String with `#{}` in it, and a literal in parentheses;
- an Integer or a Symbol against an Array, a Hash or a Range, where that `===` raises NoMethodError (`3 === [1, 2]` in a local);
- a String against an Array, a Bignum against a Float and a Float against a Bignum, which do not build;
- an object of the program as `x`: the value asks it nothing, where CRuby asks its `==`. Where `K === obj` did not build (a String, a Float or an Array for `K`), it still does not;
- the kinds the list does not name, a Complex or a Rational among them;
- a name that a class or a module of the program bears too: a constant read is typed by its name alone, so `Foo === x` outside the class that holds `Foo = 3` would be read as the 3;
- a Range or a Float Range against an Integer that is not written as a literal (below).

`make cident` against master: the C of 6603 programs is identical and of 2 differs, the two tests of this change. optcarrot's C is unchanged.

Not here: `K === x` for an `x` that is a call, an index, an operator or a literal in parentheses still answers `false`: `LIMIT === (3)` and `NAME === h["k"]` print `false` as on master. `LIMIT === n` for an Integer `n` in a variable still answers `false`. The nil of an Integer is a sentinel in its slot, and in a local a beginless Range covers it and a Float Range can raise TypeError: `maximum = (..5); h = {"bolt" => 9}; p(maximum === h["cog"])` prints `true` on master. The class arm's `false` is CRuby's answer for a nil, and nothing says for sure that a slot cannot hold one (`nullable_int_value` does not mark an ivar never assigned or a `fetch` with a nil default), so only a literal Integer is asked of a Range. `K === x` for a String Range constant and a boxed String `x` answers `false`, as the local does (that is the `===` of a String Range, another pull request).

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here before that, on this commit over master `ed9861279d67` (Linux x86-64, gcc 13.3 and clang 18.1, CRuby 3.3.6): the build from nothing, the two tests at five collector settings with both compilers, with and without `--share-strings`, `tools/gate.rb check`, `make cident` and the figures above. `make share-strings-test` and `make int-min-test` were run on the same C: on this commit as it stood before `const_value_eqq` put its cheap tests first, which `make cident` shows to write the same C for every program of the corpus.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (the Bignum pairs are in their own test, `test/const_value_case_eq_bignum.rb`, which is marked)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: nothing
