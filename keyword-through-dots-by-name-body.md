<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Base
  def pair(a, k:, j:) = yield([a, k, j])
  def opt(a, k: 7) = yield([a, k])
end
class Kept < Base
  def pair(...) = super(...)
  def opt(...) = super(...)
end
p Kept.new.pair(5, j: 3, k: 2) { |x| x }    # [5, 2, 3]
p Kept.new.opt(5) { |x| x }                 # [5, 7]
```

printed `[5, 3, 2]` and `[5, 0]`, with no error.

A method that keeps its `...` has one parameter for each positional argument and one for each key its sites pass, in the order the sites first name them. `emit_inline_bind_params` bound the parent's parameters from those by position, so a key written in another order went to another keyword, and a keyword no site passes read the parameter at its index, or a zero. A declared keyword now reads the forwarder's parameter of its own name, and with none, takes its own default.

Where every site passes every key in the order the parent declares them, name and position agree and the C is unchanged.

Not in this change:

- A key one site passes and another leaves out. The site that leaves it out still binds nil where the default belongs: `opt(5, k: 2)` then `opt(5)` prints `[5, 2]` and `[5, nil]`, on master and here. Where a second default reads that keyword, `def m(a, k: 7, j: k + 1)`, master printed `[5, nil, 0]` for the second call and this raises NoMethodError on `nil + 1`. The next pull request binds the default there.
- A required keyword that no site passes prints nil where CRuby raises `missing keyword`, as on master.
- `**opts` in the parent is not filled through `...`, as on master.

`tools/cident.sh` against d02a49fb7f74: 6404 identical, 1 differ (the new test), 0 refusal changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
