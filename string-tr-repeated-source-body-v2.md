<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A fix with a cost: a `tr` or `tr_s` call whose source set the program computes (a variable, a constant, an interpolation) pays for one reading of that set, once a call and nothing a character: 136 instructions for a set of one member to 586 for `"a-zA-Z"` with gcc, 131 to 580 with clang (callgrind). A computed set of characters past ASCII that do not ascend has its runs compared as well: 630 for the full-width `"０-９ａ-ｚＡ-Ｚ"`, and a set of 21,000 kanji in no order costs under twice its call. A computed set that does name a character twice is rewritten: 1,630 more for `"ll"` with gcc, 1,557 with clang. A call with a literal set adds nothing at run time, and one that was right keeps the C it had; the one exception is a `tr!` like `s.tr!("hh", "Hh")`, which looks for `h` in the receiver when the text comes out the same (149 instructions).

```ruby
p "hello".tr("ll", "xy")
```

```
spinel diff: output-diff
  program: tr.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"heyyo"
+"hexxo"
```

CRuby fills its translation table left to right, so a character the source set names more than once is translated by its last position; `sp_str_tr` and `sp_str_tr_s` stop at the first match. The repeat can be a range and a character it holds: `"hello".tr("a-yl", "b-zX")` is `"ifXXp"` and was `"ifmmp"`. `tr!`, `tr_s`, `tr_s!`, a set that is computed and a boxed receiver were wrong the same way.

Scanning the set from its end is two lines, but `text.tr("a-z", "A-Z")` on English text then costs 30% more instructions, so the scan stays and the sets are looked at instead. A literal set is read at compile time, as the runtime reads it (`str_tr_sets`: escapes, ranges, characters of more than one byte):

- No character twice, a negated set, or a repeat whose positions have the same replacement (`"ll"` to `"xx"`, `"a-za-z"` to `"A-ZA-Z"`, any set with an empty replacement): the first position answers as the last would, and the call is what it was.
- A repeat that matters, beside a literal replacement: the replacement is written out with each position of a repeated character given the replacement of its last. `"hello".tr("ll", "xy")` compiles to `sp_str_tr(s, "ll", "y")`.
- Every other call (a set the program computes, or a literal set that repeats beside a computed replacement) goes through `sp_str_tr_any` / `sp_str_tr_s_any`: they read the set once, in place, and only when a character does repeat they hand `sp_str_tr` the two sets rewritten without its earlier positions. A set is never searched member against member: its runs ascend, or its ASCII members are told by a table, or its runs are compared.

`tr!` and `tr_s!` answer nil when the text comes out the same, which their callers ask by comparing the texts. `s.tr!("hh", "Hh")` answered the receiver, as CRuby does once a character was in the set, only because the first match changed the text. So where a call is rewritten, the test asks as well whether such a character was there: for literal sets the members that are their own replacement are looked for in the receiver (where there are none, nothing is added), and `sp_str_tr_any` says it in `sp_str_tr_matched`.

The functions are in `lib/sp_string.c` because `lib/sp_str.c` sits at gcc's inline limit, where one more call changes how `sp_str_concat3` is compiled; `lib/sp_str.c` is untouched.

Not here: where the call is what it was, `tr!` still answers nil when the text comes out the same and CRuby answers the receiver (`"abc".dup.tr!("a", "a")`). `"hello".tr("^l", "αβγ")` is `"γγllγ"` before and after; CRuby 3.3.6 prints `"\xB3\xB3ll\xB3"` for it. `delete`, `squeeze` and `count` only ask whether a character is in the set, and were right.

Test: `test/string_tr_repeated_source.rb` (23 of its 46 lines are wrong on master; the others hold what master had right). The generated C of one corpus test changes, `test/splat_builtin_predicate_family.rb`, whose `tr` takes its sets from a splat; it passes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
