<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
module Plain
  def hi = "plain " + super
end
module Fancy
  def hi = "fancy " + super
end
class Both
  prepend Fancy, Plain
  def hi = "both"
end
p Both.new.hi              # "plain fancy both"; CRuby prints "fancy plain both"
p Both.ancestors.take(3)   # [Plain, Fancy, Both]; CRuby prints [Fancy, Plain, Both]
```

Ruby prepends the arguments last to first, as it includes them, so the first one listed is found first: `prepend A, B` is `prepend B; prepend A`. The prepend pass took them first to last, and the ancestors table did the same. Both now go last to first, as the include pass does since upstream pull request 7447.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: # (A super past a prepend reaches the parent's prepended method)
