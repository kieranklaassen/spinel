<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Pair
  attr_reader :left, :right
  def initialize(n)
    @left = n
    r = n
    r = "s" if n > 1000
    @right = r ? 1 : 2
  end
end
class Twin < Pair
  def tag = :twin
end
twin = Twin.new(7)
p twin.right   # nil; CRuby prints 1
```

That is the default build, `-O2`, with gcc 13.3 and with clang 18.1 on x86-64 Linux; `-O1` and `-fno-strict-aliasing` print 1. With gcc a `super` into the parent's `initialize` gives nil the same way, and a Struct's subclass prints a member's value from before an inherited method set it.

An inherited method is called with `(sp_Pair *)self`. `sp_Pair` and `sp_Twin` share a layout and are unrelated struct types to the C compiler, and by C's aliasing rule a store through one cannot change what is read through the other. With `new`, `initialize` and the reader inlined into one function, the compiler kept the unset value `sp_Twin_new` had put in the field.

The struct of a class with a parent or a child is now defined with `SP_MAY_ALIAS` (`__attribute__((may_alias))`, through `sp_compat.h`), and so is the struct of an exception subclass with instance variables, which is read as an `sp_Exception`. A class alone keeps its struct, and a compiler without the attribute gets the C it got.

The other cure is `-fno-strict-aliasing` on the compile line: one line and no change to the C, but every program's machine code changes. Over the 67 benchmarks it is 10.3% more instructions on `bm_loops_times`, 9.6% on `bm_sieve` and 3.2% on `bm_ao_render` with gcc, and with clang `bm_attr_accessor`, which clang otherwise folds away, runs 780 times as many. The attribute leaves all 67 byte for byte the machine code they were (none has a subclass). I took the attribute; the flag is one line if you prefer it.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (four of its classes have a subclass or a parent: 2,384,959,336 to 2,384,986,299 instructions with gcc, 2,595,015,518 to 2,594,982,765 with clang; checksum 59662)
- [ ] Depends on: #
