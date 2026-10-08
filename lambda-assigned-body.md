<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Cost: where the parameter is rooted, 6 to 7 instructions a call. One group that master ran right pays 4: a parameter assigned from an iterator whose answer a temp already holds (`a = a.map { ... }`, and `select`, `reject`, `sort`, `sort_by`, `uniq`, `tap`, `each_with_object`, `Array.new` and `gsub` with a block). The node table does not say which iterators hold their answer; `filter_map`, `flat_map`, `take_while`, `min_by` and a method of the program's own with a block do not, and abort on master. Every lambda that only reads its parameter, and every block form, compiles to the C it did.

```ruby
B = ->(a) { a = a.to_s * 2; b = [1, 2]; [a, b] }
B.call("s")
keep = []
n = 0
while n < 2000
  keep << B.call(n)
  n += 1
end
bad = 0
keep.each_with_index { |v, i| bad += 1 unless v[0] == i.to_s * 2 }
p bad    # CRuby: 0; master: 2
```

`spinel diff` on master: output-diff, `2` for `0`; on this branch: same.

That is a plain run, with gcc and with clang. Under `SPINEL_GC_STRESS=2` a single call aborts ("the mark reached a freed slot").

A proc reads its parameters out of the call's slots and clears the slots. An optional and a keyword are rooted where they bind, and a block's parameter the body assigns (`lambda { |a| ... }`, `proc`, `Proc.new`) is copied into a rooted local. A stabby lambda's required parameter is neither, and neither is the post of any proc (`lambda { |*x, a| ... }`): once the body assigns one a new value, nothing holds that value, and the body's next allocation can collect it. A typed parameter (a String, an Array, a Hash, an object) is lost the same way as a boxed one.

The parameter is rooted where it binds, only where the body assigns it a value nothing else holds and something can allocate after that (`proc_param_wants_root`):

- a read, a scalar and a literal with elements (its temp holds it) need no root;
- neither does an assignment that is one of the body's own statements with only reads after it: `->(a) { a = a.to_s * 2; a }` is written as it was (rooted, it cost 30 instructions a call: it has no GC frame);
- `+=`, `||=` and a multiple-assignment target count as an assignment of a new value; a parameter kept in a cell is held by the cell.

`emit_proc_literal_here` keeps its length: the three bindings end their line through one helper.

Measured against CRuby on 206 programs, each run plain and under `SPINEL_GC_STRESS=2` with gcc and with clang (a stabby lambda with one parameter, with two and with a post, called by `call`, `.()` and `[]`; `lambda`, `proc`, `Proc.new` and a block handed on, with a required parameter and with a post; a parameter assigned a String, an Array, a Hash, an object, by `=`, `+=`, `||=`, a multiple assignment, under a condition, in a loop, from a literal, a read, an interpolation, an iterator; boxed and typed):

- 83 are wrong on master and right here: 77 abort under stress, 6 print a wrong answer under stress (an empty Hash literal, an object).
- 100 keep master's C byte for byte: the 52 block forms, the 5 lambdas that only read, and 43 assignments of a literal with elements, a read, a scalar or a String literal.
- 13 are right on both and pay the one root: the iterators of the first paragraph.
- 10 are under "Not in this change". None is lost.
- `make cident`: one program of the corpus changes C beside the new test, `test/proc_parameters_reassigned_name.rb`: its `lambda { |k, m = 2, *r, z| k = k + 1; z = z + m; k + z }` assigns a boxed post from a call on a box and gets the root; it prints its `.expected` before and after, plain and under stress. optcarrot's C is the same.
- callgrind, a million calls: `->(a) { a = a.to_s * 2; b = [1, 2]; [a, b] }` 972,779,563 to 980,220,084; the typed String `a = a * 2` 820,540,775 to 826,754,735; `a = a.map { |e| e + 1 }` 898,978,001 to 903,094,215. `->(a) { a = a.to_s * 2; a }`, `->(a) { a = [1, 2]; ... }` and `->(a) { b = [1, 2]; [a, b] }`: the same C.

Not in this change, each the same on master:

- `a = a.to_s.to_sym` prints a wrong Symbol under stress (3): the Symbol is no pointer, so no root is owed; the String it is made from is the value freed.
- `Proc.new { |*x, a| ... }` called with two arguments segfaults in a plain run (1), with or without an assignment in the body.
- Six of the iterator programs do not build on either tree (`inject` with an Array seed, `group_by { }.values`, `partition`, `zip(a).map`, `each_with_index.map`, `dup.tap` on a String).
- A Range, a Rational, a Complex or a Time handed to a lambda's boxed parameter aborts under stress with no assignment at all: the box the call makes is the value freed, at the call and not in the body.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
