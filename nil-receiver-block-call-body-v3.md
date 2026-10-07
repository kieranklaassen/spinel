<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def none
  puts "called"
  nil
end
p !none
```

printed `true` and never called `none`; CRuby prints `called`, then `true`. Where the receiver's type is nil alone, `!` answered true and `&.` answered nil without emitting the receiver, so a method that always answers nil was not called at all: `if !none`, `unless !none`, `!!none`, `until !none`, `none&.size`.

Both arms now evaluate such a receiver and then answer as before, as the other arms for a nil receiver (`nil?`, `to_s`, `inspect`) already do. A receiver that is only a read is emitted as it was. The arguments of a `&.` call on nil stay unevaluated, as in CRuby.

One corpus program's C changes: in `test/empty_block_body_iterators.rb`, `drop_while`'s `!yield` over an empty block now emits the empty block.

Not here:

- A receiver that holds a rescue modifier (`!(none rescue nil)`) stays unevaluated: a rescue modifier typed nil has no C yet (`x = (none rescue nil)` stops the build with "variable or field '_t1' declared void"), so evaluating it here would stop a build that passes.
- A receiver that holds a `&.` call with a block on nil (`!nil&.then { }`) stays unevaluated too: emitted for its value, such a call runs its block, as `x = nil&.then { }` does on master.
- Inside an interpolation a statement receiver runs ahead of the earlier parts, as `"#{a}#{(begin; b; nil; end).nil?}"` does on master.
- As a middle argument in an Integer slot, `take(a, none&.size, b)` runs `none` after `b` under gcc, as `take(a, none, b)` does on master.
- The block of `none&.then { }` runs although the receiver is nil, as on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
