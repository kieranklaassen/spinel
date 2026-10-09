<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** A String replaced from an object that answers `to_str`, or from a String two names hold where it is one side of a choice or is written to in the source, came out as freed memory, in a plain run when the Strings are large. The cost is one root, 10 to 17 instructions a statement with gcc and 10 to 20 with clang, on `replace` as a statement whose source runs no call and either is no String or reads or writes a String two names hold below its top, where that can be the source's value. Sources of three families were right on master and pay it; they are named under the table with their reasons.

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
- the source is a String and a read below its top is a copy. `strbuf_slot_ref`, master's own answer to "is this read a copy", is asked of each read whose value can be the source's. A write counts as a read of its own variable where that holds such a String (`holder_of_node` says so): its value is the variable read back, and no read node stands for it. The reads whose value never is the source's are left out: a condition, the left of `&&`, a `when`'s conditions, an `in`'s pattern, an `ensure` clause, every statement of a sequence but its last (a `break` before the last gives a loop its value, and the loop holds that in a frame slot), and what `defined?` is asked about.

For every other source, and for every source master's test already roots, the generated C is master's: a literal; a read that is the whole source, which master's test has answered for; a choice, a `case`, a `begin` block or an assignment over Strings one name holds; a source that reads a String two names hold only where its value is not the source's (`t ? a : b`, `(t; a)`, `t && a`, `case a when t then b else a end`, `defined?(t)`); a constant path, a class variable, `__FILE__`, `$1`. Master's line is as it was: the second test is an `else if` after it. One read master's test passes without asking, a read marked to hand out its handle, is asked the same question; none of the programs here takes a root by it.

Cost, callgrind, 200,000 statements each, before and after, with the instructions a statement in parentheses:

| source | gcc | clang |
|---|---|---|
| `t \|\| "none"` | 106,876,162 to 110,276,163 (17) | 107,074,626 to 111,074,625 (20) |
| `k ? t : "none"` | 107,476,161 to 110,276,163 (14) | 107,474,626 to 110,474,625 (15) |
| `o`, an object whose `to_str` makes a String | 100,293,716 to 103,296,386 (15) | 100,291,827 to 103,094,494 (14) |
| `x = t` | 107,879,423 to 110,679,424 (14) | 107,877,916 to 110,877,915 (15) |
| `t \|\|= "none"` | 107,483,776 to 110,283,776 (14) | 107,878,170 to 109,878,169 (10) |
| `k && t` | 71,073,360 to 73,875,305 (14) | 69,851,793 to 72,653,735 (14) |
| `n \|\|= t` | 72,075,338 to 74,877,282 (14) | 70,653,828 to 73,455,771 (14) |
| `false \|\| t` | 71,074,368 to 73,876,318 (14) | 69,852,845 to 72,654,789 (14) |
| `k ? t : 5` | 71,074,368 to 73,876,318 (14) | 69,852,859 to 72,654,803 (14) |
| `while true; break t; end` | 71,476,274 to 74,278,217 (14) | 70,254,762 to 73,056,703 (14) |
| `begin; t; end` | 110,477,087 to 113,277,092 (14) | 111,075,562 to 113,875,563 (14) |
| `begin; t; ensure; z; end` | 126,677,665 to 129,277,668 (13) | 131,078,224 to 134,278,224 (16) |
| `begin; a; rescue; t; end` | 76,877,224 to 79,479,449 (13) | 78,061,560 to 81,463,780 (17) |
| `begin; a; rescue; b; else; t; end` | 126,302,932 to 128,902,935 (13) | 126,903,529 to 129,903,529 (15) |
| `(t if k)` | 110,477,073 to 113,277,078 (14) | 111,075,562 to 113,875,563 (14) |
| `if z then "x" elsif k then t else "y" end` | 110,477,087 to 113,277,092 (14) | 111,075,562 to 113,875,563 (14) |
| `case i; in Integer then t; end` | 110,484,756 to 113,284,756 (14) | 111,079,248 to 113,879,249 (14) |
| `$g = t` | 108,081,138 to 110,481,139 (12) | 107,878,495 to 110,679,622 (14) |
| `@x = t` | 108,087,040 to 110,488,175 (12) | 107,882,656 to 110,682,656 (14) |
| a boxed String, where a class defines `to_str` | 62,485,614 to 65,286,234 (14) | 61,665,314 to 64,465,921 (14) |
| `o`, whose `to_str` answers a String it holds | 60,060,981 to 62,863,811 (14) | 60,441,707 to 63,244,534 (14) |
| `a` | 62,056,113, the same | 62,439,113, the same |
| `x = a` | 62,456,646, the same | 62,839,628, the same |
| `a \|\|= "none"` | 61,270,260, the same | 61,849,253, the same |
| `k ? a : b` | 62,056,127, the same | 62,439,099, the same |
| `case k when true then a else b end` | 62,056,127, the same | 62,439,113, the same |
| `k && a` | 62,061,307, the same | 62,640,413, the same |
| `begin; a; end` | 65,056,758, the same | 65,639,757, the same |
| `@@a` | 56,062,761, the same | 54,842,821, the same |

