<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`gsub` with no block, which answers an Enumerator over the matches, aborts under
`SPINEL_GC_STRESS=2`:

```ruby
p "a1b2".gsub(/\d/).to_a     # aborts at level 2; CRuby prints ["1", "2"]
```

`SPINEL_GC_STRESS=2 spinel diff` of that line on 185c4d663:

```
spinel diff: crash
  program: gsub_enum.rb
  ruby:    exit 0
  spinel:  exit -1 (SIGABRT)

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +0,0 @@
-["1", "2"]
```

Built with clang it also prints a wrong line under level 1 when the call sits in a loop. In a
plain run the answers were right, but for one order, below.

The emitted C made the Enumerator and its label, `gsub(/\d/)`, as two arguments of one call to
`sp_enum_with_src`. Each is a fresh allocation held in no root while the other is made, in
whichever order the C compiler evaluates the arguments. Now the Enumerator is made first, into a
rooted temporary, so the label is the only allocation among the call's arguments. The match is
not touched: no call sets `$~` that did not set it before.

Making the Enumerator first also settles one order. A pattern that is neither a String nor a
Regexp raises TypeError. When it is an object with an `inspect` of its own, clang's order raised
before `inspect` was asked for the label and gcc's order ran `inspect` first. Now both raise
first:

```ruby
class Pt
  def inspect
    puts "inspect ran"
    "pt"
  end
end
q = [Pt.new, /\d/]
begin
  p "a1b2".gsub(q[0]).to_a
rescue TypeError
  puts "TypeError"     # built with gcc, "inspect ran" was printed above it
end
```

`spinel diff` of that program on 185c4d663, built with gcc:

```
spinel diff: output-diff
  program: gsub_pattern_inspect.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1,2 @@
+inspect ran
 TypeError
```

Measured on dafa0d047 with the split and rpartition change and the gsub with a Hash change
beneath, with gcc 13.3 and clang 18.1, the runtime built with each. On 185c4d663 the commit
picks clean and the test gives the same:

- `test/gsub_enumerator_rooted.rb` aborts without the change under `SPINEL_GC_STRESS=2`, and
  under 1 with `SPINEL_GC_VERIFY=1`; built with gcc it also prints one wrong line in a plain
  run, the `inspect ran` above. With the change it is right at 0, 1 and 2, with the verifier
  off and on, with both compilers. It is in `GC_STRESS_TESTS`, and `make gc-stress-test` passes.
- Of the 6,772 Ruby files under test/, benchmark/, examples/ and packages/, 6,532 compile, and
  the C of five changes: test/enum_method_mark.rb, test/gsub_bang_blockless_enum.rb,
  test/splat_gsub_runtime_length.rb, test/string_enum_arg_forms.rb and
  test/rbs-seed/str_gsub_bang_enum_pattern.rb. Without the change all five abort at level 2,
  and three of them at level 1 with the verifier; with the change all five are right at 0, 1
  and 2, with the verifier off and on, with both compilers.
- A set of 606 programs, one case each, built and run on both: `gsub(pat)` and `gsub!(pat)`
  with no block over six receivers (a literal, a local, a call, a long String, multi-byte,
  empty), eight patterns (a Regexp literal, with a capture, with no match, empty, a character
  class, a String, a Regexp in a local, a String in a local), the Enumerator used ten ways
  (`to_a`, `each`, `map`, `with_index`, `each_with_index`, `inspect`, `size`, `first`,
  `first(2)`, stored in a local and read three times), at the top level, in a loop and in a
  method; a pattern read out of a mixed Array, of ten kinds (a Regexp, a String, an Integer,
  nil, a Symbol, a Float, an Array, and three objects: plain, with its own `inspect`, with its
  own `to_s`); and the block form, `scan`, `each_char`, `each_line` and other blockless forms as
  controls. The C of 506 changes, in the gsub expression alone; the C of the other 100 (the
  controls, and `gsub(pat).each { }`, which is compiled as the block form) does not change.
  - Plain run: with clang no program differs. With gcc 5 that printed `inspect ran` above their
    TypeError are right with the change. No program that is right without the change differs
    with it, with either compiler.
  - Level 1: with gcc the same 5; with clang 14 fail without the change (2 crash, 12 answer
    wrong) and are right with it.
  - Level 2: 378 abort without the change and are right with it; with gcc 47 more that answer
    wrong are right.
  - Level 2, an abort that becomes a wrong line: 14 programs, `s.gsub!(pat).to_a` followed by
    `p s`. The gsub! line is right; the `p s` line is wrong on both in a plain run (below), and
    each program prints byte for byte what it prints without the change in a plain run.
- Cost (callgrind, 100,000 calls): `"a1b2".gsub(/\d/).to_a` goes from 5,183 to 5,196
  instructions a call with gcc and from 4,959 to 4,974 with clang.

Left alone, wrong on both:

- `s.gsub!(pat)` with no block, read with `to_a`, leaves `s` as it was: `s = +"a1b2c3";
  p s.gsub!(/\d/).to_a; p s` prints `"a1b2c3"` last where CRuby prints `"abc"` (14 programs of
  the set). Read with `each { }` it edits the receiver as CRuby does.
- `gsub` with no block scans at once, where CRuby scans when the Enumerator is walked. So a
  pattern that is neither a String nor a Regexp raises TypeError at the call, also when the
  Enumerator is only asked its `inspect` or its `size`, which CRuby answers (32 programs). In
  four of these, built with gcc, the pattern's own `inspect` ran before that raise and now does
  not.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
