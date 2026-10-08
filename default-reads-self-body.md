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

The default ran on the caller's self. From another class's method, or from the top level where there is no self, the C does not build: `"abc".note`, `:abc.note`, `(1..3).note`, `2.5.note`, `Time.at(5).note`.

Cost: a call that gives every default reading self, and a call on `self` itself, keep their C. A call that leaves one out on another receiver holds the receiver in a temp. That call was wrong or did not build, but for two kinds master ran right. Where the receiver is the caller itself by another expression (`idn.m` in a String method, beside `def idn = self`) the temp's root is 1 instruction a call for a String, with gcc and with clang, and 0 for a Symbol or a Float. Where the default reads self only as `self.class` the temp is not rooted: 0.

"A builtin method's default that reads an ivar runs on its receiver" lets such a default read a held receiver (`g_arm_self`), in the arms for Random, Array, Hash and a call with a block. The site at the top of `emit_call_body` that takes a String, Symbol, Float, Range or Time receiver without a block still wrote the default where the call stands. That site now holds the receiver for it, in the statement expression "A method added to a builtin runs its receiver before its arguments" opens where the call stands: what the statement runs before the call still runs before the receiver (`"#{side}#{lg.note}"` runs `side` first). It does so where the method is the receiver class's own, a def in the class or in a module it includes, the call leaves out a default that reads self (a positional it does not reach, a keyword it does not write), and the receiver is not `self`. The temp is rooted where such a default reads the value; `self.class` reads only its type. The site takes `self` in a method added to Integer too, so `def me = note` beside `def note(k = self + 1)` builds now.

A held String, Symbol, Integer, Float, Range or Time is the value itself, so `self.class` in such a default is answered from its type; handed to `sp_poly_class_val` it did not build.

Not in this change, each as on master: such a default in a method added to Object or Kernel (the C does not build), to Class (`String.m` against `def m(k = self)` prints `c Class__reopen`), or to Integer and called from outside the class (`4.note` prints `n main`); through a boxed receiver it is the ground of "A default left out of a call on a boxed receiver runs in its own arm". A nil behind `&.` still reaches the method, as `p ns&.m` against `def m(k = "d")` prints `"n d"` on master: against `def m(k = self)` the call builds now and prints `"n "`, against `def m(k = self + "!")` it raises NoMethodError. A default that calls a builtin method of the receiver with no `self.` (`def note(k = upcase)`) raises NameError from another class on master; a program that holds one beside `def tag(k = self)` did not build, and raises that now.

Depends on "A method added to a builtin runs its receiver before its arguments", which brings the statement expression: without it this test does not build.

`test/reopen_default_reads_receiver.rb` prints 45 lines and joins `GC_STRESS_TESTS`; master's C does not build on it.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
