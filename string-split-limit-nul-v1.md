<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p "x,a\0b".split(",", 2)     # CRuby ["x", "a\u0000b"]. Here: ["x", "a"]
p "a\0b\0c".split("\0", 2)   # CRuby ["a", "b\u0000c"]. Here: ["a"]
p "a\0".split("", 5)         # CRuby ["a", "\u0000", ""]. Here: ["a"]
```

`sp_str_split_limit`'s arm for a positive limit read the String with `strlen` and sought the separator with `strstr`, where the unlimited split (`sp_str_split_into`) reads byte lengths and searches by bytes. A field after a NUL was lost, and a separator that starts with a NUL was taken for the empty one. The arm reads byte lengths now. A one-byte separator is found by `memchr`. A longer separator without a NUL is still found by `strstr`, run again behind each NUL of the String: `strstr` stops there, and a separator that holds no NUL has no byte to put on one, so no match lies across it. A separator that holds a NUL, wrong on master in every call, is found by `sp_bytestr`. `lib/sp_str.c` only; no program's generated C changes.

Measured on master 185c4d66, CRuby 3.3.6, gcc and clang: 30,005 lines (21 Strings, 6 ways of holding one, 12 separators, 7 limits, 7 uses of the result). Right before and after 18,084; wrong made right 11,734; right made wrong 0. 187 are wrong before and after for other causes: the fields of a binary String lose the binary mark, and a Regexp separator with limit 0 drops a field that starts with a NUL. Under `SPINEL_GC_STRESS=2` the same 11,734 are made right and none is lost; master stops in the collector at a Regexp separator with a limit, before and after, and the lines behind it are not printed.

Cost by callgrind, 200,000 calls: `"alpha,beta,gamma,delta".split(",", 3)` 179.63M instructions to 178.23M; `"key: value: more".split(": ", 2)` 140.16M to 149.36M (+6.6%, the worst measured: 46 instructions a call for the two byte lengths and one look through the separator for a NUL); `"hello, world".split("", 4)` 199.87M to 205.07M (+2.6%). A 2,000-byte field, 20,000 calls: 34.59M to 25.95M. A String filled with the separator's first byte, `("a" * 2000 + "b,c").split("ab", 2)`, 20,000 calls: 43.19M to 44.07M.

**Test.** `test/string_split_limit_nul.rb`, 12 lines; all 12 fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [ ] Depends on: # (nothing)
