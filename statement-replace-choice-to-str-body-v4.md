<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** A String replaced from an object that answers `to_str`, or from a String two names hold where it is one side of a choice or is written to in the source, came out as freed memory, in a plain run when the Strings are large. The cost is one root, 10 to 22 instructions a statement with gcc and 7 to 20 with clang, on `replace` as a statement whose source runs no call and either is no String or reads or writes a String two names hold below its top, where that can be the source's value. Sources of three families were right on master and pay it; they are named under the table with their reasons.

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

- a String two names hold, read below the top of the source: one side of a choice (`t || "none"`, `c ? t : "none"`, a `case`, an `unless`), the value of an assignment (`x = t`), or a write to that String itself (`t ||= "none"`, `t = "abc"`), whose value is the String read back. It is read as a copy there too, and the test asks about a read that is the whole source, not about one inside it;
- an object, read through its `to_str`: `s.replace(o)`, `s.replace(@o)`, a boxed value that holds a String or such an object (`v = c ? "odd" + i.to_s : o`), and `c ? o : "none"`.

Where master's test says no, a second one now asks whether the source may be such a String (`replace_source_may_be_fresh`), and the temp gets the same root where it may:

- the source is no String: an object, or a boxed value while a class of the program defines `to_str`;
- the source is a String and a read below its top is a copy. `strbuf_slot_ref`, master's own answer to "is this read a copy", is asked of each read whose value can be the source's. A write counts as a read of its own variable where that holds such a String (`holder_of_node` says so): its value is the variable read back, and no read node stands for it. With `--share-strings` a plain write of a frozen literal (`t = "abc"`) is not counted: master gives the variable that literal's own handle (`share_frozen_literal` says which values those are), what is read back is the literal's bytes, and the statement keeps master's C. The reads whose value never is the source's are left out: a condition, the left of `&&`, a `when`'s conditions, an `in`'s pattern, an `ensure` clause, every statement of a sequence but its last (a `break` before the last gives a loop its value, and the loop holds that in a frame slot), and what `defined?` is asked about.

For every other source, and for every source master's test already roots, the generated C is master's: a literal; a read that is the whole source, which master's test has answered for; a choice, a `case`, a `begin` block or an assignment over Strings one name holds; a source that reads a String two names hold only where its value is not the source's (`t ? a : b`, `(t; a)`, `t && a`, `case a when t then b else a end`, `defined?(t)`); a constant path, a class variable, `__FILE__`, `$1`. Master's line is as it was: the second test is an `else if` after it. One read master's test passes without asking, a read marked to hand out its handle, is asked the same question; none of the programs here takes a root by it.

Cost, callgrind, 200,000 statements each, before and after, with the instructions a statement in parentheses:

