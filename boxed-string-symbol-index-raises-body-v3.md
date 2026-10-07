<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Symbol as the index of a boxed String or Symbol answered nil where CRuby raises:

```ruby
def pick(n) = n > 0 ? {a: 1} : +"abc"
s = pick(0)
p s[:a]   # nil; CRuby: no implicit conversion of Symbol into Integer (TypeError)
```

This turns a silent nil into CRuby's raise. Of 2,560 probe programs it changes 185: 181 printed the nil or went on with it, 4 raised NoMethodError on it, and all 185 now answer as CRuby does. The 1,827 that were right stay right.

A Hash's read meets no new test. By callgrind a loop reading `h[:a]` and `g["a"]` from boxed Hashes runs 223 instructions an iteration on master and 224 here with gcc, 214 and 210 with clang: the one instruction is gcc's register choice for the class id once the branch for a receiver that is no object holds more than a return.

`sp_poly_get_sym` answered nil for every receiver that is no Hash. It now raises for a String, a shared String and a Symbol (whose `[]` is its String's). That is the read behind `s[:a]`, `s[:a] += "x"`, `s[:a] ||= 1` and an index that is itself boxed (unless a class of the program defines its own `[]`: `s[k]` with a boxed Symbol then still answers a character). An Integer, a String, a Range or a Regexp index takes other paths and answers as before. The test stands where the receiver is already known to be no object, and the shared String is one more arm of the switch.

Separate, no order: "A Symbol or String index on a boxed Array raises TypeError", "A Float, true or Array index on a boxed Array is not element 0" and "fetch and values_at on a boxed Array refuse an index that is no Integer".

No generated C changes: the function is in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
