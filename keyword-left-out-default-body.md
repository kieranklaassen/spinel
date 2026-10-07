<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Base
  def opt(a, k: 7) = yield([a, k])
end
class Kept < Base
  def opt(...) = super(...)
end
p Kept.new.opt(5, k: 2) { |x| x }    # [5, 2]
p Kept.new.opt(5) { |x| x }          # [5, 7]
```

printed `[5, 2]` and `[5, nil]`, with no error.

A method that keeps its `...` has one parameter for each key any of its sites passes. A site that leaves a key out binds that parameter nil, and `super(...)` passed the nil on as if the site had written it. The expansion now notes the parameters a site gave no argument for; a keyword bound from one takes its own default, and a forwarder between the two hands the gap on.

A site that passes every key keeps its C.

Not in this change:

- A required keyword that a site leaves out prints nil where CRuby raises `missing keyword`, as on master.
- `k: nil` written at one site and the key left out at another does not build, as on master.
- `**opts` in the parent is not filled through `...`, as on master.

`tools/cident.sh` against the pull request this depends on, itself on d02a49fb7f74: 6405 identical, 1 differ (the new test), 0 refusal changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: the pull request "A keyword through `super(...)` in a method with `...` binds by name"
