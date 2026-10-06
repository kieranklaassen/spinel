<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A String replaced from a source made in place came out as freed memory, in a plain run when the Strings are large:

```ruby
$g = "abcdefgh" * 1_000
want = "abcdefgh" * 1_000
bad = 0
300.times do
  $g.replace($g.dup)
  bad += 1 unless $g == want
end
p bad          # 0 in Ruby; 285 on master, with gcc and with clang
```

and under `SPINEL_GC_STRESS=2` whatever their size, with exit 0:

```ruby
3.times do |i|
  s = +"qrst"
  s.replace("a" + i.to_s)
  p s          # "a0", "a1", "a2" in Ruby; "\xDB\xDB" three times on master at level 2
end
```

The statement form of `replace` (`str_mutate_reassign_arms`, `src/codegen_stmt.c`) copies its source into a new String:

```c
{ const char *_t1 = <source>; lv_s = sp_str_from_bytes(_t1, sp_str_byte_len(_t1)); }
```

A source that only `_t1` holds is held by nothing while `sp_str_from_bytes` allocates the copy. The temp is now rooted, unless the source is a literal, a constant, `self`, or a local or an instance variable read where it stands. The root sits inside the statement's own block, so nothing is read or evaluated earlier than before.

One decision: the source is not sent through `sp_str_dup` instead, which roots its argument. That would turn the `""` a nil source reads as into nil.

`test/string_replace_fresh_source_root.rb` replaces through seven forms and counts the Strings that came out wrong. On master (dafa0d047, gcc and clang) it is right in a plain run and at level 1, and counts every one wrong at level 2 with exit 0. It is added to `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on dafa0d047)
- [ ] Depends on: # (nothing)
