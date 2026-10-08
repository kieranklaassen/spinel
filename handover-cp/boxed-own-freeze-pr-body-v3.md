<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A cost first. In a program where a class has a `freeze` or `frozen?` of its own, every such call on a boxed value now takes the dispatch on the value's class before it reaches the builtin: three to seven instructions a call, by the loop around it and the compiler (callgrind, master 5d762fb1, whose C for these programs the pull request this depends on leaves alone; a builtin value read from a mixed Array in a loop of 3,000,000: over five kinds of value a `frozen?` call costs 3.0 more with gcc and with clang and a `freeze` call 4.2 more with gcc and 1.0 fewer with clang; over an Integer and a String alone, `frozen?` 4.0 and 7.0, `freeze` 3.0 and 7.0). It is what master charges `dup`, `to_s` and `nil?` in the same program today (5.0, 5.0 and 1.5 instructions a call with gcc, 4.0, 4.1 and 2.4 with clang, on master 1df866be): the two arms now ask the question those arms ask, whether a class of the program defines the name. A boxed value carries no record of the classes it can hold, so there is nothing narrower to ask; a later change that gave one answer for every name master dispatches this way would repay all of them at once.

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

They stand down only where that dispatch keeps the builtin for every other value (`poly_dispatch_keeps_builtin`, the tests the dispatch's default arm makes: no block on the call, and a builtin answer that fits the call's slot). A call that carries a block (`x.freeze { }`) has no such arm, and the default would raise NoMethodError for 5, a String or nil, which master answers; there the builtin line answers as it did.

Depends on the pull request that makes `super` in a `freeze` or `frozen?` override Object's: a `freeze` that ends in `super` and is called through the box raised at the `super` before it, where the builtin had answered.

Not covered: a call through a box that carries a block, where the builtin answers whatever the class. And a typed object's own `frozen?` that answers something other than true or false prints true or false, as before: a program that did not build for a boxed call beside such a method (`p row[0].frozen?` where the method answers a Symbol) now builds and prints true for the typed call, which is what master prints with the boxed call's value written in its place.

Without this change, on the pull request it depends on, test/poly_own_freeze.rb prints 5 of its 47 lines wrong and test/poly_own_freeze_or_nil.rb 2 of 8. No corpus program's generated C changes; optcarrot's is unchanged. A program with no `freeze` or `frozen?` of its own emits the C it did.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (the pull request "super in a freeze or frozen? override is Object's")
