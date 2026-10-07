<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def pick(n) = n > 0 ? {a: 1} : +"st"
s = pick(0)
begin
  s[:a] = "x"
  puts "stored"
rescue TypeError => e
  puts e.message
end
p s    # CRuby: no implicit conversion of Symbol into Integer, then "st"; master: stored, then "st"
```

`spinel diff` on master: output-diff, `stored` for the TypeError's message; on this branch: same.

A boxed value that holds a String took `s[:a] = v` in silence: the store was dropped, the program went on and the String read back as it was. The same for a nil, true, false, Array or Hash key, for a key read out of an Array (`k = [:a, 1][0]; s[k] = v`), for a String a method has appended to, and beside a class that owns `[]=` (every Struct does), where the store goes through the class dispatch and falls to its default.

The boxed stores have no String arm: `sp_poly_set_sym` (a Symbol key) and `sp_poly_set_poly` (a boxed key, and any key through the dispatch default) answer the value for a receiver that is no object, and a shared String fell to `default:`. A boxed Array given such a key already raises this TypeError. A String receiver, plain or shared, now raises it too, from one helper both functions call (`sp_poly_str_key_refuse`).

An Integer, a Float, a String, a Regexp and a Range are `String#[]=`'s own keys: where one of them reaches these two functions it does what it did. `make cident`: the generated C of the corpus is unchanged, the change is in the runtime alone.

Cost by callgrind, a million stores into a boxed Hash (the receiver these functions serve most): a Symbol key 89,671,697 to 89,671,653; a String key 226,671,512 to 227,671,470 and a boxed key 137,671,824 to 138,671,782, one instruction a store, gcc's layout of `sp_poly_set_poly` (the Hash's path has no added test); an Integer index into a boxed Array 115,670,576 to 115,670,534.

Not here, the same on master: a Float key (`s[1.5] = "x"` stores at index 1 in CRuby; dropped) and a Bignum key (RangeError in CRuby; dropped); a boxed Range given any index store (NoMethodError in CRuby; silent).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
