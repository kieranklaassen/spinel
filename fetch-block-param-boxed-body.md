<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`fetch` with a block lost its Hash arm, or did not build, when the receiver may be a Hash or an Array and the program also reads it with a Symbol key:

```ruby
def pick(n) = n > 0 ? {"a" => 1, :s => 2, 3 => 4} : [10, 20]
x = pick(1)
p x[:s]
p(x.fetch(9) { |k| k * 2 })   # undefined method 'fetch' for an instance of Hash; CRuby prints 18
```

The read types the still untyped local as a Hash of Symbol keys for one round of inference. The block's parameter took that key type and kept it when the local was boxed a round later. It is now boxed where the key's type is not the parameter's, as it already is in the program without the read.

Only for a key whose type is known and is no String and no Symbol: a boxed String is a copy under a change in place. And only while no other fetch block of the program would be left behind with its failure. Those programs fail as they did.

Every other corpus program compiles to the same C in both overflow modes.

## `make gate` (on this branch merged with current master)

```
not run yet: this branch waits for the full gate
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
