<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`:a.equal?(3)` raised NoMethodError where CRuby answers false.

```ruby
s = :a
p s.equal?(3)
x = [3, :a][1]
p s.eql?(x)
```

Master (42557a3c) stops at the first line: `undefined method 'equal?' for an instance of Symbol (NoMethodError)`. CRuby prints `false`, `true`.

The Symbol rows of the builtin table (`src/builtin_ops.c`) had none for `equal?` or `eql?`. The one arm was the compare of two Symbols by type, their ids. With any other argument (an Integer, a String, nil, an object, and a boxed value even where it holds the same Symbol) a program that defines neither name found no row, and the call was compiled as the raise. An Integer, a Float and a boolean receiver each answer the rest. Two rows now ask the boxed pair's identity, `sp_poly_equal`, for both names: a Symbol is itself alone. A Symbol slot that holds nil is boxed as nil there and equals nil. Two Symbols by type keep the compare they had.

`symbol_identity_builtin` says which calls the rows answer. Every other call keeps master's C.

Left alone:

- a program that defines `equal?` or `eql?` above a Symbol: on Symbol, Object, BasicObject or NilClass, or in a module (Kernel, Comparable, one it includes). CRuby calls that method, and master calls it where it finds it;
- a program that names either in an `undef`, a `private`, an alias or a `define_method`;
- a call with a splat, keywords or a block argument (`s.equal?(*a)`, `s.equal?(k: 1)`, `s.equal?(3, &b)`): CRuby has its own errors and its own order for these;
- an argument that is more than reads, calls that take no block, and number, String, Symbol, nil and boolean literals: an `if`, a `begin`, a block, a Range or Regexp literal, a literal Array or Hash that holds a call (`f.equal?([g])`). Master evaluates some of these ahead of the receiver;
- a boxed receiver: its call was right already.

Not here: `:"é"` and `"\xC3\xA9".b.to_sym` are one Symbol on master, so `equal?` of the two answers `true`, typed or boxed.

The corpus C changes for the new test alone.

Cost: a million calls in a loop over an Integer, a Symbol, a String and nil cost 18 instructions a turn under callgrind, either name; the same loop with an Integer receiver costs 22 on master and here. A file of 300 such calls builds in 1.3 s of CPU where master's 300 raises build in 0.8.

Tests: `test/symbol_equal_other_kind.rb` (its `.expected` is 41 lines; master raises on the first call) and `test/symbol_equal_program_method.rb` (6 lines, a program with an `equal?` and an `eql?` of its own; master prints them right and so does this).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
