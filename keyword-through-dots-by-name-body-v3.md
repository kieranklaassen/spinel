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

One cost of this pull request alone. Where the keys are of different classes and a site leaves one out, master stopped and this builds:

```ruby
class Base
  def self.m(a, k: 1, j: "d") = yield([a, k, j])
end
class Kept < Base
  def self.m(...) = super(...)
end
Kept.m(4) { |x| p x }             # [4, 1, "d"]
Kept.m(5, j: "s2") { |x| p x }    # [5, 1, "s2"]
```

is a C compiler error on master and prints `[4, 1, nil]` and `[5, 1, "s2"]` here. Master's stop was the C compiler meeting a String in an Integer slot, not a judgment of the program: with `j: 8` and `j: 22`, keys of one class, master builds it and prints `[4, nil, 8]` and `[5, 22, 8]`. Of 1,136 generated programs with keys of different classes, 57 go this way: 42 to a wrong line, 15 to a NoMethodError or TypeError on the key that was left out. Each has such a twin that is wrong on master. The next two pull requests (the default for a key left out, then `missing keyword`) make all 57 right, and with them all 1,136 are.

A method that keeps its `...` has one parameter for each positional argument and one for each key its sites pass, in the order the sites first name them. `emit_inline_bind_params` bound the parent's parameters from those by position, so a key written in another order went to another keyword, and a keyword no site passes read the parameter at its index, or a zero. A declared keyword now reads the forwarder's parameter of its own name, and with none, takes its own default.

The analyzer typed those parameters by position too (`bind_args_params`), so with keys of different classes, `pair(5, j: "s", k: 2)`, k was typed as a String: master printed `[5, "s", 2]`, and bound by name alone it would stop in the C compiler. The second commit types a declared keyword from the forwarder's parameter of its own name, as it is now bound.

Where every site passes every key in the order the parent declares them, name and position agree and the C is unchanged.

Not in this change:

- A key one site passes and another leaves out. The site that leaves it out still binds nil where the default belongs: `opt(5, k: 2)` then `opt(5)` prints `[5, 2]` and `[5, nil]`, on master and here. Where a second default reads that keyword, `def m(a, k: 7, j: k + 1)`, master printed `[5, nil, 0]` for the second call and this raises NoMethodError on `nil + 1`. The next pull request binds the default there.
- A required keyword that no site passes prints nil where CRuby raises `missing keyword`, as on master.
- `**opts` in the parent is not filled through `...`, as on master.

`tools/cident.sh`: the first commit against d02a49fb7f74, 6404 identical, 1 differ (its test); the second against the first, 6405 identical, 1 differ (its test), 0 refusal changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
