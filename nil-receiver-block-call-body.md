<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

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

Left alone: the block of `none&.then { }` runs although the receiver is nil, as on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
