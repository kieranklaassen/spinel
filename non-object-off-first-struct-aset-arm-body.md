## What this changes

```ruby
Pt = Struct.new(:m, :n)
x = [5, Pt.new(1, 2)][0]
begin
  x[0] = 7
rescue NoMethodError => e
  p e.class                 # NoMethodError in CRuby; master segfaults at the store
end
```

`spinel diff` on master: crash, SIGSEGV where CRuby prints `NoMethodError` and exits 0.

The box of a value that is no object carries class id 0, the id of the program's first class, and the dispatch key keeps such a value off that class's arm when the class takes one (`poly_key_cls0`). A Struct's builtin `[]=` has no method scope, so its arm was not counted, and with a Struct as the first class `x[k] = v` wrote a member through a pointer that is no Struct.

Now the key counts the Struct's arm: an Integer, a Float, nil and true raise NoMethodError as in CRuby. A dispatch in which class 0 is no such Struct emits the same C.

Not here: a String's store and a Symbol's call are still dropped there, as they are on master when another class comes first (on master with the Struct first the String had a member's box written into its bytes); the String's store is cured by the pull request that follows.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
