<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`fetch` and `values_at` on a boxed Array read an index that is no Integer as a number:

```ruby
def pick(n) = n > 0 ? {a: 1} : [10, "s", :z]
h = pick(0)
p h.values_at(:a)         # ["s"]; CRuby: no implicit conversion of Symbol into Integer (TypeError)
p h.values_at(nil)        # [10]; CRuby: no implicit conversion from nil to integer (TypeError)
p h.fetch(2**70)          # 10; CRuby: bignum too big to convert into 'long' (RangeError)
p h.fetch(0.0 / 0.0, 9)   # 9; CRuby: float NaN out of range of integer (RangeError)
```

Of 1,296 programs that call `fetch` or `values_at` on a boxed receiver with an index of every kind, 102 are cured and none that was right is lost: 1,076 are right on master and here, 14 print the same wrong bytes on both, and 104 build on neither (a `values_at` index that needs a statement of its own: another pull request).

An Integer index pays nothing, and `fetch` is cheaper. By callgrind a loop of three fetches (two on a boxed Array, one on a boxed Hash) runs 651 instructions a pass on master and 331 here with gcc, 602 and 316 with clang; `values_at` with two Integers runs 572 and 570 with gcc, 578 and 571 with clang.

`sp_poly_fetch` and `sp_poly_arr_values_at` read the index with `sp_poly_to_i`, which answers a number for anything. `values_at` read an element for a Symbol, `true` or `nil`; `fetch` read element 0 for a Bignum, and answered its default for a NaN and, on an empty Array, for an index of any kind. Both now convert the index as an Integer argument is converted (`sp_poly_arg_int_chk`), with `Array#fill`'s check for a Float or a Bignum past a word in front of it: a Float is cut, a NaN, a far Float and a Bignum past a word are CRuby's RangeError, and anything that is no number is its TypeError. The smallest Integer is a word, so it stays the offset it was, past every Array, whether its box says Integer or Bignum. `fetch` then reads the element by the index it has converted rather than through the generic index; `values_at` takes an Integer as it is.

Since the commit "A keyword splat sent to a method without keywords arrives as its last positional, and a boxed array index of another kind raises TypeError", `fetch` by a Symbol, `true` or an Array inside the bounds raises through that generic index. It raises there for a Rational and an object with `to_int` too, which `fetch` converts; here they answer the element.

Not here: a Float Range in `values_at`, which CRuby slices by, still reads one element (converting it would raise where no raise is due); `fetch` with a block still hands the block the converted index; the TypeError for an arithmetic sequence names Array, and for a String Range in `values_at` it names Range where CRuby names String; the smallest Integer in a local, or computed under `--int-overflow=promote`, is nil to master before `fetch` sees it (`p` prints nil) and raises TypeError as it did. For the same reason nil on an empty boxed Array is left as it was (`fetch` answers its default or IndexError, `values_at` nil): a nil there cannot be told from that Integer, for which those are CRuby's answers.

No generated C changes: the two functions are in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
