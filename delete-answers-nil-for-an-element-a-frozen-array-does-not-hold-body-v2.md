<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
a = ["x", "y"].freeze
p a.delete("zz")
p a.delete("zz") { "none" }
```

raises FrozenError at its first `delete` (`spinel diff`: exception-diff). CRuby prints `nil` and `"none"`.

One cost stays, and it is on `delete` itself: on an Integer Array that is not frozen `delete` runs 2 instructions a call more, 1 more in a program with threads, with gcc and with clang. On a Float, String or boxed Array it costs what it cost (table below).

It cannot be cut. The raise never returned and the search can, so `sp_IntArray_delete` now keeps the flag of its GC root in a register across that call, and saves and restores the register on every call. Testing `frozen` before the Array is rooted avoids that (2 instructions a call fewer than master, measured), but gcc then counts the function one statement larger, and `lib/sp_array.c` is at gcc's inline unit limit: gcc stops inlining in it at its cap of 14,000 size units and refuses 86 call sites, so one statement more in one function changes what it inlines into others (`sp_IntArray_product` comes out different in the runtime with threads). So the check stands exactly where the raise stood, and the three functions keep the size gcc counted for them. Every other function of `lib/sp_array.c` is then the same instructions as on master, with and without threads: with the object files compared section by section, 257 of 262 code sections are equal without threads and 258 of 263 with, and the five that differ are the three `delete` functions (both parts of the Integer and of the String one, the cold part of the Float one).

CRuby's `Array#delete` raises only once it has found an element to remove, so an Array that does not hold the element is left alone. The delete functions of the four Array kinds (Integer and Symbol, Float, String, boxed) raised for a frozen Array before they searched. Each now hands a frozen Array to a cold function that searches it: the function raises where the Array holds the element and returns where it does not, and the caller then answers nil. A boxed Array proves the element absent only among Integers, Strings, Symbols, nil, true, false and Floats that are numbers, where the runtime equality is CRuby's; with a NaN, a Complex or an object that has its own `==` on either side it raises as it did.

Cost: the search stands only behind the frozen test each function already made. Instructions a call of `delete` on an Array of 8 elements that is not frozen, this branch less master (callgrind, 100,000 calls; the runtime archive is built by `cc`, gcc 13.3.0, in every column, and the column names the compiler of the generated C):

| `delete` on an Array that is not frozen | gcc | clang | gcc, threads | clang, threads |
|---|---|---|---|---|
| Integer Array, finds nothing | +2 | +2 | +1 | +1 |
| Integer Array, finds its element | +2 | +2 | +1 | +1 |
| Float Array, finds nothing | 0 | 0 | 0 | 0 |
| Float Array, finds its element | 0 | 0 | 0 | 0 |
| String Array, finds nothing | 0 | 0 | 0 | 0 |
| String Array, finds its element | 0 | 0 | 0 | 0 |
| boxed Array asked for an Integer, finds nothing | 0 | 0 | 0 | 0 |
| boxed Array asked for an Integer, finds it | 0 | 0 | 0 | 0 |
| boxed Array asked for a String, finds nothing | 0 | 0 | 0 | 0 |
| boxed Array asked for a String, finds it | 0 | 0 | 0 | 0 |

Without threads the Float and String rows are the same instruction count to the last digit with both compilers, and the boxed rows are within 3 instructions over the whole run. With threads the scheduler moves a program's total by a few thousand instructions between two runs of one binary, so those two columns are the count of the function that deletes (`sp_IntArray_delete`, `sp_FloatArray_delete`, `sp_StrArray_delete`, and for a boxed Array the program's main function, where the boxed `delete` is inline), which is the same in three runs. The three typed functions that search are in `lib/sp_inspect.c`, where gcc refuses no call site, and every other function of that object is unchanged. The Float and the String element are handed to them as a one-member struct read through the parameter's address, an odd line that is there only for the inline unit limit above: a plain Float `v` in the call is a load that makes `sp_FloatArray_delete` one statement larger (`sp_IntArray_product` then comes out different in the runtime with threads), and a String handed by its address costs `delete` on a String Array 1 instruction a call. No generated C changes: the change is in the runtime library only.

Not changed: `delete_at` with an index past the end of a frozen Integer, Float or String Array still raises FrozenError where CRuby answers nil. `[1.5, 0.0 / 0.0].freeze.delete(0.0 / 0.0)` still raises where CRuby answers nil: the search cannot tell one NaN from another. An Integer, Float or String Array asked to delete an object that defines its own `==` is refused, and an Integer or String Array asked to delete a Complex or a Rational does not build, both as on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
