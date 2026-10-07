<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Cost: one instruction a store for a String key or a boxed key into a boxed Hash, gcc's layout of `sp_poly_set_poly` (the Hash's path has no added test). By callgrind, a million stores: a String key 226,671,484 to 227,671,490, a boxed key 137,671,799 to 138,671,805; a Symbol key 89,671,669 to 89,671,673 and an Integer index into a boxed Array 115,670,583 to 115,670,589 are the same.

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

The boxed stores have no String arm: `sp_poly_set_sym` (a Symbol key) and `sp_poly_set_poly` (a boxed key, and any key through the dispatch default) answer the value for a receiver that is no object, and a shared String fell to `default:`. A boxed Array given such a key already raises this TypeError. A String receiver, plain or shared, now raises it too, from one helper both functions call (`sp_poly_str_key_refuse`). The cure stands in the callee, so every asker gets it: no call site is taught. A nil, a Symbol, an Array and a true key, each on a local, an instance variable, a global, a block parameter, a lambda parameter and a method parameter: 24 programs, each prints the String unchanged with no error on master, each raises here.

Where the program gives String a `[]=` of its own, the key is that method's to take, and a Symbol key is no error there. Such a program keeps the stores it had: the startup code sets `sp_str_own_aset` where String, or a module it includes or prepends, defines `[]=`, and the helper answers at once. Eight programs of that kind (the method logs, does nothing, is reached under `||=`, takes a literal Symbol, sits in a prepended or an included module, beside a Struct, on a frozen String) print here what they print on master: CRuby's answer for seven, and for the included module the line under "Not here". String reopened for another method is not such a program and raises.

An Integer, a Float, a String, a Regexp and a Range are `String#[]=`'s own keys: where one of them reaches these two functions it does what it did. `make cident`: the generated C of the corpus is unchanged but for the one startup line in the new test that defines `String#[]=`.

Not here, the same on master:

- a Float key (`s[1.5] = "x"` stores at index 1 in CRuby; dropped: that key must store and write the new String back to the receiver, which these two functions cannot do; six programs, the same on both) and a Bignum key (RangeError in CRuby; dropped);
- every other object as a key: a Class, a Proc, a Time, a plain object, a Struct, a Set and an object that answers `to_str` raise this TypeError in CRuby; an object that answers `to_int`, a Rational and a Float Range store. All are dropped in silence on both;
- a `[]=` an included module gives String: CRuby runs the builtin ahead of the module's and raises; master goes on, and so does this branch (the stand-aside above);
- a boxed Range given any index store (NoMethodError in CRuby; silent).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
