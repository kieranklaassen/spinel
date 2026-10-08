<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
g = { "lo" => "b", "hi" => "d", "n" => 1 }
p "a".clamp(g["lo"], g["hi"])
```

does not build (`spinel diff`: link-error, incompatible types when initializing type `const char *` using type `sp_RbVal`). CRuby prints `"b"`.

The String arm of `clamp` emits each bound as a C string, and a boxed bound is a boxed value.

Now a `String#clamp` with a boxed bound is typed boxed and answered by `sp_poly_clamp`, the clamp a boxed receiver already takes: nil is an open side, an Integer bound raises CRuby's comparison error, and the answer is the receiver or the bound itself. A String the program appends to is held in its box as a shared handle, and when it wins the answer is that handle:

```ruby
h = { "k" => +"b", "n" => 1 }
h["k"] << "b"
x = "a".clamp(h["k"], g["hi"])
p x.equal?(h["k"])   # true
x << "!"
p h["k"]             # "bb!"
```

An operand that is a local or an instance variable whose String the program mutates in place becomes the shared handle too, as one stored into an Array literal does (`promote_shared_stored_strings`), and is boxed as that handle, so an append through the answer reaches the variable. The three operands fill rooted temporaries in Ruby's order, receiver, low bound, high bound: C leaves the order of a call's arguments open, and gcc runs them last to first.

Cost: no program that builds on master changes: no corpus program's generated C changes but the new test's, which does not build on master (`tools/cident.sh`). A clamp with two typed bounds emits the C it did and costs what it did: 125 instructions a call with gcc and 187 with clang when the receiver wins, on master and on this branch. A clamp with boxed bounds, which did not build, costs 524 / 518 (gcc / clang) when the receiver wins, 369 / 359 when the low bound wins, 525 / 516 when the high bound wins and 619 / 519 when an appended bound wins; master's clamp on a boxed receiver, with the same bounds, costs 508 / 492, 350 / 337, 509 / 489 and 605 / 497.

Not changed: `s.clamp(g["lo"]..g["hi"])`, a Range of boxed ends, still does not build, nor does `s.clamp(nil, g["hi"])`, a nil written beside a boxed bound. A program that defines a `clamp` of its own emits the C it did. `:c.clamp(g["lo"], g["hi"])` still raises NoMethodError.

Three answers are not CRuby's, and each is what master prints for the same values by another route. A mutable String that the program never mutates by its own name, when it wins and is then appended to through the answer, keeps its text: `u = +"c"; x = u.clamp(g["lo"], g["hi"]); x << "!"; p u` prints `"c"` where CRuby prints `"c!"`, as master prints with two typed bounds and with a boxed receiver. A Bignum as the high bound answers the receiver or the low bound where CRuby raises ArgumentError, as master's clamp on a boxed receiver does. A method parameter the method appends to, when it wins and is appended to through the answer, keeps its text, as it does on master when the receiver is boxed. Three more shapes are loud and not CRuby's, each as master's clamp on a boxed receiver is: a Bignum as the low bound raises ArgumentError with the min and max message in place of the comparison one, and a high bound that is an object with `to_str`, or either bound that is one with `to_str` and its own `<=>`, raises ArgumentError where CRuby asks the object.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
