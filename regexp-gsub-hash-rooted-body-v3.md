<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`gsub` with a String pattern and a Hash crashes in a plain run on a large String, in a program
that reads `$~`:

```ruby
h = {" " => "_"}
s = ("abcdefghij" * 40 + " ") * 2000
n = 0
8.times do
  t = s.gsub(" ", h)
  n += t.size if t[400] == "_" && $~[0] == " "
end
p n          # exits 139; CRuby prints 6416000
```

`spinel diff` of that program on 185c4d663:

```
spinel diff: crash
  program: gsub_hash_big.rb
  ruby:    exit 0
  spinel:  exit -1 (SIGSEGV)

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +0,0 @@
-6416000
```

On a 6 KB String, 20,000 rounds of `s.gsub("l", h)` followed by `$~[0]` answer a freed String
197 times. A program that never reads `$~` is right, and so are `sub` with a Hash and `gsub`
with a String replacement.

`sp_str_gsub_str_str_hash` built its result and then set the match, which allocates, while the
result sat in a C local with no root. Now the result is rooted across that one call, inside the
branch a program that reads `$~` takes. The match is set where it was set before and nowhere
else: no call sets `$~` that did not set it before.

Measured on dafa0d047 with the split and rpartition change beneath, with gcc 13.3 and clang
18.1, the runtime built with each; both compilers give the same counts. On 185c4d663 the
commit picks clean and the test gives the same:

- `test/gsub_hash_result_rooted.rb` prints one wrong line without the change in a plain run,
  two under `SPINEL_GC_STRESS=1`, and aborts under 2; dafa0d047 itself does the same. With the
  change it is right at all three, with `SPINEL_GC_VERIFY` 0 and 1. It is in `GC_STRESS_TESTS`,
  and `make gc-stress-test` passes.
- The change is in lib/sp_cold.c: the generated C does not change.
- The two corpus programs whose C calls the function, test/string_gsub_str_hash.rb and
  test/sub_gsub_hash_any_values.rb, are right on both in a plain run and at level 1; at level 2
  both abort without the change and are right with it.
- A set of 494 programs, one case each, built and run on both: eight receivers (empty to
  800 KB, multi-byte, binary, with a NUL byte, a buffer that was appended to), four patterns
  (found, not found, empty, two characters), four Hashes (String values, Integer values, mixed
  values, long values), with `$~` read and not read, at the top level, in a loop and in a
  method; and `sub` with a Hash, `gsub` with a String, `gsub` with a Regexp and a Hash, `gsub!`
  and the block form as controls.
  - Plain run: 10 fail without the change (4 crash, 6 answer wrong) and are right with it. No
    program that is right without the change differs with it.
  - Level 1: 24 fail without the change (7 crash, 17 answer wrong) and are right with it.
  - Level 2: 101 abort without the change and are right with it, and 20 that answer wrong are
    right.
  - Level 2, an abort that becomes a wrong line: four programs, a receiver with a NUL byte and
    an empty pattern. Each prints byte for byte what it prints without the change in a plain
    run: they are four of the fourteen that are wrong on both, below, where the abort came
    first.
- Cost (callgrind, 100,000 calls): `"hello".gsub("l", h)` goes from 1,405 to 1,425 instructions
  a call in a program that reads `$~` and from 1,204 to 1,206 in one that does not; with clang
  from 1,372 to 1,386 and from 1,172 to 1,175.

Left alone, wrong on both (14 programs of the set):

- A receiver with a NUL byte is read up to the NUL: `"he\0llo l".gsub("l", h)` answers the
  receiver unchanged and leaves `$~` nil, and with an empty pattern it answers 5 characters
  for 17 (12 programs).
- A Hash's default is not asked: `h = Hash.new("D"); "hello".gsub("l", h)` answers `"heo"`
  where CRuby answers `"heDDo"` (1 program).
- `p $~` after a String pattern prints `#<MatchData "L">` where CRuby prints
  `#<MatchData: L>` (1 program).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
