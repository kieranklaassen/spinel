<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** A String replaced from an object that answers `to_str`, or from a choice with a String two names hold on one side, came out as freed memory, in a plain run when the Strings are large. The cost is one root, 14 to 17 instructions a statement with gcc and 14 to 20 with clang, on `replace` as a statement whose source runs no call and is not on the list below. Four such sources were right on master and pay it; they are named under the table.

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

- a String two names hold as one side of a choice: `t || "none"`, `c ? t : "none"`, a `case`, an `unless`. It is read as a copy there too, and the test asks about the read itself, not about a choice it stands in;
- an object, read through its `to_str`: `s.replace(o)`, `s.replace(@o)`, a boxed value that holds a String or such an object (`v = c ? "odd" + i.to_s : o`), and `c ? o : "none"`.

Where master's test says no, a second one now asks whether something else holds the source (`replace_source_is_held`), and the temp gets the same root unless it does:

- a literal;
- a local, an instance variable, a constant, a global or `self` read where it stands, typed String (`strbuf_slot_ref` says which of those are read as a copy);
- a boxed value read the same way, while no class of the program defines `to_str`;
- a choice between two of those: `c ? a : K`, `a || K`, `k && a`.

For a source on that list, and for every source master's test already roots, the generated C is master's. Master's line is as it was: the second test is an `else if` after it.

Cost, callgrind, 200,000 statements each, before and after, with the instructions a statement in parentheses:

| source | gcc | clang |
|---|---|---|
| `t \|\| "none"` | 106,876,162 to 110,276,163 (17) | 107,074,640 to 111,074,639 (20) |
| `c ? t : "none"` | 107,476,161 to 110,276,163 (14) | 107,474,640 to 110,474,639 (15) |
| `o`, an object with `to_str` | 60,060,386 to 62,861,002 (14) | 60,441,044 to 63,241,657 (14) |
| `k && t`, `k` a boolean | 71,073,417 to 73,875,362 (14) | 69,851,818 to 72,653,760 (14) |
| `x = a` | 62,456,126 to 65,256,772 (14) | 62,839,097 to 65,839,740 (15) |
| `begin; t; end` | 110,477,087 to 113,277,092 (14) | 111,075,562 to 113,875,563 (14) |
| a boxed String, where a class defines `to_str` | 62,485,675 to 65,286,295 (14) | 61,665,452 to 64,466,059 (14) |
| `k && a` | 62,656,127, the same | 63,039,113, the same |
| `a` (a local) | 62,055,618, the same | 62,438,603, the same |

`t` is a String two names hold, `a` one a single local holds. The first three were wrong on master at `SPINEL_GC_STRESS=2`. The next four take the root and were right: an `&&` of a boolean and such a `t` is boxed, and `t` is not copied (beside a String `k` it is, and that was wrong); an assignment written as the source leaves the String in its local; a `begin` block is run into a temp ahead of the statement; and a boxed String is read where it stands, which is not known where a class of the program defines `to_str` and the box may hold its object. A source that is no String at all (`s.replace(1)`) raises ahead of the root. Where a row says "the same", the two counts are equal: the generated C is.

No program under `test/`, `benchmark/` and `packages/*/test/` has such a statement: the generated C of all 6,707 is master's (three print the path of the build's own directory and differ in that alone), and optcarrot's is byte-identical.

`test/string_replace_choice_to_str_root.rb` replaces through eight such sources and counts the Strings that came out wrong: `t || "x"`, `c ? t : "x"`, a `case`, `@t || "x"`, an object in a local and in an instance variable, a boxed value, and `c ? o : "x"`. A ninth count is for four sources something else holds (`a`, `c ? a : "x"`, `a || "x"`, and `t` alone, which master roots). On master a3892bb00 (gcc and clang) it is right in a plain run and at level 1, and counts 1,750 of its 2,400 wrong at level 2 with exit 0 (the others take a literal, or a String a local holds); the ninth count is 0 of 1,200. With this change it prints its `.expected` in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang, and the same with `--share-strings`. It is registered for the stress lanes by its header line (`# spinel: gc-stress`).

**Not in this change**, on master and here alike:

- `Named` as it is written above, boxed beside a String (`v = c ? "odd" : Named.new("v")`, `s.replace(v)`), raises "no implicit conversion of Named into String" in every run: a class that writes its instance variables only in `initialize` is passed by value, and its `to_str` is not among those a boxed value is sent to. With a setter in the class it is; that is the boxed source in the list above.
- An object as the source where the receiver is a String two names hold, or with `--share-strings` a parameter: the program does not build (`sp_String_set_bin` is handed the object). That is another arm of the statement; a choice as its source is right there.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master a3892bb00, built from nothing: the test in the seven collector lanes with gcc and clang, with and without `--share-strings` (master is wrong at `SPINEL_GC_STRESS=2` with exit 0; this change is right in every one); `ruby tools/gate.rb check`; the generated C of the 6,707 other programs, unchanged; optcarrot, checksum 59662, its C byte-identical; `make share-strings-test` and `make int-min-test`, both pass; the compiler's own instructions over 1,000 and 2,000 lines of one statement: `s.replace(a)`, 488,132,727 and 489,169,834 at 1,000 (+0.21%), 970,305,771 and 972,379,878 at 2,000 (+0.21%), the largest pair found on statements that keep master's C; `s.replace(t || "x")`, which gains the root, 636,715,250 and 644,604,962 (+1.24%), 1,268,767,093 and 1,284,659,165 (+1.25%); `s.replace(a + k)`, which master's test roots, 1,079,750,196 and 1,079,750,317.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal` (nine lines of `0`); CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change. It depends on no other pull request.
