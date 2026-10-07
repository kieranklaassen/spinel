<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Through a boxed value a class's own `freeze` and `frozen?` were never called:

```ruby
class Doc
  def initialize = @sealed = false
  def freeze
    @sealed = true
    self
  end
  def sealed = @sealed
end
class Draft
  def frozen? = true
end
d = Doc.new
row = [d, Draft.new, 5]
row[0].freeze
p d.sealed            # false; Ruby prints true
p row[1].frozen?      # false; Ruby prints true
p d.frozen?           # true; Ruby prints false
```

The boxed `freeze` arm called the builtin whatever class the value had: `row[0].freeze` never ran Doc's method (`p d.sealed` printed false) and froze the object for real (`p d.frozen?` printed true). The boxed `frozen?` arm read the header's bit and never asked the class.

Both arms now stand down in a program where a class defines the name, as the `nil?` arm above the `freeze` line and the `dup` and `clone` arm below the `frozen?` line do (`user_defines_or_reads`). The call goes on to the dispatch on the value's class: the class's method runs for its objects, and every other value comes back to the same builtin arm.

Depends on the pull request that makes `super` in a `freeze` or `frozen?` override Object's: a `freeze` that ends in `super` and is called through the box raised at the `super` before it, where the builtin had answered.

The test fails without this change. No corpus program's generated C changes; optcarrot's is unchanged. A program with no `freeze` or `frozen?` of its own emits the C it did. Beside a class that defines one, a builtin value in the box pays the dispatch: three instructions a `frozen?` call with gcc and clang, four a `freeze` call with gcc and one fewer with clang (callgrind, on master 2801817b with the pull request this depends on).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (the pull request "super in a freeze or frozen? override is Object's")
