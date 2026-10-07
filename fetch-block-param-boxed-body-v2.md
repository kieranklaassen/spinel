<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def pick(n) = n > 0 ? {"a" => 1, :s => 2, 3 => 4} : [10, 20]
x = pick(1)
p x[:s]
p(x.fetch(9) { |k| k * 2 })   # undefined method 'fetch' for an instance of Hash; CRuby prints 18
```

`fetch` with a block lost its Hash arm, or did not build, when the receiver may be a Hash or an Array and the program also reads it with a Symbol key. The read types the still untyped local as a Hash of Symbol keys for one round of inference; the block's parameter took that key type and kept it when the local was boxed a round later. It is now boxed where the key's type is not the parameter's, as it already is in the program without the read. The C is that program's plus the read, so where master's boxed dispatch is itself wrong the cured program answers the same wrong thing: for the key `2.5`, `k.even?` prints `true` with and without the read, where CRuby raises a NoMethodError.

Only for a key whose type is known and is no String and no Symbol: a boxed String is a copy under a change in place. And only while no other fetch block of the program would be left behind with its failure. Those programs fail as they did.

Every other corpus program compiles to the same C in both overflow modes. The fetch blocks are listed once a round of inference, not walked again for every parameter: under callgrind, spinel takes 1.0002 times master's instructions on 1,000 fetch blocks that are right on master, and 1.004 times on 1,000 that this cures. The list itself is still read at each ask, so 1,000 cured blocks beside 1,000 Symbol-key ones take 1.016 times.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
