<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
$g = +"abcdef"
r = ($g[0] = "x")          # CRuby "x"; here NoMethodError, undefined method '[]=' for an instance of String
def last = ($g[1, 2] = "yy")   # the same as a method's last expression, as an argument,
NAME = +"abc"                  # and on a class variable or a constant
r = (NAME[-1] = "z")
```

As a statement each of these stored. The value arm in `emit_call_operator_arms` takes a local and an ivar by node type; a global, a class variable and a constant went on to the NoMethodError gate.

The arm now takes those three where it can prove its answer:

- the right-hand side is a String that cannot be nil: a literal, an interpolation, or `+`, `*`, `to_s` or `dup` on a String or a number;
- every index is a literal, or a local variable beside a value that runs no code.

The statement runs and the expression answers the right-hand side, evaluated once, as it does for a local. A global can hold nil where its type is String: whether it does is read ahead of the value, and NoMethodError, "undefined method '[]=' for nil", is raised after the value ran, as the gate raised it.

Every other shape keeps the gate and its NoMethodError, with the same C as before: a value out of a variable or a method (it may be nil, and the statement takes a nil value for an empty String), an Integer value, an index that runs code, a local index beside a value that runs code.

The generated C changes in the new test and nowhere else: no existing test, no benchmark and not optcarrot.

Under `SPINEL_GC_STRESS=2` the Integer index stops with "the mark reached a freed heap string" on a global as it does on a local, as a statement and with its value taken, before this change and after it. That is the Integer arm's own rooting fault, which #NNNN closes; the test here is right at levels 0 and 1 by itself, and at level 2 above #NNNN.

Left as it is: a second name for the global's String does not see the store, with the value taken as with the statement. `$g = +"abc"; t = $g; t << ""; r = ($g[0] = "x"); p r, $g, t` prints "x", "xbc" and "abc" where CRuby prints "xbc" for `t`; it raised NoMethodError before. The statement `$g[0] = "x"; p $g, t` prints "xbc" and "abc" before this change and after it.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
