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

tr_s also asked the C string whether its set is negated, so `"^\0"` was not. With the String walked whole that would have turned `"a\0b".tr_s("^\0", "x").bytes` from [97] into [97, 120, 98]; the set is read by its length in the same commit, and the answer is CRuby's [120, 0, 120].

Cost by callgrind, a gcc build and a clang build: `sum("")` is 17% cheaper on both. `format` with 85 literal bytes in its template +3.5% (gcc; clang -0.4%), chomp +3.1% (clang, 9 instructions a call; gcc -0.3%), chr +2.1% (clang, 4 a call; gcc -0.1%), tr_s +0.9% (gcc; clang -1.3%), a short `format` and a Regexp split under 0.5%.

Measured on master a3941433, CRuby 3.3.6: 4,064 lines (508 calls that answer a String or an Array of them, on four Strings, each as a literal and held in a variable). Right before and after 3,266; wrong made right 288; right made wrong 0. 366 are wrong before and after, each with the line it had: 142 that the next pull request cures; sub and gsub with a block (112), codepoints (16), delete_prefix (32) and split with a limit (32) past a NUL, each a fix of its own; `start_with?` over a NUL (12); and 20 that no short length causes (`pack("H*")`, `Symbol#inspect`, `tr_s("^a", ...)` over wide characters, `gsub("") { }` on a multibyte String, `bytesplice`). 144 do not build, raise or stop, before and after. Under `SPINEL_GC_STRESS=2`: 286 made right, none lost; 92 stop, before and after.

**Not here.**

- `printf("a\0b%s\n", "c")` writes "a": Kernel#printf writes its String with `fputs`.
- tr, delete, squeeze and count do not take the set `"^\0"` for a negated one, before and after: they read it as the two characters, so `"a\0bb".delete("^\0").bytes` is [97, 98, 98] for CRuby's [0]. A set that holds a NUL elsewhere (`"\0b"`) is read right.
- CRuby's tr_s with a negated set leaves a character above U+00FF alone; here it is translated, before and after. So one wrong answer changes into another:

  ```ruby
  p "é\0日".tr_s("^\0", "x").bytes   # CRuby [120, 0, 230, 151, 165]. master [195, 169], this branch [120, 0, 120]
  p "é-日".tr_s("^-", "x").bytes     # CRuby [120, 45, 230, 151, 165]. master [120, 45, 120]
  ```

  The first now prints what master prints for any other byte in the NUL's place.
- scan, lines with a separator and sub and gsub with a Hash search with `strstr`: the next pull request, with its cost. sub and gsub with a block lose the subject's tail past a NUL: another pull request's.
- `test/string_split_regexp_nul_field.rb` passes plain and under `SPINEL_GC_STRESS=1`. Under `SPINEL_GC_STRESS=2` every Regexp split stops in the collector on master, before and after (`sp_re_split_limit` does not root its Array), so the test is not in `GC_STRESS_TESTS`.
- A String Range compares with `strcmp`, so a method that answered a short String could give CRuby's answer by chance:

  ```ruby
  p ("a-b\0".."a-bz").cover?("a\0b".tr_s("\0", "-"))   # CRuby false. master false, this branch true
  p ("a-b\0".."a-bz").cover?("a-b")                    # CRuby false. master true, this branch true
  ```

  The first printed false only because tr_s answered "a". With tr_s whole it prints what master prints for the literal. In a sweep on master 5390d300 of 3,950 Strings made by methods that cut at a NUL and put to cover?, ===, `when`, max and minmax, 120 lines change this way here (tr_s 48, sum 60, a Regexp split 12), each byte for byte the line master prints for the literal. The compare is fixed in a pull request of its own that depends on this one.

**Tests.** Seven files, 57 lines; 53 differ on master, and every file fails there.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [ ] Depends on: # (nothing)
