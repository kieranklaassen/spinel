With this branch merged into master fa08b100d, a write through a boxed receiver reaches the member, and an append through the member's reader after it is lost without a word:

```ruby
S = Struct.new(:x, :n)
c = S.new(nil, 1)
a = [c, 1]
a[0][:x] = +"r"
c.x << "z"
p c.x
```

- CRuby (`--enable-frozen-string-literal`): `"rz"`
- master fa08b100d: `undefined method '<<' for nil (NoMethodError)`, since the bracket write stored nothing
- master with this branch: `"r"`, the same at `SPINEL_GC_STRESS` unset, 1 and 2

The write is right now. The member is a boxed slot (it holds nil as well), a plain String in a box is a value, and `c.x << "z"` answers a new String that nothing stores back into the member. Master loses the same append today when the member is filled by its setter (`c.x = +"r"; c.x << "z"` prints `"r"` since #7462 made that read compile), so this is one more way to reach an existing fault, not a new one.
