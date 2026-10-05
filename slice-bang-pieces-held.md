<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`slice!` on a String could leave the wrong text behind. With long pieces a plain run shows it:

```ruby
big = 0
keep = []
a = "ab" * 2_000
1_000.times do |i|
  s = a + "<#{i}>" + a
  keep << s.slice!(4_000, i.to_s.size + 2)
  big += 1 unless s == a + a
end
p big        # 0 in Ruby; master prints 11, with gcc and with clang
```

With short Strings a plain run is right and the stress lane stops the program:

```ruby
s = "qrstuvwxyz" + 1.to_s
s.slice!(3)
p s          # master at SPINEL_GC_STRESS=2: "the mark reached a freed heap string"; "qrsuvwxyz1" in Ruby
```

`slice!` with an Integer, a start and a length, or a Range rebuilds the receiver from what is left of it. All four arms (two for a statement in `src/codegen_stmt.c`, two for the value in `emit_op_string_slice`, `src/codegen_call_string.c`) wrote that as one C expression:

```c
s = sp_str_concat(sp_str_sub_range(s, 0, i), sp_str_sub_range(s, i + n, len - i - n));
```

Whichever piece C evaluates first is held by nothing while the other is allocated: `sp_str_concat` roots its parameters only once entered. `sp_str_splice_at` in `lib/sp_cold.c` has the same two pieces and a comment on exactly this.

`emit_slice_bang_rejoin` now writes the join for the four arms. The head goes into a rooted temp, and the tail is made inside the call:

```c
const char *_t5 = sp_str_sub_range(s, 0, i); SP_GC_ROOT_STR(_t5); s = sp_str_concat(_t5, sp_str_sub_range(s, i + n, len - i - n));
```

Nothing is read or evaluated earlier than before: the index, the length and the receiver's length are computed first as they were, and the two pieces are made where the one expression stood. An index held boxed (`emit_string_slice_poly`) re-enters the same arms, so it is covered.

The temp costs 9 instructions a call (callgrind, 200,000 calls of `s.slice!(3)`: 268,965,918 on master, 270,765,867 with this change). Calling `sp_str_splice_at` with an empty replacement was built first and measured on an earlier master: it makes one more allocation and cost 392 instructions a call.

`test/string_slice_bang_pieces_root.rb` slices 300 times through each of ten forms (Integer, start and length, Range; as a statement and with the removed part taken; through a second name; by an Integer and a Range held boxed) and counts the results that are not Ruby's, then runs the 1,000 long rounds above. On master (1ed8b0fbd and 92510d6c1, Linux x86-64, gcc and clang) the long rounds answer 11 wrong in a plain run and 121 at level 1, and each of the ten short forms alone aborts at level 2. With this change the test prints Ruby's output at every level. So it fails without the fix in the ordinary test leg, and it is added to `GC_STRESS_TESTS` for the short forms, which only that leg shows.

Short Strings are not safe below level 2 either: of 87 one-form programs with 10-character Strings (a local, an Array element and an instance variable as the receiver), 19 are right in a plain run on master and print a wrong answer at level 1, exit 0. All 19 are right with this change.

Measured with both compilers built on 1ed8b0fbd: the generated C of 24 of the 5,780 programs in `test/*.rb` changes, by that temp and the temp numbers after it, and so does that of 15 tests of `packages/openssl`, whose own Ruby calls `slice!`; the 64 programs in `benchmark/` and optcarrot are byte-identical. All 24 pass in a plain run and at level 1 before and after. At level 2, 8 of them fail on master and 5 with this change: `issue_3084`, `string_slice_bang_value_rooted` and `string_slice_bang_empty` now pass, and the other five stop on another call.

Not in this change, and wrong on master and here alike: `insert` and `s[i] = v` as statements, which join three pieces in one expression in the same way, and `slice!(/re/, n)`, which joins two `sp_str_byteslice` pieces so. With long pieces a plain run shows them too (1,000 rounds on 8,001 characters, the results kept: `s[4_000] = "<#{i}>"` 104 wrong, `s.insert(4_000, "<#{i}>")` 1, `s.slice!(/(<)(\d+>)/, 2)` 1).

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it is `0`, four Strings, `0` and `1000`)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on 1ed8b0fbd)
- [ ] Depends on: # (nothing)
