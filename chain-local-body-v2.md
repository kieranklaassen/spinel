<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Before:

```ruby
module Doubled
  def total(a)
    twice = a * 2
    twice + super(a)
  end
end
class Plain
  prepend Doubled
  def total(a)
    a + 100
  end
end
p Plain.new.total(3)    # does not build: 'lv_twice' undeclared; CRuby prints 109
```

After: `109`.

A local written in a method of a prepended module had no slot, with a `super` in the method or without one, and the C did not build. Where the local's type was needed first, the program was refused instead: "unsupported comparison" for a loop counter, "unsupported operator assignment" for `t += q`.

How: `process_prepend_body` copies the module's method in front of the class after `register_locals` has run. It carries the parameters across by hand, but the locals the cloned body writes were never interned. The include and extend clones call `register_locals` again for this, and `register_prepends` now does too when it made a copy. Such a program built before only where a later pass interned them by the way: a method cloned in its proc form, or a class method specialised for a subclass.

Measured on master fa08b100 with gcc 13 against CRuby 3.3.6: 377 programs with a local in a prepended method (13 kinds of local, 8 class shapes, with and without `super`), of which 290 did not build and 87 were refused, all print CRuby's lines now. No program that builds on master gets other C: of 9,804 more prepend programs the C of 395 changes, none of which built; 297 are right now and 24 still do not build.

The other 74 now build and reach a fault master has without the local. Each prints, or raises, exactly what master does today for the same program with the local written away (`[super(), :m]` for `v = super(); [v, :m]`):

- 21: a module named twice in `prepend` runs once too often. With `def go; [super(), :m]; end` in M, `class A; prepend M; prepend M; def go; [3, 6]; end; end; class B < A; prepend M; end; p B.new.go` prints `[[[[3, 6], :m], :m], :m]` on master; CRuby prints `[[[3, 6], :m], :m]`. The pull request that follows this one, "A super past a prepend reaches the parent's prepended method", cures it.
- 27: `prepend A, B` puts B in front. With `def r; [:a] + super; end` in A and the like in B, `class K; prepend A, B; def r; [:k]; end; end; p K.new.r` prints `[:b, :a, :k]` on master; CRuby prints `[:a, :b, :k]`. Its cure is the pull request for the order of `prepend`'s arguments, which follows.
- 1: `prepend M` written inside a module does nothing, on master and here. With `module K; prepend M; end` included in a class whose superclass answers `[3, 6]`, `go` prints `[3, 6]` for `[[3, 6], :m]`.
- 25: a `super` or a call that CRuby answers through `method_missing` raises NoMethodError by name ("super: no superclass method 'go'", "undefined method 'nothing'"), which is master's own raise for the twin.

clang 18 gives the same on a sample of 142.

Generated C against master fa08b100 (`make cident`): 6,111 programs identical, none differ, and one refusal change: the new test, which master refuses. optcarrot's C is identical. On 9c4eec71 the commit picks without conflict; the test does not build there and passes with it.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
