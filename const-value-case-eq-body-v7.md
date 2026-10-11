<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Fix with a cost on a program master ran right: a `K === x` that answered `false` and was right now runs the comparison it names, where master wrote the constant `false`: up to 92.5 instructions a call by the kind, and nothing where the two kinds cannot be equal (the first table below). Compiling such a line costs 5,100 to 76,500 instructions more (the second table).

```ruby
LIMIT = 1..5
NAME = "abc"
p(LIMIT === 3, NAME === "abc")
p(["x", "abc"].select { |v| NAME === v })
```

prints `false`, `false` and `[]` (`spinel diff`: output-diff). CRuby prints `true`, `true` and `["abc"]`.

`emit_call_identity_arms` reads every `K === x` with a bare constant for its receiver as `Class === x`, the test whether `x` is an instance of the class `K` names. A constant the program gave a value names no class, so no `x` passed and the call was written as `false`. The same value in a local was asked its own `===`, and so were `when LIMIT`, `grep(LIMIT)` and `M::LIMIT === x`.

`const_value_eqq` takes such a call out of the class arm, and the `===` a local reaches answers: a Range covers, a number, a String, a Symbol, an Array and a Hash compare by `==`, an object with a `===` of its own is asked. A class constant is still the class test.

It takes the call only where CRuby's lookup must reach that value. A constant's read is typed by its name alone, and CRuby reads a bare name by where it stands: `Foo === x` outside the class that holds `Foo = 3` is whatever `Foo` names there, a class of the program, one of CRuby's own that no table of the compiler lists (`Marshal`), or one a file brings that the compiler did not read. So the call is taken only where:

