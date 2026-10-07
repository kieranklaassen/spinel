<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Symbol as the index of a boxed String or Symbol answered nil where CRuby raises:

```ruby
def pick(n) = n > 0 ? {a: 1} : +"abc"
s = pick(0)
p s[:a]   # nil; CRuby: no implicit conversion of Symbol into Integer (TypeError)
```

This turns a silent nil into CRuby's raise. Of 4,496 programs that read a boxed receiver by an index of every kind, 226 reach it: none was right on master (222 printed a wrong answer, 4 raised NoMethodError where CRuby raises TypeError) and all 226 are right here.

A Hash's read meets no new test. By callgrind a loop reading `h[:a]` and `g["a"]` from boxed Hashes runs 223 instructions a pass on master and 224 here with gcc, 214 and 210 with clang: the one instruction is gcc's register choice for the class id once the branch for a receiver that is no object holds more than a return.

`sp_poly_get_sym` answered nil for every receiver that is no Hash. It now raises for a String, a shared String and a Symbol (whose `[]` is its String's). That is the read behind `s[:a]`, `s[:a] += "x"`, `s[:a] ||= 1` and an index that is itself boxed (unless a class of the program defines its own `[]`: `s[k]` with a boxed Symbol then still answers a character). An Integer, a String, a Range or a Regexp index takes other paths and answers as before. The test stands where the receiver is already known to be no object, and the shared String is one more arm of the switch.

The same raise for an Array receiver is the commit "A keyword splat sent to a method without keywords arrives as its last positional, and a boxed array index of another kind raises TypeError" where the index is boxed, and "A Symbol or String index on a boxed Array raises TypeError" where it is a literal; neither touches a String or a Symbol receiver.

No generated C changes: the function is in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
