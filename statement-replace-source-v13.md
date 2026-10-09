<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** A String replaced from a source made in place came out as freed memory, in a plain run when the Strings are large. The cost is on `replace` as a statement whose source is a call the list below does not look into: 7 to 20 instructions a statement with gcc and 5 to 15 with clang (the numbers are below). Master ran some of those right, and they pay it. That is any call's answer the list does not look into while something does hold it: an element under an index a call computes (`ar[idx(i)]`), an element of an element (`nn[0][0]`), an element of a block's result (`[1].map { |k| y }[0]`), a reader off an object made in place (`Item.new(y).name`), and an element, a first, a last or a reader that the program defines itself and that answers a String something holds. It is also an assignment written as the source (`s.replace(q = "a" + i.to_s)`), which the local holds once it is made, and a boxed value answered by `to_s`, `itself` or `freeze` (`h[:k].to_s`, the value of a Hash with Symbol keys): a dispatch, which makes a String for anything but a String. A literal, a variable, a constant, a field, an element and a Hash value run master's C, and so does any of them typed String and answered by its own `to_s`, `to_str`, `itself` or `freeze`.

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

It is not rooted where a list says something else holds the source (`replace_source_is_held`):

- a literal, a constant, `self`, a local, an instance variable or a global read where it stands;
- a read out of a slot that a variable, a constant or `self` holds: an `attr_reader`'s or a Struct member's field (`o.name`, `st.name`, or `name` with no receiver inside its class), an Array's element by an Integer index (`ar[0]`, `ar[i % 2]`, `ar.fetch(0)`), its `first` or its `last`, and a Hash's value (`h[:k]`, `hs["k"]`, `h.fetch(:k)`), the index or the key a literal or a read;
- one of those, typed String, answered by its own `to_s`, `to_str`, `itself` or `freeze` with no argument (`y.to_s`, `ar[0].to_s`, `hs["k"].to_s`): a String answers itself there and nothing is made (`freeze` seals it in place, or answers an immortal copy of a literal); a boxed value is not one of them, its `to_s` is a dispatch and stays rooted (`h[:k].to_s`);
- a choice between two of those (`c ? t : K`, `t || K`).

For those the generated C is master's. A slot read is on the list only while the method is the builtin. Where the program gives Array or Hash its own `[]`, `first`, `last` or `fetch`, gives String its own `to_s`, `to_str`, `itself` or `freeze`, or writes the reader by hand, the answer is a call's result (with no receiver too: `name` under `def name = @name + "!"`, and a reader over a slot the class appends to in place, which reads a copy; master was wrong on both at `SPINEL_GC_STRESS=2`), and so is `h[:k]` in a program that gives any Hash a default block (`fetch` with one key or one index runs none: a missing one raises); a boxed value (`h[:k]` out of a Hash with Symbol keys or of mixed values) is on it only where no class defines `to_str`. Each of these is rooted, and master was wrong on them at `SPINEL_GC_STRESS=2` where the method makes its String: with `class Array; def first = "f" + size.to_s; end`, `s.replace(ar.first)` was wrong there.

One decision: the source is not sent through `sp_str_dup` instead, which roots its argument. That would turn the `""` a nil source reads as into nil.

Cost, callgrind on 84f5b5020, 200,000 statements each, before and after:

| source | gcc | clang |
|---|---|---|
| `"lit"` | 56,912,012, the same | 57,492,620, the same |
| `y` (a local) | 58,712,023, the same | 58,292,688, the same |
| `$g` | 62,509,822, the same | 62,091,184, the same |
| `i.odd? ? y : K` | 61,201,295, the same | 60,881,960, the same |
| `y \|\| K` | 58,712,024, the same | 58,292,634, the same |
| `ar[0]` | 59,512,010, the same | 59,892,620, the same |
| `ar.fetch(0)` | 62,712,012, the same | 62,692,712, the same |
| `ar.first` | 59,512,024, the same | 59,892,688, the same |
| `ar.last` | 55,305,622, the same | 55,283,314, the same |
| `h[:k]` | 63,512,023, the same | 62,892,718, the same |
| `hs["k"]` | 75,538,772, the same | 75,117,843, the same |
| `h.fetch(:k)` | 68,138,773, the same | 66,317,824, the same |
| `hs.fetch("k")` | 92,138,772, the same | 92,917,833, the same |
| `o.name` | 58,712,023, the same | 58,292,688, the same |
| `st.name` | 58,938,772, the same | 58,517,855, the same |
| `y.to_s` | 58,738,772, the same | 58,717,857, the same |
| `y.to_str` | 57,538,773, the same | 58,117,855, the same |
| `y.itself` | 58,738,772, the same | 58,317,855, the same |
| `y.freeze` | 60,737,139, the same | 61,116,242, the same |
| `ar[idx(i)]` | 58,132,506 to 61,533,973 (17) | 58,110,895 to 60,712,362 (13) |
| `Item.new(y).name` | 60,938,765 to 62,340,988 (7) | 60,517,838 to 61,520,053 (5) |
| `h[:k].to_s` | 67,312,009 to 70,114,410 (14) | 67,092,677 to 69,895,061 (14) |

The last three keep the root and are right on master: an index that a call computes is not a read, an object made in place holds its field only as long as something holds the object, and a boxed value's `to_s` is a dispatch, which makes a String for anything but a String. The other sources named at the top take the same root; they are not in the table, but for the dearest of them, `h[:k].freeze` (20 and 15), and `h.fetch(:k).to_s` (16 and 13). `ar.fetch(i & 1)`, `ar[0].to_s`, `hs["k"].to_s` and a reader with no receiver inside its class (`name`) are the same too. Where a row says "the same", the two counts are equal: the generated C is.

On master 4337d93cf the generated C of two of the 6,672 programs under `test/`, `benchmark/` and `packages/*/test/` gains the root, `string_replace_boxed_argument` and `string_replace_prepend_insert_clear`; both print their `.expected` in the seven lanes below (on master the second prints poison bytes at level 2). Every other program's C is unchanged, optcarrot's among them (three print the path of the build's own directory and differ in that alone).

`test/string_replace_fresh_source_root.rb` replaces through thirteen forms and counts the Strings that came out wrong; three of the forms are the program's own `Array#first`, an element the Array holds (`ar[1]`, which must stay master's C and be right) and a reader written by hand. On master 4337d93cf (gcc and clang) it is right in a plain run and at level 1, and counts 3,450 of its 3,900 wrong at level 2 with exit 0 (150 take the literal side of a choice and 300 read the held element). With this change it prints its `.expected` in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang, and the same with `--share-strings`. It is registered for the stress lanes by its header line (`# spinel: gc-stress`).

**Not in this change:** a String made in place as the receiver of the program's own String method (`("se" + i.to_s).into(r)` with `def into(q); q.replace(self); q; end`) is held by nothing inside the method, with or without a `replace` there. That is the call's fault, on master and here.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master 4337d93cf, built from nothing: the test in the seven collector lanes with gcc and clang, with and without `--share-strings` (master is wrong at `SPINEL_GC_STRESS=2` with exit 0; this change is right in every one); `ruby tools/gate.rb check`; the generated C of the 6,672 programs, changed in the two named above, which print their `.expected` in the seven lanes; optcarrot, checksum 59662, its C byte-identical; `make share-strings-test` and `make int-min-test`, both pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal` (`0`, `"g299"` and `"i299"`); CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change. It depends on no other pull request.