- the constant is bound once in the whole program, by a plain write (`K = v`), and the call stands in the same class or module body as that write, or both at the top level. A method or a block of that body is in it; a subclass, a class nested in it and `::K` inside a class are not. CRuby asks that body's own table first, ahead of the bodies around it and of the class's ancestors. A name written under two paths counts by its last part, since two paths can name one class (`class Object`, `class A::X`, `Y = X; class Y`);
- no call can bind the name anew or take it away: the program as written holds no Symbol of the name and no site where a method is named, made, mixed in or loaded by something the text does not spell (`an_prog_never_gives`, master's walk), and no `const_set` or `remove_const`, as a call or as a Symbol. Such a call is one the compiler does not perform: it raises NoMethodError, the program can rescue it and run on, and in CRuby the constant is another by then;
- no test of the engine was decided at compile time (`RUBY_ENGINE`, `RUBY_VERSION`, `defined?(RubyVM)`): the node table no longer holds the arm CRuby runs, and a second write, a class of that name or such a call may have stood in it. `desugar_engine_branches` now notes that it decided one (`g_engine_decided`), which by itself changes no program's C.

Any other call keeps master's C and its `false`.

And it takes the call only where `x` is one node that runs nothing: a number, a String or a Symbol written out, `nil`, `true`, `false`, `self`, a local, an instance or a class variable, a constant of the program. The value's `===` reads the constant in one C expression with `x`, in the order the C compiler picks, so an `x` that changes the constant's String in place (`NAME === (NAME << "c"; "ab")`) or binds the constant anew would be read before the constant by one compiler and after it by the other; master's `false` is CRuby's answer there with both.

It answers for the kinds of `K` and `x` it lists, the ones where that `===` answers as CRuby does on master. I ran every pair of 24 values of `K` and 27 of `x`, with `x` in a local, in the constant form and in the local form (1,296 programs), with `--share-strings` and without: 28 of the 648 constant forms go from `false` to CRuby's answer, no answer that was right changes with gcc or with clang, and each local form compiles to the same C or, for 7 of the 648, is refused as on master.

Every other call is left to the class arm as before, right or wrong:

- an `x` that runs something or is more than one node: `K === f(n)`, `K === h["k"]`, `K === n + 1`, `K === [1, 2]`, a String with `#{}` in it, and a literal in parentheses;
- an Integer or a Symbol against an Array, a Hash or a Range, where that `===` raises NoMethodError (`3 === [1, 2]` in a local);
- a String against an Array, a Bignum against a Float and a Float against a Bignum, which do not build;
- an object of the program as `x`: the value asks it nothing, where CRuby asks its `==`. Where `K === obj` does not build on master (every kind of `K` I tried but an Integer Range, which answers `false`), it still does not;
- a constant of a kind the list does not name, a Complex among them (it still answers `false`);
- a Range or a Float Range against an Integer that is not written as a literal (below).

No corpus program's C changes but that of the two tests of the new answers, with `--share-strings` or without, and the change adds no refusal in either setting. optcarrot's C is unchanged.

Cost at run time, in instructions a call: callgrind over 300,000 turns of `n += 1 if K === v` in a `while` loop at the top level, every answer `false`, with `v` one of two locals picked a line above and their values not known to the C compiler. Each row was counted with the constant's line above the locals' and below them; a figure is the least and the greatest of the two where they differ, and a half is the mean of the two values' paths.

| `K` holds | gcc 13.3 | clang 18.1 |
|---|---|---|
| a String Range, `x` a String outside it | 86.5 | 86 |
| a String Array, `x` another | 86.5 | 92.5 |
| an Integer Range, `x` a literal Integer outside it | 81 | 81 |
| a Hash, `x` another Hash | 78 to 78.5 | 72.5 |
| a String, `x` another String | 32 to 34 | 57 |
| a Float Range, `x` a Float outside it | 34.5 | 34 |
| an Integer Array, `x` another | 26 | 32.5 |
| an object with a `===` of its own, `x` an Integer | 22 | 26 |
| a Float, `x` another Float | 9.5 | 10 |
| an Integer, `x` another Integer | 8 | 3 |
| a Symbol, `x` another Symbol | 0 to 8 | 0 |
| two kinds that cannot be equal: an Integer or a Float against a String, a String against an Integer or a Float, a Symbol against an Integer or a String | 0 | 0 |

That is the comparison a local reaches: against the same value in a local the call is within 2 instructions either way, but for an object with a `===` of its own, 14 / 23 more (a read of that constant tests that its initializer is done, as every read of it does on master), and a Symbol, 0 to 8 / 0 more. Where the answer is `true` master printed the wrong line.

Cost at compile time, in instructions of the compiler alone (callgrind over `spinel -c --no-line-map`) on programs of 2,000 lines `t += 1 if K === x` of one kind behind a few lines that set the constants and a local of each kind (`KI = 3`, `xi = ARGV.size + 3` and the like). The last column is what master pays today for the same constant asked by name, counted the same way against its `false` line.

| 2,000 lines of | more a line | of that compile | by name on master, a line, against its `false` line |
|---|---|---|---|
| `KI === xi`, an Integer | 5,100 | 0.61% | 9,200 fewer (`KI == xi`) |
| `KF === xf`, a Float | 5,100 | 0.64% | - |
| `KY === :b`, a Symbol | 5,900 | 0.74% | - |
| `KS === xs`, a String | 7,400 | 0.91% | 6,600 fewer (`KS == xs`) |
| `KA === xa`, an Integer Array | 7,400 | 0.87% | - |
| `KR === 9`, an Integer Range and a literal | 20,300 | 2.59% | 22,700 more (`KR.cover?(9)`) |
| `KSR === xs`, a String Range | 23,200 | 2.94% | - |
| `KR === xf`, a Float Range | 35,100 | 4.45% | 26,500 more (`KR.cover?(xf)`) |
| `KO === xi`, an object whose class defines `===` | 76,500 | 8.38% | 65,500 more (`KO.check(xi)`, a method of its own) |

A Range or an object costs what writing its comparison costs, where master wrote `false`. One line that asks such an object, in a program where no local holds an object of its class, adds 0.7% to the whole compile whatever its length (counted at 200, 2,000 and 8,000 lines): the call roots its receiver, and master lays out the function's frame of roots once, as it does for any call on that constant; where a local already holds one, the line adds 2,797,200 instructions. A line the change leaves in the class arm, a Range against an Integer in a variable, costs about 400: `const_value_eqq` looks at the operand and the two kinds before it asks where the name is bound. Asking that is one walk of the node table a program, made at the first call that gets so far: a program of n Integer constants with one such call each (`x = K0 === v`, `x = K1 === v` and so on) compiles with 0.42% more instructions at n = 1,000 and 0.32% at 2,000, 6,600 and 6,800 a line. A `===` whose receiver is a local pays 20 instructions a line at compile time (the question is asked and answered no at once) and compiles to the same C, and a program with no `===` pays 1 a line (2,042 in 1,586,870,848 at 2,000 lines).

Not here: a `K === x` whose constant is read outside the body that binds it (a method of a subclass, a class nested in that body, `::K` inside a class) or is bound twice or under two spellings of one class, and every such call in a program that holds a `const_set` or a `remove_const`, a site the text does not spell, or a test of the engine the compiler decides (`if RUBY_VERSION >= "3.0"` anywhere in the program is one), stays `false`, right or wrong as on master. `K === x` for an `x` that is a call, an index, an operator or a literal in parentheses still answers `false`: `LIMIT === (3)` and `NAME === h["k"]` print `false` as on master. `LIMIT === n` for an Integer `n` in a variable still answers `false`. The nil of an Integer is a sentinel in its slot, and in a local a beginless Range covers it and a Float Range can raise TypeError: `maximum = (..5); h = {"bolt" => 9}; p(maximum === h["cog"])` prints `true` on master. The class arm's `false` is CRuby's answer for a nil, and nothing says for sure that a slot cannot hold one (`nullable_int_value` does not mark an ivar never assigned or a `fetch` with a nil default), so only a literal Integer is asked of a Range. `K === x` for a String Range constant and a boxed String `x` answers `false`, as the local does.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

On Linux x86-64 (gcc 13.3 and clang 18.1, CRuby 3.3.6), before that, on this commit (the expected files were made with CRuby 3.3.6, so the first box is open for the gate): the build from nothing, the seven tests at five collector settings with both compilers, with and without `--share-strings`, and under the two `--int-overflow` modes, `ruby tools/gate.rb check-range HEAD^1 HEAD`, `make gc-stress-test`, `make share-strings-test`, `make int-min-test`, `make cident` against the commit beneath and the figures above. No make leg runs a test with `--share-strings` at `SPINEL_GC_STRESS=2`, so the seven were run by hand at that level with the flag and without it, with `SPINEL_GC_VERIFY` 0 and 1 and both compilers. `make share-verify-test` ends as it does on master without this commit: one failure (test/share/share_strings_net_http_zlib.rb) and two new diagnostics (test/share/share_strings_exception_dispatch.rb).

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (compared with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (the Bignum pairs are in their own test, `test/const_value_case_eq_bignum.rb`, which is marked)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: nothing
