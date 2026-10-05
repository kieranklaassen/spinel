<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
s = +"ab"; s.insert(9, "x"); p s        # CRuby IndexError; here "abx"
s = +"ab"; s.insert(-4, "x"); p s       # CRuby IndexError; here "xb"
s = +"ab"; r = s.insert(-4, "x"); p r   # CRuby IndexError; here "axb"
```

The statement arm cut the String with two `sp_str_sub_range` calls and checked no bound; a String two names hold runs the same arm. With its value taken, a negative index below the start came back around, because the arm folded the index and `sp_str_splice_at` folded it again. A boxed receiver's insert did the same.

The statement and the value arm now go through one `sp_str_insert` in the runtime. It raises for an index past either end with the index CRuby reports, ahead of a frozen receiver's FrozenError as CRuby does, and builds the result in one `sp_str_concat3` with the head rooted while the tail is cut. A boxed receiver's `sp_poly_insert` keeps its two lines and gains the bound above them, so `lib/spinel_rt.h` only gains lines.

The statement arm nested both fresh pieces in `sp_str_concat`, so a collection between them freed the piece still in flight. In a plain run that is a wrong String and no error:

```ruby
fails = 0
20000.times do |i|
  n = i % 40 + 1
  s = "x" * 2100
  s.insert(0, "y" * n)
  fails += 1 unless s.size == 2100 + n
end
p fails   # CRuby 0; here 35, built with gcc: the String is the text alone
```

The count moves with what else allocates (110 a few merges earlier); built with clang this program is right. Under `SPINEL_GC_STRESS=2` the same window stopped a statement insert with "the mark reached a freed heap string" (`s = +"x"; s << "a"; s.insert(0, "b")`). Both are right now, with gcc and with clang, and the test joins `GC_STRESS_TESTS`. The statement arm also reads its text as the value arm does, so a text whose kind is known at run time builds; on master the new test stops at C compilation for that line.

The statement reads its index, then its text, then the receiver, so a text that changes the receiver, `s.insert(1, (s << "ef"; "x"))`, is seen whichever order the C compiler reads a call's arguments in. The nested calls it replaces lost the append built with gcc and kept it built with clang. With its value taken, an insert reads the receiver first as it did, so `r = s.insert(1, (s << "ef"; "x"))` still loses the append, with gcc and with clang.

A nil receiver raised FrozenError as a statement ("can't modify frozen String: nil"); it raises NoMethodError. With its value taken, an insert on a nil receiver still crashes, as on master. A nil text inserted nothing; it raises TypeError.

An insert is not slower: 1,172 instructions a statement insert into an eight-character String before, 1,090 after; 1,304 and 1,100 with the value taken (callgrind, 200,000 calls). No benchmark and not optcarrot calls it; their generated C is unchanged.

Left as they are, on master too: a frozen String two names hold raises FrozenError ahead of the IndexError when the index is also past the end, and an insert whose text appends to a String two names hold loses the append, since that arm copies the contents out before the arguments run.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