| source | gcc | clang |
|---|---|---|
| `t \|\| "none"` | 108,276,051 to 111,676,052 (17) | 108,474,466 to 112,474,465 (20) |
| `k ? t : "none"` | 108,876,050 to 111,676,052 (14) | 108,874,466 to 111,874,465 (15) |
| `o`, an object whose `to_str` makes a String | 100,293,578 to 103,296,234 (15) | 100,291,617 to 103,094,270 (14) |
| `x = t` | 109,279,326 to 112,079,327 (14) | 109,277,742 to 112,277,741 (15) |
| `t \|\|= "none"` | 108,883,656 to 111,683,656 (14) | 109,278,037 to 111,278,036 (10) |
| `t = "abc"` | 173,897,060 to 176,497,313 (13) | 179,552,369 to 182,752,710 (16) |
| `k && t` | 71,073,240 to 73,875,171 (14) | 69,851,592 to 72,653,520 (14) |
| `n \|\|= t` | 72,075,204 to 74,877,162 (14) | 70,653,685 to 73,455,588 (14) |
| `false \|\| t` | 71,074,248 to 73,876,198 (14) | 69,852,676 to 72,654,620 (14) |
| `k ? t : 5` | 71,074,234 to 73,876,198 (14) | 69,852,662 to 72,654,620 (14) |
| `while true; break t; end` | 71,476,154 to 74,278,083 (14) | 70,254,633 to 73,056,506 (14) |
| `while r; break t; end` | 71,676,140 to 74,478,097 (14) | 70,254,619 to 73,056,574 (14) |
| `begin; t; end` | 111,876,962 to 114,676,981 (14) | 112,475,374 to 115,275,389 (14) |
| `begin; t; ensure; z; end` | 128,077,549 to 130,677,557 (13) | 132,878,118 to 135,878,118 (15) |
| `begin; a; rescue; t; end` | 76,877,133 to 79,479,358 (13) | 78,061,455 to 81,463,675 (17) |
| `begin; a; rescue; b; else; t; end` | 127,702,847 to 130,302,850 (13) | 128,303,430 to 131,303,430 (15) |
| `(t if k)` | 111,876,976 to 114,676,981 (14) | 112,475,388 to 115,275,389 (14) |
| `if z then "x" elsif k then t else "y" end` | 111,876,962 to 114,676,981 (14) | 112,475,374 to 115,275,389 (14) |
| `case i; in Integer then t; end` | 111,884,614 to 114,684,614 (14) | 112,479,065 to 115,279,066 (14) |
| `$g = t` | 109,480,995 to 111,881,010 (12) | 109,279,461 to 112,079,475 (14) |
| `@x = t` | 109,488,012 to 111,888,005 (12) | 109,282,527 to 112,082,459 (14) |
| a boxed String, where a class defines `to_str` | 62,485,444 to 65,286,078 (14) | 61,665,081 to 64,465,702 (14) |
| `o`, whose `to_str` answers a String it holds | 60,060,845 to 62,863,675 (14) | 60,441,558 to 63,244,385 (14) |
| `a` | 62,056,016, the same | 62,438,993, the same |
| `x = a` | 62,456,535 and 62,456,521 (0) | 62,839,508 and 62,839,494 (0) |
| `a \|\|= "none"` | 61,270,154, the same | 61,849,088, the same |
| `k ? a : b` | 62,056,016, the same | 62,438,993, the same |
| `case k when true then a else b end` | 62,056,002 and 62,056,016 (0) | 62,438,979 and 62,438,993 (0) |
| `k && a` | 62,061,173 and 62,061,187 (0) | 62,640,198 and 62,640,212 (0) |
| `begin; a; end` | 65,056,661, the same | 65,639,637, the same |
| `@@a` | 56,062,641 and 56,062,627 (0) | 54,842,647 and 54,842,633 (0) |

`t` is a String two names hold, `a` and `b` Strings one local holds, `k` and `z` booleans, `r` a boolean set in the loop, `n` nil. The first six were wrong on master at `SPINEL_GC_STRESS=2`. The other rows that take the root were right. They are examples, not a list: the sources that pay are of three families, by what the emitter did with the read, which the tree does not show:

- `t` is boxed by its handle and not copied: `k && t` and `n ||= t` (beside a String `k` it is copied, and that was wrong), `false || t`, `n || t`, `k ? t : 5`, and a loop that hands `t` out by `break`, whose value the loop keeps boxed in a frame slot;
- the source is run into a temp ahead of the statement, and that temp is rooted: `begin; t; end`, the same with an `ensure`, a `rescue` or an `else` arm, `(t if k)`, an `elsif` chain, an `in` arm;
- the variable written holds the copy: `$g = t`, `@x = t`.

A write to `t` in place of the read pays the same where master ran it right: in a loop's `break`, and in the forms run ahead (`(t = "abc" if k)`). With `--share-strings` a plain write of a frozen literal keeps master's C in each of those places, and three sources beside it that master ran right there take the root, 16 to 22 instructions a statement with gcc and 14 to 15 with clang: `t &&= "abc"`, `u = t = "abc"` and `(t = "abc"; t)`. What they read back is the literal's too; the cut is made only where the write is a plain one and its value is the literal itself.

Two more come from the type line: a boxed String, where a class of the program defines `to_str` (the box may hold that object), and an object whose `to_str` answers a String it holds (`def to_str = @buf`; what a `to_str` answers is not known at the statement).

A source that is no String at all (`s.replace(1)`) raises ahead of the root. Where a row says "the same" the two counts are equal, and where it gives two with (0) they differ by 14 instructions, less than two runs of one binary differ by here: the generated C is master's in both.

No program under `test/`, `benchmark/` and `packages/*/test/` has such a statement: the generated C of all 6,811 is master's (three print the path of the build's own directory and differ in that alone), and optcarrot's is byte-identical.

