<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`full_message(highlight: false)` and `detailed_message(highlight: false)`
raised NoMethodError on a value typed as the program's exception class
(`MyErr.new`, `rescue MyErr => e`) and on any exception kept as a boxed
value, a builtin one too.

```ruby
class MyErr < StandardError; end
e = MyErr.new("q")
p e.detailed_message(highlight: false)
# Spinel: undefined method 'detailed_message' for an instance of MyErr (NoMethodError)
# CRuby:  "q (MyErr)"
```

The bare calls answer on all of those values, and so does
`rescue => e; e.full_message(highlight: false)`: the arms for the typed and
the boxed receiver took the call only with no argument. They take it now
with the keywords that ask for what the bare call gives, written as
literals: `highlight: false` or nil, `order: :top` or nil. The renderings
have no terminal to colour for and no backtrace to order, so the call emits
the bare call's C.

Any other keyword or value is left as it was (NoMethodError): `highlight:
true` and `order: :bottom` ask for another text, a variable can hold
either, and CRuby raises ArgumentError for `highlight: 3`.

`full_message`'s text stays Spinel's own (`MyErr: q`, with no file and
line, as `test/exception_object_methods.rb` has it for the bare call). A
program that prints `e.full_message(highlight: false)` prints that line now
where it raised, the same line the bare call prints on master. Of 1,492
one-case programs 67 do so: each differs from CRuby by that line alone and
prints what its twin, the same program with the bare call, prints on
master. The difference is reached, not made.

Test: `test/exception_rendering_keywords.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
