<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

An object with no `to_a`, splatted into one of the program's methods, arrived wrapped in an Array.

```ruby
class Foo
  def initialize(n) = @n = n
  def n = @n
end
def cls(a) = a.class
def num(a) = a.n
x = Foo.new(1)
p cls(*x)
p num(*x)
```

Spinel prints `Array` and then raises NoMethodError (undefined method 'n' for an instance of Array). CRuby prints `Foo` and `1`.

A splat handed to a method of the program is spread in place where its operand is boxed, a scalar or an Array. An object of one of the program's classes was none of those, and the one-element array `sp_splat_to_array` wraps it in was passed as the argument. Such an object is now spread in place too, where it certainly has no `to_a`: none by a method, a reader or an Enumerable's `each` in its class, above it or in any class below it, no `method_missing` there, no Struct, Data or native class above it, and none at the top level, in a module included there or in a reopened Object, Kernel or BasicObject.

Checked on master dafa0d047:

- `test/splat_object_into_method.rb` fails on master and passes here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`, with gcc and clang.
- 1,092 generated programs (39 kinds of operand into 28 forms of call), each against CRuby: 220 go from wrong to right, and the other 872 compile to the same C as on master.
- Generated C across `test/`, `benchmark/` and `packages/*/test/`: 6,281 of 6,282 programs are byte-identical; the one that differs is the new test.

Left alone, with the same C as on master:

- An object whose class, a class above it or a class below it has a `to_a` or a `method_missing`.
- Every object of a program with a `to_a` at the top level, in a module included there or in a reopened Object or Kernel. Master does not ask that `to_a` and hands over the wrapped object; that is wrong before and after.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A splatted value is rooted while its one-element array is allocated": the test's `one(*Foo.new(2))` hands `sp_splat_to_array` a call's fresh answer; its commit sits beneath this one with the same SHA)
