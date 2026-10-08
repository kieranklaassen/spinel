<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = +"abc"; s[0..] = "x"; p s            # CRuby "x"; here "xabc"
s = +"abc"; s[-3..] = "x"; p s           # CRuby "x"; here "xabc" with clang, IndexError "negative length" with gcc
def upto(k) = k == 0 ? nil : k
s = +"abc"; s[0..upto(0)] = "x"; p s     # CRuby "x"; here "xabc"
s = +"abcdef"; s[-6..9223372036854775807] = "x"; p s
                                         # CRuby "xabcdef"; here "xabcdef" with clang, that IndexError with gcc
```

An endless Range carries `INTPTR_MAX` as its end, and the Range arm of `String#[]=` took only `SP_INT_NIL` for "no end": from a start of 0 the count of characters, `INTPTR_MAX - 0 + 1`, ran over and nothing was replaced. From any other start the count stays an Integer and the splice clamps it, so `s[1..] = "x"` was right.

A Range whose end is 2^63 - 1 carries the same `INTPTR_MAX`, and there CRuby's own count runs over and replaces nothing (the last line above), so the number cannot say which Range it is. The arm asks the Range written in its index: one written with no end, or with `nil`, has none; one whose end can be nil when the program runs has its two ends taken into temps, the start first, and the end is asked whether it was nil. With no end and a start of 0 the count is `INTPTR_MAX`, which the splice clamps to the String. Every other count is what it was, and now wraps as unsigned arithmetic, where the signed overflow was the C compiler's to decide.

The cost: a start counted from the end pays one compare, 1,123 instructions a `s[-3..] = "xyz"` before and 1,124 after (callgrind, gcc; two with clang). `s[5..] = "xyz"`, an end written as an Integer, an end that may be nil and a Range out of a variable count what they counted. Eight existing tests change their generated C and print what they printed.

Left as they are: an endless Range that arrives as a value (`r = (0..); s[r] = "x"`) still answers "xabc". `sp_Range` has no word for "no end" that an end of 2^63 - 1 cannot counterfeit (`p (0..9223372036854775807)` prints `0..`), so a Range out of a variable, a method or a constant is read as it was. So is a Range written with a boxed start and an end that is nil at run time, and one whose end is a call that answers nil where the String has a second name (`t = s`): its Range runs into a temp ahead of the statement.

Depends on "String#insert and String#[]= raise TypeError for a value that is nil": with an endless Range from the first character and a String value that is nil at run time, that pull request raises CRuby's TypeError where this one alone would empty the String without a word. Both stand on "String#[]= with a Range starting outside the String raises RangeError".

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
