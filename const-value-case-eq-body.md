<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
LIMIT = 1..5
NAME = "abc"
p(LIMIT === 3, NAME === "abc")
p([9, 3, 1].find { |v| LIMIT === v })
```

prints `false`, `false` and `nil` (`spinel diff`: output-diff). CRuby prints `true`, `true` and `3`.

`emit_call_identity_arms` reads every `K === x` with a bare constant for its receiver as `Class === x`, the test whether `x` is an instance of the class `K` names. A constant the program gave a value names no class, so no `x` passed and the call was written as `false`. The same value in a local was asked its own `===`, and so were `when LIMIT`, `grep(LIMIT)` and `M::LIMIT === x`.

`const_value_eqq` takes such a call out of the class arm, and the `===` a local reaches answers: a Range covers, a number, a String, a Symbol, an Array and a Hash compare by `==`, an object with a `===` of its own is asked. A class constant is still the class test.

It answers for the kinds of `K` and `x` it lists, the ones where that `===` answers as CRuby does on master. I ran every pair of 24 values of `K` and 27 of `x`, in the constant form and in the local form (1,296 programs): 33 of the 648 constant forms go from `false` to CRuby's answer, no answer that was right changes, and the local forms compile to the same C.

Every other pair stays in the class arm with its `false`, right or wrong as before:

- an Integer or a Symbol against an Array, a Hash or a Range, where that `===` raises NoMethodError (`3 === [1, 2]` in a local);
- a String against an Array, a Bignum against a Float and a Float against a Bignum, which do not build;
- an object of the program as `x`: the value asks it nothing, where CRuby asks its `==`. Where `K === obj` did not build (a String, a Float or an Array for `K`), it still does not;
- the kinds the list does not name, a Complex or a Rational among them;
- a name that a class or a module of the program bears too: a constant read is typed by its name alone, so `Foo === x` outside the class that holds `Foo = 3` would be read as the 3.

Cost: a call that answered `false` and was right now runs the comparison it names. It is the C a local writes, within 2 instructions a call (callgrind over 300,000 turns of `n += 1 if LIMIT === a[i & 1]` and its twin with a local, gcc 13.3 and clang 18.1). No corpus program's C changes beyond the two tests. optcarrot's C is unchanged.

Not here: `K === x` for a constant that holds a String Range and a boxed String `x` answers `false`, as the local does (that is the `===` of a String Range, another pull request).

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (the Bignum pairs are in their own test, `test/const_value_case_eq_bignum.rb`, which is marked)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: nothing
