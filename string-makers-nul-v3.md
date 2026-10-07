<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**Cost, first: a fix with a stated cost.** By callgrind on master a2bd8900, instructions a call, a gcc build then a clang build. tr_s: +9 (+0.6%) on short Strings, +77 (+0.9%) on 176 bytes and +516 (+1.2%) on 880 with gcc; with clang it is cheaper (-3.8%, -8.8%, -9.2%). tr_s! +10 (+0.6%), -2.9%. `format` with 85 literal bytes in its template +67 (+3.5%), -0.4%; a short `format` +0.3%, +0.4%. chomp -0.3%, +9 (+3.1%). chr -0.1%, +4 (+2.1%). A Regexp split +0.1%, +0.4%. `sum("")` is 17% cheaper on both.

```ruby
p "PATH=/bin\0".chomp("\0").bytesize     # CRuby 9. Here: 10
p "a\0b".tr_s("a", "z").bytes            # CRuby [122, 0, 98]. Here: [122]
p ["a\0b", "c"].sum("").bytes            # CRuby [97, 0, 98, 99]. Here: [97, 99]
p "\0ab".chr.bytes                       # CRuby [0]. Here: []
p format("a\0b%s", "c").bytes            # CRuby [97, 0, 98, 99]. Here: [97]
p "a,\0x".split(/,/).map(&:bytes)        # CRuby [[97], [0, 120]]. Here: [[97]]
p ARGF.read.bytes                        # stdin "a\0b\n": CRuby [97, 0, 98, 10]. Here: [97]
```

Each of the seven measured a String by `strlen`, or took a first byte of NUL for the empty String, where the String's header holds its byte length. Seven commits, one a method, each with its test; each message names the function and the cause.

Three more answers of tr_s come with its walk, in the same commit, because the cut at the NUL had hidden them.

- tr_s asked the C string whether its set is negated, so `"^\0"` was not. The set is read by its length: `"a\0b".tr_s("^\0", "x").bytes` is CRuby's [120, 0, 120], where the walk alone would have turned [97] into [97, 120, 98].
- tr_s! answered nil when the text came out as it went in. CRuby answers nil when no character of the set was met, so `s.tr_s!("b", "b")` is the String. For `"a\0b"` master's cut text differed and its answer was right; walked whole it would have been nil. `sp_str_tr_s` now says whether it met one, and the three places in `src/codegen_call_recv.c` that emit tr_s! ask it beside the comparison. `"a-b".dup.tr_s!("b", "b")`, nil on master, is the String too.
- A character the set names twice is translated by its last naming, as in CRuby: `"aa".tr_s("aa", "xy")` was "x" for "y", and `"a\0a".tr_s("aa", "xy").bytes` would have gone from [120] to [120, 0, 120] for [121, 0, 121].

Measured on master a2bd8900 against CRuby 3.3.6.

- 4,064 lines (508 calls that answer a String or an Array of them, on four Strings, each as a literal and held in a variable). Right before and after 3,266; wrong made right 288; right made wrong 0. 366 are wrong before and after, and in these lines each prints what it printed: 142 that scan, lines and sub and gsub with a Hash cut at a NUL, the pull requests above this one; sub and gsub with a block (112), codepoints (16), delete_prefix (32) and split with a limit (32) past a NUL, each a fix of its own; `start_with?` over a NUL (12); and 20 that no short length causes (`pack("H*")`, `Symbol#inspect`, `tr_s("^a", ...)` over wide characters, `gsub("") { }` on a multibyte String, `bytesplice`). 144 do not build, raise or stop, before and after. Under `SPINEL_GC_STRESS=2`: 286 made right, none lost; 92 stop, before and after.
- 3,920 lines of tr_s and tr_s! (8 Strings, 14 from-sets, 5 to-sets; the answer's bytes, and tr_s!'s nil and its receiver as a local, a shared String, a boxed value and an instance variable), with gcc and with clang, plain and under `SPINEL_GC_STRESS=2` alike: right before and after 1,014; wrong made right 2,822; right made wrong 0. The other 84 are the String with wide characters under a negated set, below: 28 print what they printed and 56 another wrong line.

**Not here.**

- CRuby's tr_s with a negated set leaves a character above U+00FF alone; here it is translated, before and after. So one wrong answer changes into another, the first now being what master prints for any other byte in the NUL's place:

  ```ruby
  p "é\0日".tr_s("^\0", "x").bytes   # CRuby [120, 0, 230, 151, 165]. master [195, 169], this branch [120, 0, 120]
  p "é-日".tr_s("^-", "x").bytes     # CRuby [120, 45, 230, 151, 165]. master [120, 45, 120]
  ```
- tr_s writes a byte that is not UTF-8 as the character of that number, before and after: `"a-\xffb".b.tr_s("b", "c").bytes` is [97, 45, 195, 191, 99] for CRuby's [97, 45, 255, 99]. Behind a NUL the byte is now reached: `"a\0\xffb".b.tr_s("b", "c").bytes` goes from [97] to [97, 0, 195, 191, 99].
- tr still takes a character's first naming (`"aa".tr("aa", "xy")` is "xx"), and tr! still answers nil for a character translated to itself. tr, delete, squeeze and count do not take the set `"^\0"` for a negated one: `"a\0bb".delete("^\0").bytes` is [97, 98, 98] for CRuby's [0].
- `[s, "def"].sum("")` drops `s` when it is a String shared by reference in a boxed Array, before and after: that is `sp_PolyArray_sum_str`, not the function this mends.
- `printf("a\0b%s\n", "c")` writes "a": Kernel#printf writes its String with `fputs`.
- scan, lines with a separator and sub and gsub with a Hash search with `strstr`: the next pull request, with its cost. sub and gsub with a block lose the subject's tail past a NUL: another pull request's.
- `test/string_split_regexp_nul_field.rb` passes plain and under `SPINEL_GC_STRESS=1`. Under `SPINEL_GC_STRESS=2` a Regexp split that finds its separator stops in the collector on master, before and after (`sp_re_split_limit` does not root its Array), so the test is not in `GC_STRESS_TESTS`.
- A String Range compares with `strcmp`, so a method that answered a short String could give CRuby's answer by chance:

  ```ruby
  p ("a-b\0".."a-bz").cover?("a\0b".tr_s("\0", "-"))   # CRuby false. master false, this branch true
  p ("a-b\0".."a-bz").cover?("a-b")                    # CRuby false. master true, this branch true
  ```

  The first printed false only because tr_s answered "a". With tr_s whole it prints what master prints for the literal. In a sweep on master a2bd8900 of 3,950 Strings made by methods that cut at a NUL, each put to cover?, ===, `when`, max, min and minmax (43,450 lines), 128 lines of cover?, === and `when` change this way here (tr_s 56, sum 60, a Regexp split 12). 43 lines of max, min and minmax print a wrong line where master printed none: in 39 its walk from the short String ran out of time or memory (format 23, tr_s 12, sum 4), and in 4 it raised RangeError for the empty String a Regexp split had cut a field to. Each of the 171 is byte for byte the line master prints for the literal. The compare is "cover?, === and max of a String Range compare the whole String", a pull request of its own that depends on this one.

**Tests.** Seven files, 63 lines; 53 differ on master, and every file fails there.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
