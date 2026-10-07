<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A cost first, a small one. A boxed needle that is no number and not nil, a String or a Symbol looked for in an Integer Array, is now asked whether it is a Float or an object before it is "not there": 5 instructions a lookup with gcc and 6 to 9 with clang, of 20 to 47 (callgrind, master 8dc55225, an Array of eight). An Integer needle runs the same count with gcc on `include?` and 5 to 7 fewer on `index` and `rindex`; with clang 0 to 2 more on `include?` and 2 to 3 fewer on `index`. A nil needle runs 6 fewer with gcc and the same with clang.

An Integer Array did not find a boxed Float or Rational that equals one of its elements:

```ruby
xs = [1, 2, 3]
price = { list: 2.0, note: "each" }
p xs.include?(price[:list])     # false; Ruby prints true
p xs.index(price[:list])        # nil; Ruby prints 1

row = [Rational(6, 2), "x"]
p xs.rindex(row[0])             # nil; Ruby prints 2
```

`Array#include?` and `#index` ask `element == needle`, and `2 == 2.0`. For a boxed needle the typed Integer Array's arms search the slots for an Integer's word, or for the nil slot's, and answer "not there" for a needle of any other kind, where unboxing it raised TypeError before. A Float or a Rational that equals an Integer was never looked for.

Such a number equals at most one Integer, and `sp_poly_int_needle` hands that Integer back boxed: a Float that is whole and inside the word, a Rational whose denominator is 1. Any other value comes back as it is. The emitted line picks the needle's word first (an Integer's own, the nil slot's, or the one the helper found) and calls the search once, so `index`, `find_index`, `rindex`, `include?` and `member?` answer alike, and the scan is the one an Integer needle runs. NaN, an infinity, a Float with a fraction or past the word are not there, as before; nor is `-2**63`, the nil slot's word, which is no element.

The two arms emitted the same lines; they now share one function, `emit_int_array_boxed_search`, and a typed nil needle keeps the C it had. The word is chosen first and the search called once for the cost's sake: with the tag test written as a last arm that makes a call of its own, an Integer needle paid 5 instructions with gcc.

Not covered: `delete` with such a needle; a Complex whose imaginary part is 0, a Rational made of Bignums, and an object whose class has a `==` of its own (Ruby asks it); an Integer Array that is itself in a box; a typed Rational needle (another arm); a Float Array searched for a Rational.

On master the test prints 11 of its 33 lines wrong and misses one. Eight corpus tests take the new line in their generated C and pass as before, with gcc and clang at the three stress settings. Optcarrot's generated C is unchanged.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (test/int_array_boxed_number_needle.rb)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
