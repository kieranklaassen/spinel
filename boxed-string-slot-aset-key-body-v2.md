<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def pick(i) = i == 0 ? "hello world".dup : 3
a = [pick(0), pick(1)]
a[0]["world"] = "there"
p a                          # CRuby ["hello there", 3]; here ["hello world", 3]
```

A String key's store into a boxed String element of an Array or a Hash is lost. This writes it to the slot, as the Integer index's store on the same element (`a[0][6, 5] = "there"`) is written. It has two costs:

- One answer that was right goes wrong. A second name taken for the element before the store keeps the old contents, as it does after the Integer index's store:

  ```ruby
  b = a[0]
  a[0]["world"] = "there"
  p a[0]                     # CRuby "hello there"; before "hello world"; now "hello there"
  p a[0] == b                # CRuby true; before true, both being stale; now false
  ```

  With `a[0][6, 5] = "there"` in the store's place master prints "hello there" and false today. Of 336 programs that take the second name six ways and look seven ways, 48 are made right (the element read), 96 go from right to wrong (`==` and `equal?` against the second name) and 192 are wrong before and after (the second name read); each of the 336 prints what master prints for its Integer-index twin.
- By callgrind, a Hash, an Array or a shared String in such a slot pays one test of the element's tag and one of a pointer: `a[0]["k"] = i` on a Hash element goes from 204 instructions to 210 (clang 217 to 224), `h[1]["k"] = i` from 354 to 355 (clang 358 to 365).

A String that is not shared has no place to change in: `sp_poly_str_aset_key` answers its new contents and the caller stores them where the String was read. For a local or an instance variable the emitter does; for an element it dropped the answer. `emit_poly_index_call` now keeps the String it read from `outer[i]` and puts the call's answer into the slot if the slot still holds that String. The arm applies where a second read of `outer[i]` is the same read: the outer is an Array or a Hash of boxed values, neither it nor its index runs code, and a key or a value that runs code has already run, in Ruby's order. Everything else emits the C it did.

Not here:

- The element of a boxed outer keeps its old contents: `a = [[pick(0), 1], 2]; a[0][0]["world"] = "there"; p a` prints `[["hello world", 1], 2]` (CRuby `[["hello there", 1], 2]`). So does a constant's Array, an outer reached through a call, a Hash under a String or a Symbol key, and `a[0]["world"] += "!"`.
- A key that is itself boxed (`k = ["world", 2][0]; a[0][k] = "there"`) raises TypeError, "no implicit conversion of String into Integer".
- Two stores that kept the old contents without a word are still wrong, another way: `a[0]["world"] = 5` stores "5", as a local's store does (CRuby TypeError), and the element of a frozen Array raises FrozenError, as the Integer index's store does (CRuby stores, the String is not frozen).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
