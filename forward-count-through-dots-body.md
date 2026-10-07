<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Base
  def two(a, b) = yield([a, b])
end
class Kept < Base
  def two(...) = super(...)
end
Kept.new.two(1) { |x| p x }    # wrong number of arguments (given 1, expected 2)
```

printed `[1, 0]`, with no error, and `two(1, 2, 3)` printed `[1, 2]`.

A call judges its count before it binds (`emit_call_arity_check`), but the binder skips that for a `...` forward: its arguments are the forwarder's parameters, one slot for each positional of the longest site. The binder now counts the slots this site filled and hands that count to `arity_count_error`, the rule of the direct call paths, ahead of the missing-keyword check, as CRuby orders them. With a required keyword left out as well, the pull request this depends on raised `missing keyword: :k`; it is now CRuby's `wrong number of arguments (given 1, expected 2; required keyword: k)`.

It judges only where the site is known to have written its positionals out: no `*` at the call, and the keys proven as the missing-keyword check needs them. A key passed to a parent that declares no keyword is one more positional, a Hash, which no slot holds; and a second forwarder that names a parameter of its own (`def m(x, ...)`) is bound slot for slot, so what it forwards is not counted. Those calls keep their C.

Not in this change:

- An unknown keyword through `...` is not judged: `def key(a, k: 7)` called `key(1, z: 2)` prints `[1, 7]` where CRuby raises `unknown keyword: :z` (master printed `[1, 2]`).
- `**opts` in the parent is not filled through `...`, as on master.

`tools/cident.sh`, on the pull request this depends on, itself on d02a49fb7f74: 6407 identical, 1 differ (the new test), 0 refusal changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: the pull request "A required keyword a `...` forward does not carry raises `missing keyword`"
