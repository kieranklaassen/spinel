<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A call that no method answers evaluates its arguments before it raises NoMethodError. On a receiver of one known class, a call with a splat, a keyword argument, a double splat or a String key raised without running them. They now run where every argument is of a listed shape; every other call compiles to the C it did. What it costs: a raising call takes about 2,100 instructions, and one whose receiver has to be held ahead of its arguments takes 4 to 6 more with gcc and 2 to 8 more with clang (callgrind, 200,000 calls), besides what the arguments themselves now do; the compiler takes 7.0% more instructions on a file of 300 such calls and nothing else, and 0.2% to 0.3% more on 300 calls whose C does not change.

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

On a boxed receiver the dispatch binds the call's arguments ahead of the raise, so they ran already; an argument the binding leaves to the call, such as a splat of a method that always raises, lost its own error to the NoMethodError there too. `emit_unresolved_call` stages a call's arguments into the error only when all are plain ("a splat/block/kwarg shape keeps the plain message"), and the arguments of any other call were not emitted at all. They are now emitted for their effect, after the receiver and in CRuby's order.

**The list.** An argument that was never emitted may be one the compiler refuses, or compiles to something that does not answer as CRuby does, and a program that never reached it was right: `5.zork(k: (U = 7))` builds and raises NoMethodError, and goes on doing so. The same holds for a method that only such an argument calls. So the arguments run only where each of them is:

- a literal, a read of a variable, or an Array or Hash literal of those (nothing to run);
- a plain write of a local, an instance variable or a global of the program's own (`k: (x = 4)`), from a variable, a literal or a listed call;
- a call, written in top-level code, that is sure to reach a top-level method which is sure to do what CRuby does. It has no receiver and no block; inference binds it to the one method of that name; the method is defined by a top-level statement above the call in the same file, takes exactly that many plain parameters, does not yield, and is named by no builtin and by no Symbol or String in the program; it is given variables, literals or such calls. And the method's body does nothing but read variables and literals, write a local or a global of the program's own, print a text or an Integer that cannot be nil (`puts`, `print`, `p`), raise a builtin error with such a text, and call methods that are listed themselves;

inside parentheses, an Array or Hash literal, a splat, a keyword argument or the block argument. Only the calls and writes are emitted: the Array, the Hash or the splat around them is not built, and what a dispatch has already run into a temporary is not run again.

A call written in a method or a class body is not listed (self may be an object with a method of that name of its own), nor is one in a program that evaluates a block as another object's (`instance_eval` and its kin, `define_method`, a `Class.new` body), extends an object, has a `BEGIN` block or names `BasicObject`. A body that prints or raises is not listed in a program that defines a method named `puts`, `print`, `p`, `raise`, `exception`, `write`, `to_s` or `inspect`, has a Symbol of one of those names, aliases a global, or names `$stdout`, `$>`, `STDOUT` or an output separator.

**The receiver.** The error is staged after the arguments, and a receiver read from a variable is the object the variable held before they ran: `t = 5; t.zork(k: (t = 7))` raises for 5. Where an argument can rebind what the receiver reads, the receiver is boxed into a rooted temp ahead of the arguments, with its nil test, as a boxed receiver already is; where none can, it is read as it was. `read_rebound_by` answers that for a variable and for the variables an Array or Hash literal reads; it does not answer for a constant, so one is held wherever an argument calls a method.

**Cost, by the row** (instructions a rescued raising call, bare master against this, gcc and clang):

| receiver and argument | gcc | clang |
|---|---|---|
| a local or a literal, `k: tk` (a method that returns 0) | +0.00 | +0.00 |
| any receiver, `k: (x = 4)` (the write itself) | +2.00 | +2.00 |
| a local the argument assigns, `t.zork(k: (t = 5))` | +6.03 | +4.02 |
| an instance variable, `@n.zork(k: tk)` | +5.02 | +2.02 |
| an instance variable the argument assigns | +6.03 | +8.02 |
| a global or a constant, `k: tk` | +4.02 | +2.02 |
| a String in an instance variable, `k: tk` | +6.03 | +2.03 |
| a boxed receiver, an Array literal of variables | +0.00 | +0.00 |

A raising call takes 2,114 instructions with gcc and 2,078 with clang. A call that is answered, a call with plain arguments and a call whose arguments have nothing to run compile to the C they did. Of the corpus's 6,610 programs the generated C of one changes (`tools/cident.sh`), the new test; optcarrot's does not. Compiling a file of 300 such calls and nothing else takes 609,533,119 instructions on master and 652,343,838 with this (+7.0%): the arguments are emitted, and each held receiver is one more rooted temp for the frame pass. 300 calls with arguments outside the list take +0.3% and 300 with nothing to run +0.2%, for the same C.

Test: `test/nomethod_runs_its_arguments.rb`.

Not here:

- `NoMethodError#args` of a call with a splat or a keyword argument is nil where CRuby lists the arguments, as before, and a block argument that is a call's only argument (`5.zork(&mk)`) is still not run;
- an argument of a shape outside the list is not run, as before: a call with a receiver (`@s.zork(k: (@s << "x"))`, `k: xs.size`), any call written in a method or a class body, an operator, a constant write, a multiple assignment, and a call of a method that does more than the list allows (one that calls a proc, builds an Array, adds two numbers, prints a String it was given).

Nor here, as on master:

- a call with plain arguments reads its receiver in the C call that boxes them, so `t.zork(t = 7)` raises for 7 with gcc and for 5 with clang;
- a String that may be nil binds a keyword argument, a splat or a plain argument ahead of its nil test: `t.zork(k: (t = "cd"))` on a nil `t` raises for "cd", and `t.zork(k: (t = nil))` on a String raises for nil.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on master `84f5b5020ef8`, gcc and clang: the new test at `SPINEL_GC_STRESS` unset, 1 and 2 (also with `--share-strings`); `tools/gate.rb check` with the commit staged; `tools/cident.sh` against master (one program differs, the new test); `make share-strings-test` and `make int-min-test`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: nothing
