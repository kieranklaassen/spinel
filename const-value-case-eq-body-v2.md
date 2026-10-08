<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
LIMIT = 1..5
NAME = "abc"
p(LIMIT === 3, NAME === "abc")
p(["x", "abc"].select { |v| NAME === v })
```

prints `false`, `false` and `[]` (`spinel diff`: output-diff). CRuby prints `true`, `true` and `["abc"]`.

`emit_call_identity_arms` reads every `K === x` with a bare constant for its receiver as `Class === x`, the test whether `x` is an instance of the class `K` names. A constant the program gave a value names no class, so no `x` passed and the call was written as `false`. The same value in a local was asked its own `===`, and so were `when LIMIT`, `grep(LIMIT)` and `M::LIMIT === x`.

`const_value_eqq` takes such a call out of the class arm, and the `===` a local reaches answers: a Range covers, a number, a String, a Symbol, an Array and a Hash compare by `==`, an object with a `===` of its own is asked. A class constant is still the class test.

Cost on a program master ran right: a call that answered `false` and was right now runs the comparison it names, where master wrote the constant `false`. In instructions a call, gcc 13.3 / clang 18.1 (callgrind over 300,000 turns of `n += 1 if K === x`): an Integer 7 / 4, a Float 12 / 15, a String 29 / 42, a Float Range 46 / 42, an Integer Array 49 / 50, an object with a `===` of its own 20 / 24; a Symbol costs 244 / 268 fewer, master's class test of a Symbol was a call. It is the C a local writes, but for the object, which costs 14 / 22 more than through a local. `make cident` against master: the C of 6530 programs is identical and of 2 differs, the two tests of this change. optcarrot's C is unchanged.

It answers for the kinds of `K` and `x` it lists, the ones where that `===` answers as CRuby does on master. I ran every pair of 24 values of `K` and 27 of `x`, in the constant form and in the local form (1,296 programs): 28 of the 648 constant forms go from `false` to CRuby's answer, no answer that was right changes, and the local forms compile to the same C. And 3,556 programs whose operand is nil or not at run time (72 operands, a Hash that misses, a `find` with no hit, an ivar never assigned among them): 76 go from `false` to CRuby's answer, none that was right changes.

Every other pair stays in the class arm with its `false`, right or wrong as before:

- an Integer or a Symbol against an Array, a Hash or a Range, where that `===` raises NoMethodError (`3 === [1, 2]` in a local);
- a String against an Array, a Bignum against a Float and a Float against a Bignum, which do not build;
- an object of the program as `x`: the value asks it nothing, where CRuby asks its `==`. Where `K === obj` did not build (a String, a Float or an Array for `K`), it still does not;
- the kinds the list does not name, a Complex or a Rational among them;
- a name that a class or a module of the program bears too: a constant read is typed by its name alone, so `Foo === x` outside the class that holds `Foo = 3` would be read as the 3;
- a Range or a Float Range against an Integer that is not written as a literal (below).

Not here: `LIMIT === n` for an Integer `n` in a variable still answers `false`. The nil of an Integer is a sentinel in its slot, and in a local a beginless Range covers it and a Float Range can raise TypeError: `maximum = (..5); h = {"bolt" => 9}; p(maximum === h["cog"])` prints `true` on master. The class arm's `false` is CRuby's answer for a nil, and nothing says for sure that a slot cannot hold one (`nullable_int_value` does not mark an ivar never assigned or a `fetch` with a nil default), so only a literal Integer is asked of a Range. `K === x` for a String Range constant and a boxed String `x` answers `false`, as the local does (that is the `===` of a String Range, another pull request).

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here before that, on this commit over master `9922a2c74ee1` (Linux x86-64, gcc 13.3 and clang 18.1, CRuby 3.3.6): the build from nothing, the two tests at five collector settings with both compilers, with and without `--share-strings`, `tools/gate.rb check`, `make share-strings-test`, `make int-min-test` and `make cident`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (the Bignum pairs are in their own test, `test/const_value_case_eq_bignum.rb`, which is marked)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: nothing
