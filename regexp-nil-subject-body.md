<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def line(i) = i == 0 ? "k=v" : nil

2.times do |i|
  if /(?<key>\w+)=/ =~ line(i)
    puts "set #{key}"
  else
    p key          # nil
  end
end
```

Before: `set k`, then "k": the capture of the match before, for the line that is nil.

After: `set k`, then nil.

Two more from the same root:

```ruby
"k=v" =~ /k/
p(/x/ !~ line(1))            # true
p $~                         # nil; was #<MatchData "k">

def pick(i) = [nil, "k=v", :k][i]
blank = Regexp.new("^ *$")
p blank.match?(pick(0))      # false; was true
p blank === pick(0)          # false; was true
p blank.match(pick(0))       # nil; was #<MatchData "">
```

A nil subject of a Regexp's own `=~`, `!~`, `===`, `match` and of the named-capture `=~` went to the matcher as NULL, and the matchers return for NULL before they touch the registers. So `$~`, `$1` and the capture locals kept the earlier match, where CRuby reads `$~` as nil after such a call (only `nil =~ re`, which is `NilClass#=~`, leaves it). A boxed nil did not get that far: the String slot's conversion made it "", which `^ *$` matches, and the block form of a Regexp that is no literal raised a TypeError for it.

Chosen: nil reaches the matcher as NULL at each of these sites, boxed or not, and `sp_re_subj` clears the registers for it. Every other value converts as its site converted it before: `sp_poly_to_s_nilable` and `sp_poly_arg_str_nilable` are those conversions with nil let through. The clearing is emitted only where it can be seen: in a program that reads `$~`, `$1` or `Regexp.last_match` (`g_reads_match_regs`), for a subject that is no String literal; at a named capture always, since its locals read the registers themselves. Elsewhere the C is unchanged.

Cost: one test of the subject for NULL per match, in such a program. Ten million matches of a String take the same time before and after, least of 15 runs: `/b/ =~ s` 0.25 s and 0.22 s, `/b/ !~ s` 0.18 and 0.18, a named capture 1.10 and 1.04, `re === s` of a `Regexp.new` 0.08 and 0.08.

Not here:

- `case s when /re/` and `in /re/` over a nil String still leave `$~`. A `case` in a method has no frame of its own for `$~` yet (`scope_performs_match` counts calls), so a match in it already reaches the caller: after `"k=v" =~ /k/`, `def kind(s) = case s when /x/ then 1 else 2 end` called with "zzz" leaves the caller's `$~` nil, where Ruby keeps the MatchData. Called with nil it keeps it, by not clearing, and clearing there would lose that;
- `re === "k=v"` of a Regexp that is no literal answers right and does not set `$~` (it is compiled as `match?`): after `"k=v" =~ /k/`, `Regexp.new("v") === "k=v"` leaves `$~[0]` as "k". Only its nil subject changes here;
- a subject of another class: `/b/ !~ v` raises a TypeError for a Symbol, where Ruby matches its name, and a boxed Integer is matched as its digits by `match` and `match?`, where Ruby raises. Unchanged;
- `re.match?(str, pos)` of a Regexp that is no literal is refused, before and after.

Measured with gcc against CRuby 3.3.6, on master 3d629868df96:

- 54 generated programs, 486 lines: the Regexp as a literal, a constant, a local, an interpolation, `Regexp.new` and a parameter; `=~`, `!~`, `match`, `match(x, 0)`, `match` with a block, `match?`, `match?(x, 0)`, `===` and `when`; the subject `nil`, a local that is nil, a method that answers nil, a String method that answers nil, a boxed nil, a Hash's missing key, and three Strings. Master: 229 lines right, 230 wrong (121 only in `$~`, 93 in the answer, 16 a TypeError), 27 refused. With the change: 448 right, 11 wrong, 27 refused. The 11 are the `when` above (5 a nil String at the top level, 6 the caller's `$~` after a method). The same counts with `--share-strings`.
- 525 more programs whose subject is not nil: a String, a Symbol, an Integer, a Float, `true`, `false`, an Array, a Hash and an object with `to_s` or `to_str`, typed and boxed (21 subjects), against the Regexp as a literal, a constant and `Regexp.new`, in the eight operations (`when` aside) and a named capture. Each prints its answer, `$~` and `$1`. All 525 print the same line on master and with the change (58 build on neither).
- `make cident REF=3d629868df96`: 6484 identical, 14 differ, 0 refusal changes. The 14 are the new test and 13 programs that read `$~` or a capture and match a subject that is no String literal, `packages/bigdecimal/test/bigdecimal_basic.rb` and `test/strict_arg_conversion.rb` among them. All 13 print their `.expected`, and under `SPINEL_GC_STRESS=1` and `2` they do what they do on master: 11 print it, and those two fail there the same way before and after.
- `test/regexp_nil_subject.rb`: master stops at a TypeError after 33 of its 65 lines, 19 of them not the `.expected`'s. With the change it prints its `.expected` with gcc and clang, with `--int-overflow=promote`, with `--share-strings`, and under `SPINEL_GC_STRESS=1` and `2`; `make gc-stress-test`, `make reject-test` and `tools/refusals.sh` pass.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
