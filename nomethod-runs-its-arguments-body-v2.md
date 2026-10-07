<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def tick(n) = (puts "tick #{n}"; n)
xs = [1]
r = ARGV.size > 5 ? "s" : 5
begin
  r.zork(tick(1), *xs)                      # "tick 1" is not printed
rescue NoMethodError
  puts "no zork"
end
p (5.zork(k: tick(2)) rescue "no zork")     # nor "tick 2"
```

A call that no method answers raised NoMethodError without evaluating its arguments when one of them was a splat or a keyword argument: their side effects were lost, and an argument that raises lost its own error to the NoMethodError. `emit_unresolved_call` stages a call's arguments into the error only when all are plain ("a splat/block/kwarg shape keeps the plain message"), and the arguments of any other call were not emitted at all. They are now emitted for their effect, after the receiver and in CRuby's order: each argument, a splat's and a double splat's operand, a keyword's value, then the block argument's expression.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,4 +1,2 @@
-tick 1
 no zork
-tick 2
 "no zork"
```

An argument with nothing to run, a literal or a read of a variable, is not emitted: a call whose arguments are all such compiles to the C it did, as does a call with plain arguments and every call that is answered. So it costs nothing where a call is answered: of the 6,352 programs of the corpus the generated C of one changes, the new test (`tools/cident.sh`). Test: `test/nomethod_runs_its_arguments.rb`.

Not here: `NoMethodError#args` of such a call is nil where CRuby lists the arguments, as before.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
