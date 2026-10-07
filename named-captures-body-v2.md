<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`MatchData#named_captures` answers one group's text under another group's name, in a plain run:

```ruby
m = ("ab" * 100 + " " + "cd" * 100).match(/(?<a>\w+) (?<b>\w+)/)
keep = []
2000.times { keep << m.named_captures }
p keep.map { |h| h.values.map { |v| v[0, 2] } }.uniq
```

```
spinel diff: output-diff
  program: named_captures.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[["ab", "cd"]]
+[["ab", "cd"], ["ab", "ab"]]
```

On this branch `spinel diff` reports `same`.

Cost (callgrind, instructions a call, the receiver in a local, compiled with gcc): `named_captures` takes 18 more with one named group (1,328 to 1,346) and 46 more with five (3,958 to 4,004); `named_captures(symbolize_names: true)` takes 13 more and `deconstruct_keys([:w])` 19 more. Compiled with clang the four are 30, 94, 14 and 13. `captures`, `names`, `to_a` and `m[:w]` cost what they did.

Two faults in the builders of `lib/spinel_rt.h`, cured in one commit:

- **A group's text under another name.** `sp_md_named_captures` passed the name's copy and the group's text to `sp_StrPolyHash_set` as two arguments of one call; both are fresh Strings, and the one built first was freed while the other was built. gcc builds the text first (the report above); clang builds the name first, and with short texts a Hash then holds a text as its own name. `sp_md_named_captures_sym` lost the text the same way when `sp_sym_intern` allocated a new name. The name is now built first, into a rooted local for the String keys and as a Symbol for the others, and the text goes straight into the store. One root a group is enough, because `sp_StrPolyHash_set` holds both across its own allocation: 1,346 and 4,004 instructions a call, against 1,362 and 4,080 with the text in a rooted local too.
- **A temporary MatchData freed under the builder.** `sp_md_named_captures`, `sp_md_named_captures_sym` and `sp_md_deconstruct_keys` allocate a Hash and then each group's text, and nothing held the MatchData they read. As the call's own temporary (`s.match(re)`, `re.match(s)`, `$~`) a collection inside the call freed it: a loop of 6,000 `s.match(re).named_captures(symbolize_names: true)` that reads each Hash a few rounds later crashes in a plain run, compiled with gcc or with clang. The three now root `m`.

They are one commit because the receiver's root alone leaves a wrong answer where master crashed: a loop of `s.match(re).named_captures` then runs to the end and, compiled with gcc, 3 of its 6,000 Hashes hold a wrong text.

No generated C changes (`tools/cident.sh`: 6404 identical, 0 differ).

Not here: a MatchData read out of an Array or a Hash answers `{}` for `named_captures` and `[]` for `names`, and raises NoMethodError for the Symbol-keyed forms. Three more answers are master's own in a plain run and stay: after `re.match(s)` as a statement of its own `$~.named_captures` prints `{}`; two groups of one name (`/(?<a>x)\d|(?<a>y)\d/` on `"x1"`) answer `{"a" => nil}`; and `h["a"] << "!"` on the answered Hash leaves the value as it was. At `SPINEL_GC_STRESS=2` master crashed in each through the two faults above, not through a check.

Tests: `test/matchdata_named_captures_rooted.rb` and `test/matchdata_named_captures_temp_receiver.rb`. On master a plain run of the first prints 6 and 97 for its first two zeros compiled with gcc, 2 and 0 with clang, and then crashes; the second crashes before its first line. Both print their expected output here at `SPINEL_GC_STRESS` unset, 1 and 2, with gcc and with clang.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
