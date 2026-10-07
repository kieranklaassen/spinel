<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A fix with a cost: a `tr` or `tr_s` call whose source set is not a plain ASCII literal pays for a reading of that set, once a call and nothing a character: 134 instructions for a set of one member to 581 for `"a-zA-Z"` with gcc, 118 to 546 with clang (callgrind). A literal set that names no character twice, as `"a-z"` or `"el"`, keeps the C it had.

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

Scanning the set from its end is two lines, but `text.tr("a-z", "A-Z")` on English text then costs 30% more instructions, so the scan stays and the set is looked at instead. Codegen keeps the call to `sp_str_tr` for a literal in plain ASCII that names no character twice, and for a negated one, where a repeat changes nothing (`str_tr_set_names_once`). Every other set goes through `sp_str_tr_any` / `sp_str_tr_s_any`: they read the set in place, and only when a character does repeat they hand `sp_str_tr` the two sets rewritten without its earlier positions. The two are in `lib/sp_string.c` because `lib/sp_str.c` sits at gcc's inline limit, where one more call changes how `sp_str_concat3` is compiled; `lib/sp_str.c` is untouched.

Not here: `tr!` answers nil when the text comes out the same, where CRuby answers the receiver once a character was in the set (`"abc".dup.tr!("a", "a")`). `"hello".tr("^l", "αβγ")` is `"γγllγ"` before and after; CRuby 3.3.6 prints `"\xB3\xB3ll\xB3"` for it. `delete`, `squeeze` and `count` only ask whether a character is in the set, and were right.

Test: `test/string_tr_repeated_source.rb` (16 of its 24 lines are wrong on master). The generated C of 8 corpus tests changes, each through a `tr` whose set is not such a literal; all pass.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
