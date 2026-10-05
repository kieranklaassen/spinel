<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Before:

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

After: `"fancy plain both"` and `[Fancy, Plain, Both]`.

Ruby prepends the arguments last to first, as it includes them, so the first one listed is found first: `prepend A, B` is `prepend B; prepend A`. The prepend pass took them first to last, and the ancestors table did the same. Both now go last to first, as the include pass does since #7447.

A module named again in the list is prepended once, where its last naming puts it: `prepend A, B, A` gives `[B, A, K]`.

Measured above the pull request this one depends on, on master fa08b100 with gcc 13 against CRuby 3.3.6: 162 programs with two or three modules in one `prepend` (their methods calling `super` plainly, with arguments and with a block; the class reopened or subclassed; a module named again). 115 wrong answers are right now, 30 are right before and after, 12 do not build and 3 are refused before and after, and 2 stay wrong (a `prepend` on a singleton class does nothing, as on master). No program that is right is lost. Of 9,672 more prepend programs none gets other C. clang 18.1 gives the same on all 162.

Generated C against master fa08b100 (`make cident`): 6,111 programs identical; the only C that differs is the new tests' (this one and the five beneath). optcarrot's C is identical. On 9c4eec71 the commit picks without conflict above the three; the test fails there (9 of 12 lines) and passes with it.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: # (A super past a prepend reaches the parent's prepended method)
