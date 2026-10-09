<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** A String replaced from an object that answers `to_str`, or from a choice with a String two names hold on one side, came out as freed memory, in a plain run when the Strings are large. The cost is one root, 12 to 17 instructions a statement with gcc and 14 to 20 with clang, on `replace` as a statement whose source runs no call and either is no String or reads a String two names hold below its top, where that read can be the source's value. Eleven such sources found were right on master and pay it; each is named under the table with its reason.

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

The same with a String two names hold, as one side of a choice:

```ruby
t = +"abcdefgh"
u = t
u << "abcdefgh" * 999
want = "abcdefgh" * 1_000
s = +"start"
bad = 0
300.times do
  s.replace(t || "none")
  bad += 1 unless s == want
end
p bad          # 0 in Ruby; 1 on master, with gcc and with clang
```

and under `SPINEL_GC_STRESS=2` whatever their size, with exit 0:

```ruby
3.times do |i|
  s = +"qrst"
  t = +"a"
  u = t
  u << i.to_s
  s.replace(t || "none")
  p s          # "a0", "a1", "a2" in Ruby; "\xDB\xDB" three times on master at level 2
end
```

The statement form of `replace` (`str_mutate_reassign_arms`, `src/codegen_stmt.c`) copies its source into a new String:

```c
{ const char *_t1 = <source>; lv_s = sp_str_from_bytes(_t1, sp_str_byte_len(_t1)); }
```

Master roots `_t1` where `operand_may_allocate` says the source may make a String: any call, an interpolation, and the read of a String two names hold, which is a copy. That covers a source made in place (`s.replace("a" + i.to_s)`, `s.replace(t)`). Two kinds of source make a String with no call written in them, and that test does not see them:

- a String two names hold, read below the top of the source: one side of a choice (`t || "none"`, `c ? t : "none"`, a `case`, an `unless`) or the value of an assignment (`x = t`). It is read as a copy there too, and the test asks about a read that is the whole source, not about one inside it;
- an object, read through its `to_str`: `s.replace(o)`, `s.replace(@o)`, a boxed value that holds a String or such an object (`v = c ? "odd" + i.to_s : o`), and `c ? o : "none"`.

Where master's test says no, a second one now asks whether the source may be such a String (`replace_source_may_be_fresh`), and the temp gets the same root where it may:

- the source is no String: an object, or a boxed value while a class of the program defines `to_str`;
- the source is a String and a read below its top is a copy. `strbuf_slot_ref`, master's own answer to "is this read a copy", is asked of each read whose value can be the source's. The reads whose value never is are left out: a condition, the left of `&&`, a `when`'s conditions, an `in`'s pattern, an `ensure` clause, every statement of a sequence but its last, and what `defined?` is asked about.

For every other source, and for every source master's test already roots, the generated C is master's: a literal; a read that is the whole source, which master's test has answered for; a choice, a `case`, a `begin` block or an assignment over Strings one name holds; a source that reads a String two names hold only where its value is not the source's (`t ? a : b`, `(t; a)`, `t && a`, `case a when t then b else a end`, `defined?(t)`); a constant path, a class variable, `__FILE__`, `$1`. Master's line is as it was: the second test is an `else if` after it. One read master's test passes without asking, a read marked to hand out its handle, is asked the same question; none of the programs here takes a root by it.

Cost, callgrind, 200,000 statements each, before and after, with the instructions a statement in parentheses:

| source | gcc | clang |
|---|---|---|
| `t \|\| "none"` | 106,876,974 to 110,276,975 (17) | 107,076,565 to 111,075,437 (20) |
| `k ? t : "none"` | 107,476,973 to 110,276,975 (14) | 107,476,565 to 110,476,564 (15) |
| `o`, an object whose `to_str` makes a String | 100,295,668 to 103,298,338 (15) | 100,293,724 to 103,096,391 (14) |
| `x = t` | 107,880,235 to 110,680,236 (14) | 107,878,728 to 110,878,727 (15) |
| `k && t` | 71,074,172 to 73,876,117 (14) | 69,853,687 to 72,655,629 (14) |
| `n \|\|= t` | 72,077,278 to 74,878,094 (14) | 70,655,767 to 73,457,710 (14) |
| `begin; t; end` | 110,477,899 to 113,277,904 (14) | 111,076,374 to 113,877,502 (14) |
| `begin; t; ensure; z; end` | 126,678,477 to 129,279,608 (13) | 131,079,036 to 134,279,036 (16) |
| `begin; a; rescue; t; end` | 76,878,036 to 79,480,261 (13) | 78,063,499 to 81,465,719 (17) |
| `begin; a; rescue; b; else; t; end` | 126,304,872 to 128,904,875 (13) | 126,905,468 to 129,905,468 (15) |
| `(t if k)` | 110,477,885 to 113,277,890 (14) | 111,076,374 to 113,877,502 (14) |
| `if z then "x" elsif k then t else "y" end` | 110,477,899 to 113,277,904 (14) | 111,076,374 to 113,877,502 (14) |
| `$g = t` | 108,081,950 to 110,481,951 (12) | 107,881,561 to 110,681,561 (14) |
| a boxed String, where a class defines `to_str` | 62,486,438 to 65,287,058 (14) | 61,667,121 to 64,467,728 (14) |
| `o`, whose `to_str` answers a String it holds | 60,061,805 to 62,864,635 (14) | 60,442,468 to 63,246,422 (14) |
| `a` | 62,056,919, the same | 62,441,046, the same |
| `x = a` | 62,457,452, the same | 62,840,434, the same |
| `k ? a : b` | 62,056,933, the same | 62,439,905, the same |
| `case k when true then a else b end` | 62,056,933, the same | 62,439,919, the same |
| `k && a` | 62,062,113, the same | 62,642,292 and 62,641,165, the same C |
| `begin; a; end` | 65,058,692 and 65,057,564, the same C | 65,640,563, the same |
| `@@a` | 56,063,579, the same | 54,843,594 and 54,844,721, the same C |

