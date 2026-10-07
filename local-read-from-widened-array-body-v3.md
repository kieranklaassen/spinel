<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A local read out of an Array that a later store gave another kind of element held a wrong value, with nothing said.

```ruby
t = [1, 2]
t << "s"
r = t.last
p r
```

```
spinel diff: output-diff
  program: lead.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"s"
+0
```

**The cost, yours to weigh.** A local read out of a widened Array is now boxed, also in a program that was right before because the element it read was of the first kind. A read of an Array that is never widened compiles to the same C. No list keeps the unboxed local where the element happened to be of the first kind: which element a read answers is settled when the program runs, and master boxes the same read where the Array is mixed from its literal (`t = [1, 2, "s"]; r = t[0]`). One turn of a loop (callgrind, gcc, 200,000 turns, `t = [1, 2]; t << "s"` unless said):

| loop body | before | here |
|---|---|---|
| `r = t[0]; s += r` | 27 | 31 |
| `r = t[1]; n += 1 if r == 2` | 26 | 30 |
| `r = t.first; n += 1 if r` | 26 | 21 |
| `r = t[0]; n += r.size`, `t = ["a", "b"]; t << 7` | 81 | 105 |
| `r = t[0]; s += r * 2.0`, `t = [1.5, 2.5]; t << "s"` | 29 | 74 |

Compiling costs more only where a local Array is widened: the scan of the writes and the fold then run twice a round. Against the same program with the Array mixed from its literal (`t = [1, 2, "s"]`), which holds the same boxed locals and compiles on master as it is, that is 1.1 times for many reads of one Array and 1.6 times for many Arrays, flat in their number (instructions of `spinel -c`, callgrind):

| program | before | here | the literal twin, before |
|---|---|---|---|
| 500 Arrays, none widened | 2,333,982,128 | 2,334,139,078 | |
| 500 reads of one widened Array | 718,877,424 | 1,666,892,515 | 1,478,571,760 |
| 250 Arrays, each widened and read | 796,690,944 | 1,416,704,215 | 878,917,856 |
| a chain of 25 (`t2 << r1; r2 = t2.last` ...) | 48,426,570 | 65,675,440 | 41,688,932 |
| a chain of 200 | 647,276,669 | 1,050,920,348 | 658,239,565 |

The container fold makes `t` the general Array, but it runs after the scan that types each local from its writes. So `r` was typed from the Integer array, in every round, and the boxed element was narrowed into it. An Integer read out of what began as a String array came out as `"1"`, a String out of a Float array raised ArgumentError, and `a, b, c = t` printed a pointer for `c`. Stored on, the wrong value spread: `u = [3, 4]; u << r` held `[3, 4, 0]`.

`infer_write_types` now marks the plain locals that hold a typed Array before the fold and looks at them after it. If the fold widened any, the other plain locals go back to UNKNOWN and the scan runs again in the same round with those locals held as the general Array. Nothing is kept across rounds.

`infer_write_reads_widened` does not reach this: it runs before the fold, when the Array is still typed. Run after the fold it types `k = t[0]` again but not what is made of `k`: `t = ["a", "b"]; t << 7; k = t[0]; h = { k => 1 }; p h["a"]` prints 1 on master and was refused that way. Its list is used for what it does carry: as the fold widens a local Array the writes that read it are typed again at once, so `r = t.last; t2 << r` widens `t2` in the same pass and a chain does not cost a scan a link. The first commit cuts that function into its build and its drain for this, with no change in the generated C.

Checked on master a785162aa:

- `test/local_read_from_widened_array.rb` fails on master in every section and passes here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`, with gcc and clang.
- 1,920 generated programs (an Array of Integers, Floats, Strings or Symbols, 15 ways it comes to hold another kind, 32 ways a local reads from it), each against CRuby: the C changes in 684 and all 684 are right, where master was right in 361, printed a wrong answer in 210 and raised in 113. The other 1,236 compile to the C they had.
- 756 more that use the local read (80 uses): the C changes in 750 and each answers as before. No program is refused and none stops building.
- With `--share-strings`, the String rows of both sets (480 and 238): the C changes in 228 and 238. The 228 are all right, where master was right in 127, wrong in 90 and raised in 11; the 238 answer as before.
- `tools/cident.sh` against a785162aa: the first commit alone 6414 identical, 0 differ, 0 refusal changes; with the second, 6414 identical, 1 differ (the new test), 0 refusal changes.

Left alone: `t.map! { }` whose block answers another kind widens `t` in a later pass, so a local read out of that Array is still typed from the first kind. The next pull request mends it.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
