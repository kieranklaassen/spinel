<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class String
  def note(k = self + "!") = "n #{k}"
  def ask(s) = s.note
end
puts "x".ask("abc")
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-n abc!
+n x!
```

The default ran on the caller's self. From another class's method, or from the top level where there is no self, the C does not build: `"abc".note`, `:abc.note`, `(1..3).note`, `2.5.note`.

"A builtin method's default that reads an ivar runs on its receiver" holds the receiver in a rooted temp and lets the default read it (`emit_reopen_recv_args`), in the arms for Random, Array, Hash and a call with a block. The site at the top of `emit_call_body` that takes a String, Symbol, Range or Float receiver without a block still wrote the default where the call stands. It now calls `emit_reopen_recv_args` where the method is the receiver class's own, a def in the class or in a module it includes; a method the class only inherits (Object's, Kernel's) is emitted as before. The site takes `self` in a method added to Integer too, so `def me = note` beside `def note(k = self + 1)` builds now. One line changes, and `emit_call_body` keeps its line count.

A held String, Symbol, Float, Range or Time is the value itself, so `self.class` in such a default is answered from its type; handed to `sp_poly_class_val` it did not build.

A default that calls a builtin method of the receiver with no `self.` (`def note(k = upcase)`) still runs on the caller: `Room.new.ask("abc")` prints `n ` on master and here. A program that holds such a line beside `"abc".tag` against `def tag(k = self)` at the top level did not build; it builds now, and prints that line as master prints it without the `tag`.

Cost: none for a call that leaves out no default reading self (`emit_reopen_recv_args` falls through to the ordered form). One that does pays the rooted temp the four arms already pay.

Not in this change: such a default in a method added to Object or Kernel, or to Integer and called on a value from outside the class (`4.note`), still runs on the caller.

Depends on "A method added to a builtin runs its receiver before its arguments", which brings the ordered form this site falls through to.

`test/reopen_default_reads_receiver.rb` prints 20 lines; master's C does not build on it.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
