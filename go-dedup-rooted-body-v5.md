<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`-str` and `String#dedup` on a String just built answer from freed bytes: in a plain run where the String is large, under `SPINEL_GC_STRESS=2` for any. No program pays for the fix: a content already interned runs the same instructions, a new one a few less.

```ruby
a = "x" * 100_000
b = "y" * 100_000
x = -(a + b)
p x[0, 3], x.count("x")   # master: "\u0000\u0000\u0000" and 3984. CRuby: "xxx" and 100000
```

When the content is not interned yet `sp_str_dedup` (`lib/spinel_rt.h`) allocates the frozen copy with `sp_str_from_bytes`, and nothing held the String it copies from: a collection in that allocation freed a receiver the caller had just built, and the copy was made of freed bytes. A String this large starts that collection by itself; `-("ab" + k.to_s)` and `(a + b).dedup` go the same way under `SPINEL_GC_STRESS=2`. The copy is now allocated with `sp_str_alloc_nogc`, which runs no collection first: the allocator `sp_msg_heapify` uses for a String it cannot root. Nothing is rooted and no function is added: inside `sp_str_dedup` the one line that copies becomes four.

Cost, by callgrind on master 3d629868, before and after. A content already interned, 1,000,000 `-s`: with a mutable local 213,671,820 and 213,671,813 instructions with gcc, 219,633,465 and 219,633,459 with clang; with a frozen local 99,671,467 both with gcc, 104,631,761 both with clang; with a String built each turn (`-("k" + (i % 50).to_s)`) 690,206,991 and 690,206,791 with gcc, 694,118,608 and 694,118,405 with clang. A new content, 200,000 `-key(i)`: 332,994,644 and 331,375,496 with gcc, 8 a call less, 323,776,898 and 322,957,539 with clang, 4 less; 20,000 of 2,000 bytes: 1,005,652,250 and 1,005,332,768 with gcc, 924,847,019 and 924,642,537 with clang. The compiler is untouched, so the generated C is identical.

The new test joins `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
