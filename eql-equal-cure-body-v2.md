<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def id
  puts "called"
  1
end
p id.equal?(nil)
```

printed `false` and never called `id`; CRuby prints `called`, then `false`. Where the argument's type can never equal the receiver's, the arms for `eql?` and `equal?` on an Integer or a Float, for `Float#===`, and for `eql?` on an object answered false after emitting only the argument. With an argument of more than one kind, the Integer and Float arms emitted the receiver after it, and only when it held a number of that kind.

Each arm now evaluates a receiver that is more than a read, and first. A receiver that is only a read is emitted as it was.

Left alone: `eql?` and `equal?` on an object with an argument of more than one kind still emit the receiver only when the argument holds an object.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
