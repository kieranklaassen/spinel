<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`push` as a statement on a boxed String or Integer ran the receiver's `<<` where CRuby raises:

```ruby
v = [+"s", 5][0]
v.push("!")
p v   # "s"; CRuby: undefined method 'push' for an instance of String (NoMethodError)
```

`push` and `append` with one argument, as a statement on a boxed receiver, were emitted as `sp_poly_shl`. That is right for an Array and for a queue. A String and an Integer answer `<<` themselves, so `v.push("!")` ran the String's `<<` and `v.push(1)` shifted the Integer, with no NoMethodError; a Float, a Symbol, nil or a Hash raised it naming `<<`. The value form (`r = v.push("!")`) and `push` with another argument count already test the receiver at run time. The statement now does too, in `sp_poly_push_stmt`: an Array appends, a queue takes a push, anything else raises naming the method sent. `<<` is emitted as before.

## `make gate` (on this branch merged with current master)

```
not run yet: this branch waits for the full gate
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
