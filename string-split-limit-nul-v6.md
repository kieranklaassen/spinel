<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**Cost, first: a fix with a stated cost, and whether it is worth that is your call.** A limited split of a String of many NUL bytes whose separator is not found runs about 54 times master's instructions: `s = "a\0" * 1000`, 2,000 times `s.split("ab", 2).size`, is 1,610,631 instructions on master and 86,386,270 here (gcc build; clang 1,552,939 and 84,286,597). It is linear in the String, and about what the unlimited split of the same String costs on master (88,456,140). master's count is right there, 1 each time, only because it stops at the first NUL; the field it answers is 1 byte long where CRuby's is 2,000.

With no NUL in the String the worst is a separator of two bytes or more that is not found, which pays one `strlen`: `"key=value and more".split(": ", 2)` +6.0% gcc and +5.1% clang (31 and 25 instructions a call), `"ab".split("abc", 2)` +5.8% and +4.9%. Found: `"one::two:three::four::five".split("::", 3)` +4.6% and +5.3%, `"key: value: more".split(": ", 2)` +4.6% and +4.8%, `"hello, world".split("", 4)` +2.5% and +1.4%, `"alpha,beta,gamma,delta".split(",", 3)` -1.7% and -1.3%. A 2,000-byte field before a one-byte separator is 25% cheaper on both.

```ruby
p "x,a\0b".split(",", 2)     # CRuby ["x", "a\u0000b"]. Here: ["x", "a"]
p "a\0b\0c".split("\0", 2)   # CRuby ["a", "b\u0000c"]. Here: ["a"]
p "a\0".split("", 5)         # CRuby ["a", "\u0000", ""]. Here: ["a"]
```

`sp_str_split_limit`'s arm for a positive limit read the String with `strlen` and sought the separator with `strstr`, where the unlimited split (`sp_str_split_into`) reads byte lengths and searches by bytes. A field after a NUL was lost, and a separator that starts with a NUL was taken for the empty one. The arm reads byte lengths now and finds the separator with `sp_str_find`, from the pull request beneath. A separator of one byte is found by `memchr`. A longer one is sought by `strstr` as before, and only where that finds nothing and a NUL lies inside the String is the rest searched by `sp_bytestr`. A separator that holds a NUL goes by `sp_bytestr` from its first hit. `lib/sp_str.c` only; no program's generated C changes.

Measured on master a3941433, CRuby 3.3.6, gcc and clang alike: 30,005 lines (21 Strings, 6 ways of holding one, 12 separators, 7 limits, 7 uses of the result). Right before and after 18,084; wrong made right 11,759 (25 of them by the pull request beneath); right made wrong 0. 162 are wrong before and after: 104 print the right bytes now, as UTF-8 where CRuby keeps the String binary, and 58 print the line they printed. Under `SPINEL_GC_STRESS=2` 45 of the 51 programs stop at their first Regexp split with a limit, before and after (`sp_re_split_limit` does not root its Array); of the lines printed up to there 11,741 are made right and none is lost.

**Not here.**

- An append to an element of a split's Array is lost, before and after, so one program that raised prints a wrong line:

  ```ruby
  r = "\0\0x".split("\0\0", 2); r[0] << "Z"; p r   # CRuby ["Z", "x"]. master raises FrozenError, this branch prints ["", "x"]
  r = ",x".split(","); r[0] << "Z"; p r            # CRuby ["Z", "x"]. master prints ["", "x"]
  ```

  master answered an empty Array, so `r[0]` was nil and `<<` raised; with the two fields found, the program reaches the line master prints for any other split.
- A String Range compares with `strcmp`, so a split that answered a short field could give CRuby's answer by chance:

  ```ruby
  p ("b\0".."bz").cover?("a\0b".split("\0", 2).last)   # CRuby false. master false, this branch true
  p ("b\0".."bz").cover?("b")                          # CRuby false. master true, this branch true
  ```

  The first printed false only because the split answered one field, "a". With "b" it prints what master prints for the literal. In a sweep on master 5390d300 of 3,950 Strings made by methods that cut at a NUL and put to cover?, ===, `when`, max and minmax, 62 lines change this way here, each byte for byte the line master prints for the literal. The compare is fixed in a pull request of its own that depends on this one.

**Test.** `test/string_split_limit_nul.rb`, 13 lines; 12 differ on master, and the 13th is right before and after.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [ ] Depends on: #____ ("scan, lines and sub and gsub with a Hash find a String pattern by bytes": `sp_str_find`)
