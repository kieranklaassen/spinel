<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`slice!` on a String could leave the wrong text behind:

```ruby
big = 0
keep = []
a = "ab" * 2_000
1_000.times do |i|
  s = a + "<#{i}>" + a
  keep << s.slice!(4_000, i.to_s.size + 2)
  big += 1 unless s == a + a
end
p big        # 0 in Ruby; 15 on master, with gcc and with clang
```

`slice!` with an Integer, a start and a length, or a Range rebuilds the receiver from what is left of it. All four arms wrote that as one C expression:

```c
s = sp_str_concat(sp_str_sub_range(s, 0, i), sp_str_sub_range(s, i + n, len - i - n));
```

Whichever piece C evaluates first is held by nothing while the other is allocated. `emit_slice_bang_rejoin` now writes the join for the four arms, with the head in a rooted temp:

```c
const char *_t5 = sp_str_sub_range(s, 0, i); SP_GC_ROOT_STR(_t5); s = sp_str_concat(_t5, sp_str_sub_range(s, i + n, len - i - n));
```

Nothing is read or evaluated earlier than before. Calling `sp_str_splice_at` with an empty replacement, which holds its pieces already, was tried first and rejected: it makes one more allocation and cost 392 instructions a call where the temp costs 9.

`test/string_slice_bang_pieces_root.rb` slices through ten forms and runs the long rounds above. On master (dafa0d047, gcc and clang) it is wrong in a plain run and aborts at `SPINEL_GC_STRESS=2`. It is added to `GC_STRESS_TESTS`.

Not in this change: `s[i] = v` as a statement joins three pieces in one expression in the same way and is wrong in a plain run with long Strings, as on master.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on dafa0d047)
- [ ] Depends on: # (nothing)
