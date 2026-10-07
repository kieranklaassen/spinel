<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
r = [("ab".."ae"), 1][0]
ks = ["ac", 3]
p r.cover?("ac")
p r.cover?(ks[0])
```

```
spinel diff: output-diff
  program: cover_boxed.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
 true
-true
+false
```

The Range comes out of the Array boxed. For a String argument written in place, the chain of tests `emit_poly_prearms_n` writes for `cover?` has a String Range arm (pull request 7605), which answers by `sp_poly_case_eq`. For a boxed argument it has an Integer Range's arm and a Float Range's and none for a String Range, so the call fell to the false the chain starts from, whatever the argument held. The boxed argument gains the same test, after the numeric Ranges' own, and answers by `sp_poly_case_eq` too.

Cost (callgrind, 300,000 calls on an Integer and a Float Range by turns). Given a boxed Integer: 41,461,167 instructions on master and 41,311,153 here with gcc, 41,572,766 on both with clang. Given a boxed String, which neither covers: 26,911,066 to 28,561,052 with gcc, 5.5 instructions a call, and 25,372,665 to 25,222,665 with clang; given an Integer, a Float, a String and nil by turns gcc counts 2 a call more and clang half of one fewer. A String Range given a boxed String now compares where the chain fell through: 20,160,598 to 46,260,685 with gcc. A program with no `cover?` on a boxed receiver, or with an argument that is not boxed, gets the C it had; optcarrot's C is unchanged.

Stated cost. The boxed argument now answers what the String written in place answers on the same receiver, and master's boxed `false` was right wherever CRuby's answer is false:

```ruby
ma = +"ab"; mz = +"ae"
q = [(ma..mz), 1][0]
mz.replace("ac")
p q.cover?(["ad", 1][0])
```

An end changed in place after the Range is made is not seen, so this prints `true` here where CRuby and master print `false` (40 of 60 such programs measured go from right to wrong this way and the other 20 are wrong on both; the same call with `"ad"` written in place, and the Range not boxed, print `true` on master), and the cure is a Range that holds its ends as handles, which is not in this change.

A String with a NUL byte compares up to it: `[("a".."c"), 1][0].cover?(["c\0x", 1][0])` is `true` here, as it is with `"c\0x"` written in place on master. #<fork PR 106> compares the whole String, and this depends on it: with it beneath both are `false`.

The call now reads the Range's two ends. A String Range held by a global, a class variable, an instance variable or a Struct member loses them on master, where the `false` read nothing; without the two pieces that keep them this change answers wrong in a plain run (a global filled from two fresh ends and read 2,000 times counts 4 covered Strings where CRuby and master count 0). So it depends on #<fork PR 146> and #<fork PR 148>, and is right only above them.

Not here, and as on master: `case b when r` with a boxed String takes the `else` arm (`r === b` is right); `include?` and `member?` with a boxed String answer false (that is #<fork PR 162>); a String Range as the argument answers false; a String Range whose two ends are nil, given a boxed value that is no String, answers false where CRuby says true; a Range with both ends left out given a boxed String answers false; a slot that holds no Range answers false where CRuby raises NoMethodError; where a class of the program defines `cover?`, a boxed Range raises NoMethodError.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; no Ruby 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: #<fork PR 146>, #<fork PR 148> and #<fork PR 106> (the first two keep the ends of a String Range in a slot; the third compares past a NUL byte)
