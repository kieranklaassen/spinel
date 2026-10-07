<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p "PATH=/bin\0".chomp("\0").bytesize     # CRuby 9. Here: 10
p "a\0b".tr_s("a", "z").bytes            # CRuby [122, 0, 98]. Here: [122]
p ["a\0b", "c"].sum("").bytes            # CRuby [97, 0, 98, 99]. Here: [97, 99]
p "\0ab".chr.bytes                       # CRuby [0]. Here: []
p format("a\0b%s", "c").bytes            # CRuby [97, 0, 98, 99]. Here: [97]
p "a,\0x".split(/,/).map(&:bytes)        # CRuby [[97], [0, 120]]. Here: [[97]]
p ARGF.read.bytes                        # stdin "a\0b\n": CRuby [97, 0, 98, 10]. Here: [97]
```

Each of the seven measured a String by `strlen`, or took a first byte of NUL for the empty String, where the String's header holds its byte length. Seven commits, one a method, each with its test; each message names the function and the cause. Only `lib/` changes, so no program's generated C changes.

Cost by callgrind, a gcc build and a clang build: `sum("")` is 17% cheaper on both. `format` with 85 literal bytes in its template +3.5% (gcc; clang -0.4%), chomp +3.1% (clang, 9 instructions a call; gcc -0.3%), chr +2.1% (clang, 4 a call; gcc -0.1%), tr_s +0.8% (gcc; clang -1.3%), a short `format` and a Regexp split under 0.5%.

Measured on master 5390d300, CRuby 3.3.6: 4,064 lines (508 calls that answer a String or an Array of them, on four Strings, each as a literal and held in a variable). Right before and after 3,266; wrong made right 288; right made wrong 0. 366 are wrong before and after: 142 that the next pull request cures; sub and gsub with a block (112), codepoints (16), delete_prefix (32) and split with a limit (32) past a NUL, each a fix of its own; `start_with?` over a NUL (12); and 20 that no short length causes (`pack("H*")`, `Symbol#inspect`, `tr_s("^a", ...)` over wide characters, `gsub("") { }` on a multibyte String, `bytesplice`). 144 do not build, raise or stop, before and after. Under `SPINEL_GC_STRESS=2`: 286 made right, none lost; 92 stop, before and after.

**Not here.**

- `printf("a\0b%s\n", "c")` writes "a": Kernel#printf writes its String with `fputs`. `"a\0bb".tr_s("^\0", "x")` is wrong before and after: a set is read as a C string.
- scan, lines with a separator and sub and gsub with a Hash search with `strstr`: the next pull request, with its cost. sub and gsub with a block lose the subject's tail past a NUL: another pull request's.
- `test/string_split_regexp_nul_field.rb` passes plain and under `SPINEL_GC_STRESS=1`. Under `SPINEL_GC_STRESS=2` every Regexp split stops in the collector on master, before and after (`sp_re_split_limit` does not root its Array), so the test is not in `GC_STRESS_TESTS`.
- A String Range compares with `strcmp`, so a method that answered a short String could give CRuby's answer by chance:

  ```ruby
  p ("a-b\0".."a-bz").cover?("a\0b".tr_s("\0", "-"))   # CRuby false. master false, this branch true
  p ("a-b\0".."a-bz").cover?("a-b")                    # CRuby false. master true, this branch true
  ```

  The first printed false only because tr_s answered "a". With tr_s whole it prints what master prints for the literal. In a sweep on master 8684d54c of 3,950 Strings made by methods that cut at a NUL and put to cover?, ===, `when`, max and minmax, 120 lines change this way here (tr_s 48, sum 60, a Regexp split 12), each byte for byte the line master prints for the literal. The compare is fixed in a pull request of its own that depends on this one.

**Tests.** Seven files, 55 lines; 51 differ on master, and every file fails there.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [ ] Depends on: # (nothing)
