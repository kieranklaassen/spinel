<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
$g = +"abcdef"
r = ($g[0] = "x")              # CRuby "x"; here NoMethodError, undefined method '[]=' for an instance of String
def last = ($g[1, 2] = "yy")   # the same as a method's last expression, as an argument,
NAME = +"abc"                  # and on a class variable or a constant
r = (NAME[-1] = "z")
```

As a statement each of these stored. The value arm in `emit_call_operator_arms` takes a local and an ivar by node type; a global, a class variable and a constant went on to the NoMethodError gate. It now takes those three where it can prove its answer: the right-hand side is a String that cannot be nil (a literal, an interpolation, `to_s` on a String or a number, or `dup`, `+` and `*` by an Integer literal over such operands), and every index is a literal, or a local variable beside a value that runs no code. Every other shape keeps the gate, with the same C as before; the generated C changes in the new test and nowhere else.

Left as they are: a value out of a variable keeps the gate, since a String variable can hold nil: `s = "q"; r = ($g[0] = s.dup)` still raises NoMethodError where CRuby answers "q". A second name for the global's String does not see the store, with the value taken as with the statement.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
