<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def pick(n) = n > 0 ? {"a" => 1, :s => 2} : [1, 2]
x = pick(1)
p x.fetch(:zz) { |k| k }   # C did not build; CRuby prints :zz
```

`fetch` with a block that takes the missing key did not build in C when the receiver may be a Hash or an Array and the key is a Symbol or a String literal. The fetch itself types the still untyped local as a Hash of that key type for one round of inference, so the block's parameter is a Symbol's or a String's slot, and rightly. But the local is boxed a round later, the Hash arm holds its key boxed, and that boxed key was assigned to the typed slot.

The key is now unboxed into the slot where a list shows the slot is the key's own: the key is a Symbol or a String literal, nothing assigns the parameter, every read of it is a call's receiver, an interpolation or the block's value, and the block answers a plain value. Inference does not change. Everything outside the list fails in C as it did, and so does a program in which another fetch block is left with a slot of another type than its key (a Symbol key and a String key fetched from one receiver). The list is all or nothing for the program, so under `--share-strings` one slot that is a shared handle stands every fetch block of the program down: this change's own test does not build with the flag, as it does not on master, and `share-strings-test` does not run it.

Every other corpus program compiles to the same C in both overflow modes. Whether a fetch block is left behind is the whole program's answer, so it is asked once and kept, not asked again by every fetch block: under callgrind, spinel takes 1.008 times master's instructions on 1,000 such fetch blocks, and 1.0003 times on 1,000 that are right on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A fetch block's parameter is boxed where its type is not the key's)
