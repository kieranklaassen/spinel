<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Base
  def one(a) = yield([a])
end
class Kept < Base
  def one(x, ...) = [x, super(...)]
end
p Kept.new.one(1, 6) { |v| v }    # [1, [6]]
```

printed `[1, [1]]`, with no error. Called `one("s", 7)` instead, the program did not build (`assignment to 'sp_int' from 'const char *'`); with both calls it printed `["s", ["s"]]` for the second.

A method that keeps its `...` has a parameter for each one it names, then a slot for each argument its `...` takes. The binder of the inlined parent read the forwarder's parameters from the first, so `a` took `x`. It now starts past the ones the forwarder names (`fwd_lead_count`), and a declared keyword is looked for by name from there, so `def key(x, ...)` over `def key(a, k: 7)` called `key(1, 6, k: 2)` answers `[1, [6, 2]]`.

It starts there only where each positional parameter of the parent then has a forwarded slot of its own. Elsewhere the call keeps its C:

- A parent that keeps its `...` too. It is bound slot for slot from the forwarder: `def far(y, ...)` over `def far(x, ...)` is as wrong as it was.
- A call that forwards fewer positionals than the parent takes, which CRuby refuses with its count message.

`tools/cident.sh`, on the pull request this depends on, itself on d02a49fb7f74: 6408 identical, 1 differ (the new test), 0 refusal changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: the pull request "Too few or too many arguments through a `...` forward raise ArgumentError"
