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
p bad          # 0 in Ruby; 285 on master in a plain run, with gcc and with clang
```

and under `SPINEL_GC_STRESS=2` whatever their size:

```ruby
3.times do |i|
  s = +"qrst"
  s.replace("a" + i.to_s)
  p s          # "\xDB\xDB" on master at level 2; "a0", "a1", "a2" in Ruby
end
```

The statement form of `replace` (`str_mutate_reassign_arms`, `src/codegen_stmt.c`) copies its source into a new String:

```c
{ const char *_t1 = <source>; lv_s = sp_str_from_bytes(_t1, sp_str_byte_len(_t1)); }
```

A source that only `_t1` holds is held by nothing while `sp_str_from_bytes` allocates the copy. That is a concatenation, a join or a method's result, and it is also a String two names hold: reading such a local or instance variable as the source makes a copy,

```c
{ const char *_t3 = (..., lv_t ? sp_str_concat(sp_String_cstr(lv_t), "") : NULL); lv_s = sp_str_from_bytes(_t3, sp_str_byte_len(_t3)); }
```

so `t = +"sh"; u = t; u << i.to_s; s.replace(t)` and `@s.replace(@t)` failed the same way.

The temp is now rooted, `SP_GC_ROOT(_t1);`, unless the source is a literal, a constant, `self`, or a local or an instance variable that is read where it stands (`strbuf_slot_ref` says which of those are read as a copy). The root sits inside the statement's own block: nothing is read or evaluated earlier than before.

The source is not sent through `sp_str_dup` instead, which roots its argument: that would turn the `""` a nil String-or-nil source reads as into nil. Two programs with a nil source answer the same before and after.

`test/string_replace_fresh_source_root.rb` replaces 300 times through each of seven forms (a concatenation, a join over a block, a method's result, a global receiver, a local two names hold, an instance variable two names hold, an instance variable receiver) and counts the Strings that came out wrong. On master (ab9b925aa, Linux x86-64, gcc and clang) all 2,100 are wrong at level 2; with the test's short Strings a plain run (200,000 rounds tried) and level 1 are right. Larger Strings fail in a plain run on master: the 8,000-byte example above is wrong 285 times of 300, the same through a method (`def emit(s, i) = s.replace(s + "")`), and `t.replace("r" * 20_000 + t)` 536 times of 20,000, with gcc and clang alike on ab9b925aa and on 5c2dea515; all three print 0 with this change. With this change it prints 0 at plain, level 1, level 1 with `SPINEL_GC_VERIFY=1` and level 2 with both compilers. The test is added to `GC_STRESS_TESTS`, the only leg that fails without the fix. The `.expected` file was written with CRuby 3.3.6 run with `--enable-frozen-string-literal`; CRuby 4.0.7 with the same flag prints it byte for byte.

Measured with both compilers built on ab9b925aa (the branch merged with it):

- Generated C: 2 of the 5,797 programs in `test/*.rb` change (`string_replace_boxed_argument`, `string_replace_prepend_insert_clear`), each by that one root; the 64 programs in `benchmark/`, the 156 package tests and optcarrot are byte-identical.
- Cost (callgrind, 200,000 replaces): a source made in place, `s.replace(made(i))`, 115,222,115 to 118,037,602; a String two names hold, 73,312,323 to 76,112,328: 14 instructions a replace each. A plain local source generates the C it did (24,678,599 both).

Not in this change: `replace` with its value taken (`x = s.replace(...)`) already goes through `sp_str_dup` and is right. `s.replace(x) << "!"` as a statement loses the append, and a nil source replaces with `""` where Ruby raises TypeError: the same before and after.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on ab9b925aa)
- [ ] Depends on: # (nothing)
