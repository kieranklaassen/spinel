<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Base
  def one(a, k:) = yield([a, k])
end
class Kept < Base
  def one(...) = super(...)
end
Kept.new.one(5) { |x| p x }    # missing keyword: :k (ArgumentError)
```

printed `[5, 0]`, with no error. With two required keywords and a site that passes one, it printed a nil for the other.

A call judges its keywords before it binds them (`emit_call_arity_check`), but a `...` forward has no keyword hash to judge: its keys are the forwarder's parameters. The binder now asks, for each required keyword of the parent, whether the forwarder carries that key from this site, and raises CRuby's message for the ones it does not (`missing keyword: :k`, `missing keywords: :k, :j`), ahead of the unknown-keyword check, as CRuby orders them.

It raises only where the forwarder is known to hold every keyword it was handed: its call wrote each key out. A key that arrives by `**`, or through another `...` whose parameters are not the same, is not one of the forwarder's parameters, and those calls keep their C.

Two commits. The first shares `emit_argument_error` with the inline binder and changes no generated C; the second is the fix.

Not in this change:

- A key that reaches the forwarder only by `**` is dropped, as on master: `Kept.new.one(5, **h)` does not hand `k` on.
- `**opts` in the parent is not filled through `...`, as on master.

`tools/cident.sh`, on the pull request this depends on, itself on d02a49fb7f74: the first commit 6406 identical, 0 differ; the second against the first 6406 identical, 1 differ (the new test), 0 refusal changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: the pull request "A key a site leaves out of a method with `...` takes the keyword's default"
