<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p "x,a\0b".split(",", 2)     # CRuby ["x", "a\u0000b"]. Here: ["x", "a"]
p "a\0b\0c".split("\0", 2)   # CRuby ["a", "b\u0000c"]. Here: ["a"]
p "a\0".split("", 5)         # CRuby ["a", "\u0000", ""]. Here: ["a"]
```

`sp_str_split_limit`'s arm for a positive limit read the String with `strlen` and sought the separator with `strstr`, where the unlimited split (`sp_str_split_into`) reads byte lengths and searches by bytes. A field after a NUL was lost, and a separator that starts with a NUL was taken for the empty one. The arm reads byte lengths now and finds the separator with `sp_str_find`, from the pull request beneath: by `strstr` as before, and by `sp_bytestr` behind the NUL `strstr` stopped at only when it finds nothing, so a String of many NUL bytes is searched once. `lib/sp_str.c` only; no program's generated C changes.

Measured on master 8684d54c, CRuby 3.3.6, gcc and clang: 30,005 lines (21 Strings, 6 ways of holding one, 12 separators, 7 limits, 7 uses of the result). Right before and after 18,084; wrong made right 11,759, of which 25 by the pull request beneath; wrong before and after 162, all of one cause: the fields of a binary String lose the binary mark. Under `SPINEL_GC_STRESS=2` master stops in the collector at a Regexp separator with a limit, in 45 of the 51 programs, before and after; of the lines printed before that, 11,741 are made right.

Cost by callgrind, 200,000 calls: `"alpha,beta,gamma,delta".split(",", 3)` 179.63M instructions to 178.83M; `"key: value: more".split(": ", 2)` 140.16M to 145.16M (+3.6%); `"hello, world".split("", 4)` 199.87M to 206.47M (+3.3%). A separator of two bytes that is not found pays one `strlen`: `"key=value and more".split(": ", 2)` 104.00M to 113.80M (+9.4%, the worst measured, 49 instructions a call). A 2,000-byte field, 20,000 calls: 34.59M to 26.07M. A String filled with the separator's first byte, `("a" * 2000 + "b,c").split("ab", 2)`, 20,000 calls: 43.19M to 43.65M.

A String of many NUL bytes costs what the unlimited split costs: `("a\0" * 1000).split("ab", 2).size`, 2,000 calls, 1.61M to 86.43M, and `("a\0" * 1000).split("ab").size` is 88.46M on master. Master's limited split stopped at the first NUL; both now search every byte behind it.

**Test.** `test/string_split_limit_nul.rb`, 13 lines; 12 differ on master. The 13th, `"PATH=/bin\0".chomp("\0").split("=", 2)`, needs the chomp commit beneath.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [ ] Depends on: #____ ("tr_s, scan, format, lines and eight more read a String to its byte length": `sp_str_find`, and the chomp commit)
