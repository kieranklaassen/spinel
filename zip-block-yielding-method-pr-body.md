<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

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

The same where the method takes `&blk` and calls it, where the yield comes after the loop, and in a class's own `each`; with one block parameter for the pair, `_1` and `_2`, or `it`; and for `permutation`. The same call at the top level, or in a method that does not yield, is right on master.

A method that yields is spliced into its caller with its locals renamed (`rename_local`), and each is still declared in its scope under the name it was written with. `iter_ewi_zip_poly_arms` (`src/codegen_iter.c`) asked the scope for the block's parameters by the new name, found neither, and emitted the loop with no binding at all. `iter_combination_cons_arms` and `emit_poly_combination_param` asked the same way for the parameter's type, took the miss for a boxed value and wrote one into an Integer Array's slot.

The four lookups now go through one function, `block_param_local`, which asks by the name as written when the new one is not found. Where the first lookup finds the local the C is what it was.

Of 3,348 generated programs, 1,024 that were silently wrong are right and 260 that did not build are right. 1,782 are right before and after, and none that is right on master is wrong, refused or not building. They are 47 iterators with a block over Integers, Strings, Floats and mixed values, in four method shapes and two controls (1,128), and then 37 ways to write a `zip`, a `combination` or a `permutation` block (a shadowed local, a `next`, a `break`, a zip inside a zip, a literal or a shorter argument) and their neighbours, over six pairs of element kinds, in eight method shapes and two controls (2,220). With `--share-strings` the counts are the same, but for 8 of the right ones, which the flag refuses before and after. The 60 with `it` are judged against CRuby's answer for the one-parameter block, CRuby 3.3.6 having no `it`.

Not here, each as on master, in a method and at the top level alike: `combination` and its family on a String Array raise NoMethodError at run time (234 of the programs), and `chunk_while` and `slice_when` written as a statement run their block at once (48).

The test is `test/zip_block_in_yielding_method.rb` (29 lines printed; master does not build it, and section by section 17 of the lines are wrong or raise and the other 12 are in the three sections that do not build). `tools/cident.sh` against master 7bdde552 answers `6400 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`, the one being the new test. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; not yet run under Ruby 4.0)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the test)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