`test/string_replace_choice_to_str_root.rb` replaces through eleven such sources and counts the Strings that came out wrong: `t || "x"`, `c ? t : "x"`, a `case`, `@t || "x"`, an object in a local and in an instance variable, a boxed value, `c ? o : "x"`, and three writes, `w ||= "x"`, `c ? (w ||= "x") : "y"` and `w = "abc"`. A twelfth count is for four sources something else holds (`a`, `c ? a : "x"`, `a || "x"`, and `t` alone, which master roots). On master 4689b503c (gcc and clang) it is right in a plain run and at level 1, and counts 2,500 of its 3,300 wrong at level 2 with exit 0 (the others take a literal, or a String a local holds); the twelfth count is 0 of 1,200. With `--share-strings` its count for `w = "abc"` is 0 on master too, 2,200 of 3,300: that source keeps master's C there. With this change it prints its `.expected` in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang, and the same with `--share-strings`. It is registered for the stress lanes by its header line (`# spinel: gc-stress`).

**Not in this change**, on master and here alike:

- `Named` as it is written above, boxed beside a String (`v = c ? "odd" : Named.new("v")`, `s.replace(v)`), raises "no implicit conversion of Named into String" in every run: a class that writes its instance variables only in `initialize` is passed by value, and its `to_str` is not among those a boxed value is sent to. With a setter in the class it is; that is the boxed source in the list above.
- An object as the source where the receiver is a String two names hold, or with `--share-strings` a parameter: the program does not build (`sp_String_set_bin` is handed the object). That is another arm of the statement; a choice as its source is right there.
- `self` as the source in a method the program adds to String, called on a String made in place (`("sf" + i.to_s).put_into(s)` with `s.replace(self)` inside): wrong at level 2, with the same C. Nothing holds that receiver, with or without `replace`.
- An or-write through an attribute, `s.replace(o.name ||= "none")` where the attribute's String is one two names hold: wrong at level 2, with the same C. The source is neither a call nor a write of a variable; what it reads back is the attribute's.
- A `begin` block whose only statement is such a write (`s.replace(begin; t = "abc"; end)`, `begin; t ||= "none"; end`): the receiver is wrong in every run, at every level, on master and here; the root this change adds does not reach that fault.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master 4689b503c, built from nothing: the test in the seven collector lanes with gcc and clang, with and without `--share-strings` (master is wrong at `SPINEL_GC_STRESS=2` with exit 0; this change is right in every one); `ruby tools/gate.rb check`; the generated C of the 6,811 other programs, unchanged; optcarrot, checksum 59662, its C byte-identical; `make share-strings-test` and `make int-min-test`, both pass; the compiler's own instructions over 1,000 and 2,000 lines of one statement, before and after: `s.replace(a)`, 485,392,700 and 485,548,690 (+0.03%) at 1,000 and 964,615,769 and 964,927,759 (+0.03%) at 2,000; `s.replace(c ? a : "x")`, where each side of the choice is asked whether it is a copy and the C stays master's, 886,468,433 and 888,866,429 (+0.27%) and 1,771,751,846 and 1,776,547,842 (+0.27%); the same over two locals, `c ? a : b`, 902,936,275 and 906,003,286 (+0.34%) and 1,805,189,287 and 1,811,323,298 (+0.34%), and over five in a `case`, 1,826,901,347 and 1,835,195,361 (+0.45%) and 3,654,263,880 and 3,670,851,894 (+0.45%), the dearest measured of the pairs that keep master's C; `s.replace(x = a)`, where the write is asked for its variable, 10,704,429,864 and 10,706,477,875 (+0.02%) and 41,456,767,056 and 41,460,863,067 (+0.01%); `s.replace(t || "x")`, which gains the root, 634,415,016 and 642,429,833 (+1.26%) and 1,263,752,806 and 1,279,891,087 (+1.28%); `s.replace(a + k)`, which master's test roots, 1,081,224,169 and 1,081,224,181 (+12 instructions); and with `--share-strings`, `s.replace(t = "abc")`, which keeps master's C, 708,894,410 and 709,786,419 (+0.13%) and 1,409,951,970 and 1,411,735,979 (+0.13%).

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal` (twelve lines of `0`); CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change. It depends on no other pull request.
