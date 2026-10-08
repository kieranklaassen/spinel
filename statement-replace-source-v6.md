<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** A String replaced from a source made in place came out as freed memory, in a plain run when the Strings are large. The cost is on `replace` as a statement with an element, a Hash value or a reader's answer as its source: 15 instructions a statement with gcc and 13 to 14 with clang (the numbers are below). Every other source that master ran right runs master's C.

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

The same with an object that answers `to_str`:

```ruby
class Named
  def initialize(s) = @s = s
  def to_str = @s + "!"
end
o = Named.new("abcdefgh" * 1_000)
want = "abcdefgh" * 1_000 + "!"
s = +"start"
bad = 0
300.times do
  s.replace(o)
  bad += 1 unless s == want
end
p bad          # 0 in Ruby; 4 on master, with gcc and with clang
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

A source that only `_t1` holds is held by nothing while `sp_str_from_bytes` allocates the copy: a concatenation, a join, a method's result, the copy a String two names hold is read as, and the String an object's `to_str` makes. The temp is now rooted, inside the statement's own block, so nothing is read or evaluated earlier than before.

It is not rooted where a list says something else holds the source (`replace_source_is_held`): a literal, a constant, `self`, a local, an instance variable or a global read where it stands, and a choice between two of those (`c ? t : K`, `t || K`). For those the generated C is master's.

One decision: the source is not sent through `sp_str_dup` instead, which roots its argument. That would turn the `""` a nil source reads as into nil.

Cost, callgrind on 3d629868d, 200,000 statements each, before and after:

| source | gcc | clang |
|---|---|---|
| `"lit"` | 57,712,034, the same | 58,692,543, the same |
| `y` (a local) | 59,712,027, the same | 59,692,558, the same |
| `$g` | 63,509,812, the same | 63,491,048, the same |
| `i.odd? ? y : K` | 62,201,286, the same | 62,281,830, the same |
| `y \|\| K` | 59,712,026, the same | 59,692,558, the same |
| `ar[0]` | 60,912,027 to 63,914,425 | 61,292,544 to 63,894,929 |
| `ar.first` | 60,912,027 to 63,914,425 | 61,292,558 to 63,894,943 |
| `h[:k]` | 64,512,027 to 67,514,425 | 64,292,660 to 67,095,045 |
| `o.name` | 59,712,027 to 62,714,254 | 59,692,558 to 62,494,772 |

The last four keep the root. Each is a call's answer: it is held only where the program defines none of `[]`, `first` and the reader itself, and that is not known where this statement is written.

On master 9c7ea3ce0 the generated C of two of the 6,512 programs under `test/`, `benchmark/` and `packages/*/test/` gains the root, `string_replace_boxed_argument` and `string_replace_prepend_insert_clear`; both print their `.expected` in the seven lanes below. Every other program's C is unchanged, optcarrot's among them.

`test/string_replace_fresh_source_root.rb` replaces through ten forms and counts the Strings that came out wrong. On master (3d629868d, gcc and clang) it is right in a plain run and at level 1, and counts 2,850 of its 3,000 wrong at level 2 with exit 0 (the other 150 take the literal side of a choice). With this change it prints its `.expected` in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang, and the same with `--share-strings`. It is added to `GC_STRESS_TESTS`.

**Not in this change:** a String made in place as the receiver of the program's own String method (`("se" + i.to_s).into(r)` with `def into(q); q.replace(self); q; end`) is held by nothing inside the method, with or without a `replace` there. That is the call's fault, on master and here.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master 9c7ea3ce0, built from nothing: the test in the seven collector lanes with gcc and clang, with and without `--share-strings` (master is wrong at `SPINEL_GC_STRESS=2` with exit 0; this change is right in every one); `ruby tools/gate.rb check`; the generated C of the 6,512 programs, changed in the two named above, which print their `.expected` in the seven lanes; optcarrot, checksum 59662; `make share-strings-test` and `make int-min-test`, both pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal` (`0`, `"g299"` and `"i299"`); CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change. It depends on no other pull request.