`t` is a String two names hold, `a` and `b` Strings one local holds, `k` and `z` booleans, `n` nil. The first five were wrong on master at `SPINEL_GC_STRESS=2`. The other rows that take the root were right. They are examples, not a list: the sources that pay are of three families, by what the emitter did with the read, which the tree does not show:

- `t` is boxed by its handle and not copied: `k && t` and `n ||= t` (beside a String `k` it is copied, and that was wrong), `false || t`, `n || t`, `k ? t : 5`, and a loop that hands `t` out by `break`, whose value the loop keeps boxed in a frame slot;
- the source is run into a temp ahead of the statement, and that temp is rooted: `begin; t; end`, the same with an `ensure`, a `rescue` or an `else` arm, `(t if k)`, an `elsif` chain, an `in` arm;
- the variable written holds the copy: `$g = t`, `@x = t`.

A write to `t` in place of the read pays the same where master ran it right: in a loop's `break`, and in the forms run ahead (`(t = "abc" if k)`).

Two more come from the type line: a boxed String, where a class of the program defines `to_str` (the box may hold that object), and an object whose `to_str` answers a String it holds (`def to_str = @buf`; what a `to_str` answers is not known at the statement).

A source that is no String at all (`s.replace(1)`) raises ahead of the root. Where a row says "the same", the two counts are equal: the generated C is master's.

No program under `test/`, `benchmark/` and `packages/*/test/` has such a statement: the generated C of all 6,764 is master's (three print the path of the build's own directory and differ in that alone), and optcarrot's is byte-identical.

`test/string_replace_choice_to_str_root.rb` replaces through eleven such sources and counts the Strings that came out wrong: `t || "x"`, `c ? t : "x"`, a `case`, `@t || "x"`, an object in a local and in an instance variable, a boxed value, `c ? o : "x"`, and three writes, `w ||= "x"`, `c ? (w ||= "x") : "y"` and `w = "abc"`. A twelfth count is for four sources something else holds (`a`, `c ? a : "x"`, `a || "x"`, and `t` alone, which master roots). On master 090969e77 (gcc and clang) it is right in a plain run and at level 1, and counts 2,500 of its 3,300 wrong at level 2 with exit 0 (the others take a literal, or a String a local holds); the twelfth count is 0 of 1,200. With this change it prints its `.expected` in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang, and the same with `--share-strings`. It is registered for the stress lanes by its header line (`# spinel: gc-stress`).

**Not in this change**, on master and here alike:

- `Named` as it is written above, boxed beside a String (`v = c ? "odd" : Named.new("v")`, `s.replace(v)`), raises "no implicit conversion of Named into String" in every run: a class that writes its instance variables only in `initialize` is passed by value, and its `to_str` is not among those a boxed value is sent to. With a setter in the class it is; that is the boxed source in the list above.
- An object as the source where the receiver is a String two names hold, or with `--share-strings` a parameter: the program does not build (`sp_String_set_bin` is handed the object). That is another arm of the statement; a choice as its source is right there.
- `self` as the source in a method the program adds to String, called on a String made in place (`("sf" + i.to_s).put_into(s)` with `s.replace(self)` inside): wrong at level 2, with the same C. Nothing holds that receiver, with or without `replace`.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master 090969e77, built from nothing: the test in the seven collector lanes with gcc and clang, with and without `--share-strings` (master is wrong at `SPINEL_GC_STRESS=2` with exit 0; this change is right in every one); `ruby tools/gate.rb check`; the generated C of the 6,764 other programs, unchanged; optcarrot, checksum 59662, its C byte-identical; `make share-strings-test` and `make int-min-test`, both pass; the compiler's own instructions over 1,000 and 2,000 lines of one statement, before and after: `s.replace(a)`, 482,966,588 and 483,122,515 (+0.03%) at 1,000 and 959,819,762 and 960,131,689 (+0.03%) at 2,000; `s.replace(c ? a : "x")`, where each side of the choice is asked whether it is a copy and the C stays master's, 882,232,524 and 884,602,465 (+0.27%) and 1,763,469,043 and 1,768,208,984 (+0.27%); the same over two locals, `c ? a : b`, 898,592,407 and 901,631,343 (+0.34%) and 1,796,548,766 and 1,802,626,702 (+0.34%), and over five in a `case`, 1,819,676,821 and 1,827,893,734 (+0.45%) and 3,639,817,957 and 3,656,251,870 (+0.45%), the dearest measured of the pairs that keep master's C; `s.replace(x = a)`, where the write is asked for its variable, 10,677,690,721 and 10,679,731,657 (+0.02%) and 41,355,346,180 and 41,359,428,116 (+0.01%); `s.replace(t || "x")`, which gains the root, 631,470,502 and 639,475,330 (+1.27%) and 1,258,117,258 and 1,274,242,011 (+1.28%); `s.replace(a + k)`, which master's test roots, 1,076,727,076 and 1,076,726,988 (-88 instructions).

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal` (twelve lines of `0`); CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change. It depends on no other pull request.
