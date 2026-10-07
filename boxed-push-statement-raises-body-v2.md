<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`push` as a statement on a boxed String or Integer ran the receiver's `<<` where CRuby raises:

```ruby
v = [+"s", 5][0]
v.push("!")
p v   # "s"; CRuby: undefined method 'push' for an instance of String (NoMethodError)
```

The fix is a test at run time, and it has a cost: a one-argument `push` or `append` statement on a boxed receiver takes a few more instructions when the receiver is an Array. By callgrind, instructions for one loop iteration, master and this branch:

| loop body | gcc | clang |
|---|---|---|
| `row[0].push(1)`, an Integer Array | 42 → 43 | 46 → 53 |
| `v.push(i)`, a mixed Array in a local | 51 → 56 | 52 → 60 |
| `row[0] << "b"; row[0].push("c")`, a String Array | 193 → 204 | 156 → 164 |

Only such statements change: 23 programs of the corpus, optcarrot not among them.

`push` and `append` with one argument, as a statement on a boxed receiver, were emitted as `sp_poly_shl`. That is right for an Array and for a queue. A String and an Integer answer `<<` themselves, so `v.push("!")` ran the String's `<<` and `v.push(1)` shifted the Integer, with no NoMethodError; a Float, a Symbol, nil or a Hash raised it naming `<<`. The value form (`r = v.push("!")`) and `push` with another argument count already test the receiver at run time. The statement now does too, in `sp_poly_push_stmt`: an Array appends, a queue takes a push, anything else raises naming the method sent. `<<` is emitted as before.

The test prints the messages, in CRuby 4.0's wording (`'push'`).

## `make gate` (on this branch merged with current master)

```
not run yet: this branch waits for the full gate
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
