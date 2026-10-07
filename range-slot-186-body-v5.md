<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

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

The Range comes out of the Array boxed. For a String written in place, the chain of tests `emit_poly_prearms_n` writes for `cover?` has a String Range arm (pull request 7605); for a boxed argument it had none, so the call fell to the false the chain starts from, whatever the argument held. The boxed argument gains the same arm, after the numeric Ranges' own, and answers by `sp_poly_case_eq` too.

The call now reads the Range's two ends, which a String Range in a global, a class variable, an instance variable or a Struct member loses on master: without "A String Range stored into an instance variable or a Struct member keeps its ends" and "A String Range in a global, a constant or a class variable keeps its ends" beneath, a global filled from two fresh ends counts 4 covered Strings of 2,000 in a plain run where CRuby and master count 0.

Stated cost: an end changed in place after the Range is made is not seen, so `ma = +"ab"; mz = +"ae"; q = [(ma..mz), 1][0]; mz.replace("ac"); p q.cover?(["ad", 1][0])` prints `true` where CRuby and master print `false` (40 of 60 such programs go from right to wrong, each printing what the same call with the String written in place prints on master), and the cure is a Range that holds its ends as handles, which is not in this change.

Cost (callgrind, 300,000 calls on an Integer and a Float Range by turns, gcc): given a boxed Integer 41,461,167 instructions to 41,311,153; given a boxed String 26,911,066 to 28,561,052, 5.5 a call; clang the same or half an instruction a call fewer. optcarrot's C is unchanged.

Not here, and as on master: `case b when r` with a boxed String takes the `else` arm (`r === b` is right); `include?` and `member?` with a boxed String answer false (that is "include? and member? on a String Range read from a boxed slot walk its members"); a String Range as the argument answers false; a String Range whose two ends are nil, given a boxed value that is no String, answers false where CRuby says true; a Range with both ends left out given a boxed String answers false; a slot that holds no Range answers false where CRuby raises NoMethodError; where a class of the program defines `cover?`, a boxed Range raises NoMethodError.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; no Ruby 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: "A String Range stored into an instance variable or a Struct member keeps its ends", "A String Range in a global, a constant or a class variable keeps its ends" and "cover?, === and max of a String Range compare the whole String" (the first two keep the ends of a String Range in a slot; the third compares past a NUL byte)
