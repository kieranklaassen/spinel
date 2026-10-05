## What this changes

```ruby
puts "q->iv_w = #{n};"                  # SP_WBO(q)-3;
p :"q->iv_w = 1;"                       # :"SP_WBO(q)->iv_w = 1;"
p("xq->iv_w = 1;" =~ /q->iv_w = 1;/)    # nil
```

in a program with a class whose `@w` holds a reference. The write-barrier pass reads the emitted C as text and wraps what reads as a store into such an instance variable, or into a captured local (`(*_cell_x) =`). A Ruby string that spells one is in that text too.

Since 2fddce4b a frozen literal is a file-scope object written after the pass, and `puts "q->iv_w = 1;"` is right. Still scanned are the written pieces of an interpolation (so also a heredoc with `#{}`, a `raise` message, a `sub` replacement), the Symbol name table (`%i[]`, a `"k": v` key) and a Regexp's source. An interpolated piece is cut to its written length, so it prints short. A Symbol keeps the longer name and no longer equals the same name built by `to_sym`. A Regexp matches the longer text only, so `=~` and `scan` find nothing.

Both scans now ask, of a store they are about to wrap, whether it stands inside a string literal on its C line, and leave it if so. The line is read from its start, which is always code, since the emitters write a literal's line ends as `\n`. Only a string that opens and closes around the store counts: a store behind a quote the reading cannot pair keeps its barrier, and a real store written behind such a string on the same line is wrapped as before.

Measured against CRuby under gcc and clang. Of 38 small programs with one kind of literal each, 35 are right on master and 3 wrong; all 38 are right here. Then 1,450 generated programs: 986 that print such text (34 places for it, 23 texts, as an interpolated piece, a Symbol or a Regexp's source), run plain and under the verifier with `SPINEL_GC_STRESS=1`, and 464 that put a real store behind such text on its C line and count the rounds that read it back, in six collector settings.

| master | this branch | programs |
|---|---|---|
| as CRuby in every setting | as CRuby in every setting | 424 |
| a wrong answer | as CRuby in every setting | 974 |
| a RegexpError at start | as CRuby in every setting | 7 |
| refused | refused | 29 |
| a wrong answer | a wrong answer | 16 |

No program that answers as CRuby on master answers otherwise, and none that is refused or raises on master answers wrong. The 29 are `q.s = +".."` followed by `<<`, refused by name with the same message on both. The 7 hold a Regexp whose rewritten source no longer compiled. The 16 are `@x = (c ? nil : (@last.ary = v))`: a store in another store's value takes no barrier on master, which is the fault of another change ("A store in another store's value takes its write barrier"); built with both, the 16 are right.

That the change moves no barrier outside the strings: for 1,483 programs the C written here is, byte for byte, the C master writes for the same program with the spelled names changed in the Ruby source (`->iv_` to `->jv_`, `_cell_x` to `_cel1_x`) and changed back in the C. One more program differs only in the name of a method it defines by such a text.

Cost. `make cident` against master: no program changes its C besides the new test. Compiling optcarrot takes 0.042% more instructions under callgrind (6,985,303,652 to 6,988,253,584); its C is the same. The reading remembers the last place it found outside a string, so a line of many such strings is read once: a table of 20,000 such Symbols compiles in 0.7 s (master 1.2 s, which wraps each), and of 2,000 in 221,363,097 instructions (master 228,504,137).

Test: `test/gc_minor_literal_spells_store.rb`, in `GC_MINOR_TESTS`. Fifteen printed lines, eleven of them wrong on master with gcc and with clang, and five counts of rounds in which a store written behind such a string on its C line must still be recorded.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
