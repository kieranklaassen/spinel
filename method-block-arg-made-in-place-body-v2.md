<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a stated cost.** In a program that builds Method objects, a boxed value passed with `&` that is not read from a variable (`pos(1, &s(:blk, pr))`, where `s` answers its second argument) pays one frame slot, whether or not it is a Method: 15 instructions a call on the loop measured below. A value read from a variable, and every program with no Method in it, pay nothing. Two cuts were tried. Testing for a Method at run time before holding the value measured worse (26,672,470 instructions against 23,872,457). Keeping the value in a register and holding only a copy of it measured 22,872,457, 10 a call for 15, and was not taken: it is not the form the generated C gives a held temporary anywhere else.

A Method passed as a block where it is made (`&o.method(:val)`) could be called as another Method. A plain run shows it:

```ruby
class K
  def initialize(n) = @n = n
  def val = @n
  def neg = -@n
end
def m1(o)
  x = o.method(:neg)
  yield
end
def f3(o, q) = m1(q, &o.method(:val))
wrong = []
keep = []
i = 0
while i < 1000000
  o = K.new(i)
  v = f3(o, K.new(i + 7)) { 0 }
  wrong << [i, v] if v != i
  keep << o if i % 4 == 0
  i += 1
end
p wrong
```

```
spinel diff: output-diff
  program: block.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[]
+[[231030, -231037], [376567, -376574]]
```

Two calls in a million answer `q.neg` for `o.val`. `&expr` over a boxed value is written as `sp_poly_to_block(<value>)`, and a Method converts by allocating its Proc (`sp_method_to_proc`). One made in the argument list is held by nothing else:

```c
sp_Proc *_t1 = sp_poly_to_block(sp_box_nullable_obj((void *)(/* the Method, made here */), SP_BUILTIN_METHOD)); SP_GC_ROOT(_t1);
```

A collection on the Proc's allocation frees the Method, the Proc keeps the freed one, and the next Method made (`o.method(:neg)` in `m1`) takes its place. Under `SPINEL_GC_STRESS=2` the call raises `undefined method 'call' for an instance of Method (NoMethodError)`.

The conversion is written in two places, `emit_block_arg_proc` and the block an inlined `yield` forwards; both now go through `emit_poly_to_block`. In a program that builds Method objects (`an_program_builds_methods`) it binds a value that is not read from a variable to a rooted temporary across the conversion:

```c
sp_Proc *_t1 = ({ _gcf.v[0] = sp_box_nullable_obj((void *)(/* the Method */), SP_BUILTIN_METHOD); sp_poly_to_block(_gcf.v[0]); });
```

A read of a variable is held where it lives and keeps its C, and so does every program with no Method in it. A Method that reaches `&` out of a call that can also answer nil (`y0(&pick(i))`) is held the same way.

**Measured against CRuby 3.3.6 on master 9274c732.** 144 generated programs: a Method of no parameter and of one, made six ways (`method(:top0)`, `K.new(i).method(:val)`, `o.method(:val)`, `K.new(i).me.method(:val)`, read from a local, read from an Array), handed with `&` to a method that yields, to `map`, `each` and `select`, to a method that keeps its block parameter and to a constructor that keeps it, and converted with `to_proc`, at the top level and inside a method.

| of 144 | master | this branch |
|---|---|---|
| right in a plain run, under `SPINEL_GC_STRESS=1` and under 2 | 96 | 120 |
| `SPINEL_GC_STRESS=2`: raises NoMethodError | 24 | 0 |
| `SPINEL_GC_STRESS=2`: stops | 24 | 24 |

The 24 that stop are the constructor forms (see below), the same on both. None moves from a raise or a stop to a wrong answer.

**Cost.** 200,000 calls each (callgrind, gcc):

| | master | this branch |
|---|---|---|
| `y0(&K.new(i).method(:val))`, the cured call | 65,466,426 | 66,193,408 |
| `m = K.new(i).method(:val); y0(&m)` | 45,268,767 | 45,268,767, the same C |
| `y0 { 40 }` | 1,549,924 | 1,549,924, the same C |
| `pos(1, &s(:blk, pr))`, a boxed Proc out of a call, with a Method elsewhere in the program | 20,872,464 | 23,872,457 |
| the same with no Method in the program | 20,871,955 | 20,871,955, the same C |

The fourth row is the stated cost: the value is boxed, so what it is is known only at run time, and it is not read from a variable, so nothing shows it is held.

**Not here.** `Keep.new(&o.method(:val))`, where `initialize` takes the block: the constructor allocates its object after the conversion, and the call faults under `SPINEL_GC_STRESS=2` on master and here, also when a local holds the Method.

**Generated C.** `make cident REF=9274c732`: `6409 identical, 10 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The ten are the new test and nine tests in the tree that pass a boxed value made in place with `&` in a program with a Method: each gains the held conversion and renumbered temporaries. Six of them fail under `SPINEL_GC_STRESS=2` on master and pass here (`cmethod_yield_method_object_block`, `method_obj_bare_resolves_like_call`, `method_to_proc_keywords`, `string_handle_yield_boxed_nil`, `string_handle_yield_nil`, `yield_proc_arg_in_blocked_method`); `block_arg_poly_value` and `string_handle_yield_exec` fault under 2 on master and here, for another cause; `proc_curry_arity` is right on both. Whether optcarrot's generated C changes is not known: there is no checkout of it where this was written.

**Test.** `test/method_block_arg_made_in_place.rb`, also in `GC_STRESS_TESTS`: a Method of a top-level method and of an object, made in the argument list of a call that yields, at the top level and inside a method, after another block in the same statement, and out of a call that can answer nil. On master it raises under `SPINEL_GC_STRESS=2`. Here it prints the same plain, at both stress levels with and without `SPINEL_GC_VERIFY=1`, built with clang, and under `--share-strings`; `make gc-stress-test` passes. The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written. The test prints Arrays of Integers.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
