<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = +"abc"; s[0..] = "x"; p s      # CRuby "x"; here "xabc"
s = +"abc"; s[-3..] = "x"; p s     # CRuby "x"; here "xabc" with clang, IndexError "negative length" with gcc
n = nil
s = +"abc"; s[0..n] = "x"; p s     # CRuby "x"; here "xabc"
```

One program is answered the other way:

```ruby
r = (0..9223372036854775807)
s = +"abc"; s[r] = "x"; p s        # CRuby "xabc"; master "xabc"; with this "x"
p (0..9223372036854775807)         # master prints 0..
p r.end                            # master prints nil
```

Spinel cannot tell that Range from an endless one: `sp_Range` has no field for it, so nothing here can keep it. With the end written in the index, `s[0..9223372036854775807] = "x"`, it prints "xabc" as before, and the test holds that line.

An endless Range carries `INTPTR_MAX` as its end, and the Range arm of `String#[]=` took only `SP_INT_NIL` for "no end": from a start of 0 the count of characters, `INTPTR_MAX - 0 + 1`, ran over and nothing was replaced. From any other start the count stays an Integer and the splice clamps it, so `s[1..] = "x"` was right. The arm now takes an end of `INTPTR_MAX` from a start of 0 as no end. Where the end is written in the index as an Integer that cannot be nil, it is never endless and the C is what it was.

No store that was right pays: callgrind counts no more instructions after than before for `s[5..] = "xyz"`, for a Range out of a variable and for an end that may be nil. Two existing tests change their generated C and print what they printed.

This stands on "String#[]= with a Range starting outside the String raises RangeError": it changes the line beside that pull request's check, and the two do not merge apart.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