`t` is a String two names hold, `a` and `b` Strings one local holds, `k` and `z` booleans, `n` nil. The first four were wrong on master at `SPINEL_GC_STRESS=2`. The next eleven take the root and were right, because the tree does not show what the emitter did with the read:

- `k && t` and `n ||= t`: `t` is boxed by its handle there and not copied. Beside a String `k` it is copied, and that was wrong.
- `begin; t; end`, `begin; t; ensure; z; end`, `begin; a; rescue; t; end`, `begin; a; rescue; b; else; t; end`, `(t if k)` and `if z then "x" elsif k then t else "y" end`: each is run into a temp ahead of the statement, and that temp is rooted.
- `$g = t`: the global holds the copy.
- a boxed String, where a class of the program defines `to_str`: the box may hold that object.
- an object whose `to_str` answers a String it holds (`def to_str = @buf`): what a `to_str` answers is not known at the statement.

A source that is no String at all (`s.replace(1)`) raises ahead of the root. Where a row says "the same", the generated C is master's; three of those counts differ by some 1,100 instructions in 55 to 65 million, which is a run's own variation.

No program under `test/`, `benchmark/` and `packages/*/test/` has such a statement: the generated C of all 6,738 is master's (three print the path of the build's own directory and differ in that alone), and optcarrot's is byte-identical.

`test/string_replace_choice_to_str_root.rb` replaces through eight such sources and counts the Strings that came out wrong: `t || "x"`, `c ? t : "x"`, a `case`, `@t || "x"`, an object in a local and in an instance variable, a boxed value, and `c ? o : "x"`. A ninth count is for four sources something else holds (`a`, `c ? a : "x"`, `a || "x"`, and `t` alone, which master roots). On master f85f04b3a (gcc and clang) it is right in a plain run and at level 1, and counts 1,750 of its 2,400 wrong at level 2 with exit 0 (the others take a literal, or a String a local holds); the ninth count is 0 of 1,200. With this change it prints its `.expected` in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang, and the same with `--share-strings`. It is registered for the stress lanes by its header line (`# spinel: gc-stress`).

**Not in this change**, on master and here alike:

- `Named` as it is written above, boxed beside a String (`v = c ? "odd" : Named.new("v")`, `s.replace(v)`), raises "no implicit conversion of Named into String" in every run: a class that writes its instance variables only in `initialize` is passed by value, and its `to_str` is not among those a boxed value is sent to. With a setter in the class it is; that is the boxed source in the list above.
- An object as the source where the receiver is a String two names hold, or with `--share-strings` a parameter: the program does not build (`sp_String_set_bin` is handed the object). That is another arm of the statement; a choice as its source is right there.
- `self` as the source in a method the program adds to String, called on a String made in place (`("sf" + i.to_s).put_into(s)` with `s.replace(self)` inside): wrong at level 2, with the same C. Nothing holds that receiver, with or without `replace`.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master f85f04b3a, built from nothing: the test in the seven collector lanes with gcc and clang, with and without `--share-strings` (master is wrong at `SPINEL_GC_STRESS=2` with exit 0; this change is right in every one); `ruby tools/gate.rb check`; the generated C of the 6,738 other programs, unchanged; optcarrot, checksum 59662, its C byte-identical; `make share-strings-test` and `make int-min-test`, both pass; the compiler's own instructions over 1,000 and 2,000 lines of one statement, before and after: `s.replace(a)`, 482,477,968 and 482,633,968 (+0.03%) at 1,000 and 958,861,018 and 959,173,018 (+0.03%) at 2,000; `s.replace(c ? a : "x")`, where each side of the choice is asked whether it is a copy and the C stays master's, 881,833,787 and 884,177,777 (+0.27%) and 1,762,659,715 and 1,767,347,705 (+0.27%); `s.replace(t || "x")`, which gains the root, 631,027,743 and 639,025,620 (+1.27%) and 1,257,262,338 and 1,273,373,140 (+1.28%); `s.replace(a + k)`, which master's test roots, 1,075,788,657 and 1,075,788,657 (+0.00%).

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal` (nine lines of `0`); CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change. It depends on no other pull request.
