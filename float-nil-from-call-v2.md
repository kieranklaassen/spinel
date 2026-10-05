<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Before:

```ruby
def nothing = nil

def run(k)
  r = k ? 1.5 : nothing
  [r, 1]
end
p run(false)
```

prints `[NaN, 1]`.

After: `[nil, 1]`, as CRuby prints.

On the same local `r + 1.0` was NaN, or nil where the sum is the method's value, where CRuby raises NoMethodError, and `{ a: r }[:a].nil?` was false. An Integer joined the same way and stored into a Hash was not nil there either. No rescue is needed for any of it; `r = nothing rescue 1.5` and the begin form were wrong the same way.

A Float or an Integer that also sees nil keeps its slot, with the nil as the slot's sentinel, and what boxes the value or computes with it asks whether it can be that sentinel (`nullable_int_value`, src/analyze.c). The literal nil answered yes, and so did a search miss and a method whose number can be nil. A call that can answer only nil, a method that returns nil or `puts`, answered no, so the local, the instance variable or the method's return it was joined into was never marked, and the sentinel was boxed as a number. It answers yes now: one line.

It costs what a literal nil costs on master. A slot such a call can reach pays for the sentinel: at -O2 over 4,000,000 turns, 5 more instructions a turn on an instance variable's add and 3 more on a call with such a Float parameter. And an Integer parameter such a call can reach holds nil as the sentinel, as one a literal nil reaches does, so -2^63 handed to it raises master's `integer -9223372036854775808 collides with the nil of a nullable Integer slot (RangeError)` where it was passed through: twelve programs of that one value are right on master and raise now, and with a literal nil handed in place of the call master raises the same.

Left alone, as on master: a constant holding nil (`r = k ? 1.5 : NOTHING`), a local written from such a call (`x = nothing; r = k ? 1.5 : x`) and a block parameter given nil are still NaN when boxed.

- Generated C (`make cident` against master fa08b100d): 6,110 programs identical, 1 differs, the new test. No refusal changes, and no benchmark's C changes.
- scale-test: 1.71 / 4.73 / 6.06 / 4.22, the same four as master 2bd029b7e.
- 2,393 generated programs at -O0 and -O2 (measured on master c6bbdfbc9; 836 of them join a nil from one of seven sources with a Float or an Integer in one of eight ways and use it in one of eleven): 235 were wrong and are right, 130 are right on both with different C, and none that was right is wrong. Six more change their C and are wrong at -O2 on both: they write a local before a raise, which master loses there. Every program that is right with different C is right under `SPINEL_GC_STRESS=2` as well. Of the 836, 35 keep their C and are wrong on both: the constant.
- A second reading ran 3,818 more on master 2bd029b7e (the call joined with a Float or an Integer by 24 routes and used 78 ways, handed to what asks for a number, and used inside one method): 724 were wrong and are right, and none that was right is wrong. Twelve that answered wrong raise TypeError now, which is not CRuby's answer either: `r.times`, `rand(r)` and `0.step(r, 2)` with the nil.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
