<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def each_pair_of(a, b)
  a.zip(b) { |x, y| yield x, y }
end
each_pair_of([1, 2], ["a", "b"]) { |n, s| p [n, s] }
# CRuby: [1, "a"] and [2, "b"]. master: [nil, nil] twice

def pairs(a)
  a.combination(2) { |x, y| yield x + y }
end
pairs([3, 4, 5]) { |s| p s }
# CRuby: 7, 8, 9. master does not build
```

The same where the method takes `&blk` and calls it, where the yield comes after the loop, and in a class's own `each`; with one block parameter for the pair, `_1` and `_2`, or `it`; and for `permutation`. Where the block reads its parameters (`r << x + y`) the nil raised NoMethodError. The same call at the top level, or in a method that takes no block, is right on master.

A method that yields or asks `block_given?` is spliced into its caller with its locals renamed (`rename_local`), and so are the locals of a parameter's default, which runs at the call. Each is still declared in its scope under the name it was written with. `iter_ewi_zip_poly_arms` (`src/codegen_iter.c`) asked the scope for the block's parameters by the new name, found neither, and emitted the loop with no binding at all. `iter_combination_cons_arms` and `emit_poly_combination_param` asked the same way for the parameter's type, took the miss for a boxed value and wrote one into an Integer Array's slot.

The five lookups now go through one function, `block_param_local`, which asks by the name as written when the new one is not found. Where the first lookup finds the local the C is what it was. So the method that only asks `block_given?` and the default are right too:

```ruby
def sums_or_size(a, b)
  r = []
  a.zip(b) { |x, y| r << x + y }
  block_given? ? r.size : r
end
p sums_or_size([1, 2], [3, 4])   # [4, 6]; master: undefined method '+' for nil

def dot(a, b, c = (s = 0; a.zip(b) { |x, y| s += x * y }; s)) = c
p dot([1, 2], [3, 4])            # 11; master: undefined method '*' for nil
```

Of 3,348 generated programs, run on master 759d120f, 1,024 that printed wrong lines are right and 260 that did not build are right. 1,782 are right before and after, and none that is right on master is wrong, refused or not building. 48 of those 1,782 are a block that reads neither parameter: it now binds them, and the binding is dead code (`a.zip(b) { |x, y| n += 1 }` in such a method over 200,000 pairs, ten times: 3,668,241 instructions before and 3,668,255 after). The programs are 47 iterators with a block over Integers, Strings, Floats and mixed values, in four method shapes and two controls (1,128), and then 37 ways to write a `zip`, a `combination` or a `permutation` block (a shadowed local, a `next`, a `break`, a zip inside a zip, a literal or a shorter argument) and their neighbours, over six pairs of element kinds, in eight method shapes and two controls (2,220). With `--share-strings` the counts are the same, but for 8 of the right ones, which the flag refuses before and after. The 60 with `it` are judged against CRuby's answer for the one-parameter block, CRuby 3.3.6 having no `it`.

Handed its elements, the block now meets what a `zip` or `combination` block meets at the top level. Each of these went from a raise, or from no build, to the line master prints for the same block outside such a method:

- `x << "!"` in the block changes a copy of a String element: `def m(a); a.zip([1]) { |x, y| x << "!" }; yield a; end` with `m(["p".dup]) { |r| p r }` raised NoMethodError and prints `["p"]` for `["p!"]`, as `a.zip([1]) { |x, y| x << "!" }; p a` does at the top level. `c[0] << "!"` in a `combination(2) { |c| ... }` block did not build and prints `["p", 1]` for `["p!", 1]`, as it does at the top level.
- A method called with an Integer and then a Float second array reads the Float's bits: `def m(a, b); n = 0; a.zip(b) { |x, y| n += y; yield y }; end` with `m([1], [10])` and `m([3], [4.5])` raised TypeError and prints 10 and 4616752568008179712, as the method does on master with `p y` for the `yield y`.
- A block that yields the pair and then an element, in a method called with two kinds of array (`a.zip(b) { |x, y| yield([x, y]); yield(x) }` with `m([1], [10])` and `m(["p"], ["a"])`), printed `[nil, nil]` and `nil` and now prints `[1, 10]` and then crashes, as it does on master when the two yields are calls of `def show(v) = p(v)`. With one kind of array it is right.

Not here, each as on master, in a method and at the top level alike: `combination` and its family on a String Array raise NoMethodError at run time (234 of the programs); `chunk_while` and `slice_when` written as a statement run their block at once (48 of them); and `def m(a, b, &blk) = a.zip(b, &blk)` hands the block nil for both.

The test is `test/zip_block_in_yielding_method.rb` (32 lines printed; master does not build it, and section by section 9 of the lines are wrong, 11 are in the five sections that raise NoMethodError and 12 in the three that do not build). `tools/cident.sh` against master 759d120f answers `6428 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`, the one being the new test. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; not yet run under Ruby 4.0)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the test)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
