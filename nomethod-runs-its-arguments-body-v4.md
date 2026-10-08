<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def tick(n) = (puts "tick #{n}"; n)
def boom = raise(IOError, "io")
xs = [1]
begin
  5.zork(tick(1), *xs)                      # "tick 1" is not printed
rescue NoMethodError
  puts "no zork"
end
p (nil.zork(k: tick(2)) rescue "no zork")   # nor "tick 2"
r = ARGV.size > 5 ? "s" : 5
p (r.zork(*boom) rescue $!.class)           # NoMethodError, CRuby: IOError
```

A call that no method answers evaluates its arguments before it raises NoMethodError. On a boxed receiver it does: the dispatch binds the call's arguments ahead of the raise. A receiver of one known class (an Integer, a String, a Symbol, an Array, an object, nil) raised without running them when one was a splat, a keyword argument, a double splat or a String key: their side effects were lost. And an argument the binding leaves to the call, a splat of a method that always raises, lost its own error to the NoMethodError on a boxed receiver too.

`emit_unresolved_call` stages a call's arguments into the error only when all are plain ("a splat/block/kwarg shape keeps the plain message"), and the arguments of any other call were not emitted at all. They are now emitted for their effect, after the receiver and in CRuby's order: each argument, a splat's and a double splat's operand, a keyword's value, then the block argument's expression. What an argument hoists ahead of its statement (the loop of a call with a block, the calls inside an Array or Hash literal, an `if` used as a value) is written where the argument itself goes, so it too runs after the receiver and after the arguments before it.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,5 +1,3 @@
-tick 1
 no zork
-tick 2
 "no zork"
-IOError
+NoMethodError
```

An argument with nothing to run, a literal or a read of a variable, is not emitted, and one a dispatch already holds in a temporary is not run a second time: a call whose arguments are all such compiles to the C it did, as does a call with plain arguments and every call that is answered. So it costs nothing where a call is answered: of the 6,505 programs of the corpus the generated C of one changes, the new test (`tools/cident.sh`). Test: `test/nomethod_runs_its_arguments.rb`.

Not here: `NoMethodError#args` of such a call is nil where CRuby lists the arguments, as before (`e.args` after `5.zork(a: tick(1), b: tick(2))`), and a block argument that is a call's only argument (`5.zork(&mk)`) is still not run.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
