<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A Struct or Data made in place and read as a boxed value lost its members under the stress lane:

```ruby
S = Struct.new(:a, :b)
T = Struct.new(:c)
k = [S, T][0]
p k.new("a" + "1", "b" + "2").to_a    # ["a1", "b2"] in Ruby
```

Under `SPINEL_GC_STRESS=2` this prints two poisoned Strings on master; five tests in `test/` fail there the same way (`boxed_reader_visibility`, `boxed_struct_aref`, `class_value_new_arity_error`, `class_value_new_conditional`, `dynamic_class_new_fed_back`). Plain runs and level 1 do not show it.

`to_a`, `to_h`, `values` and `deconstruct` on a boxed Struct or Data go through `sp_obj_to_h` and `sp_obj_struct_values`, which the compiler writes for the program (`emit_obj_to_h_dispatch`, `emit_obj_struct_values_dispatch`). Each takes the object by value, allocates its Hash or Array, and then reads the members:

```c
static sp_RbVal sp_obj_to_h(sp_RbVal v) {
  switch (v.cls_id) {
    case 0: {
      sp_S *o = (sp_S *)v.v.p; (void)o;
      sp_SymPolyHash *h = sp_SymPolyHash_new(); SP_GC_ROOT(h);
      sp_SymPolyHash_set(h, sp_sym_intern("a"), o->iv_a);
```

The runtime calls them with whatever it was handed (`sp_poly_to_a_call(<the new object>)`), so an object made in place is held by nothing while the container is allocated. Both helpers now open with `SP_GC_ROOT_RBVAL(v);`, two added lines in `src/codegen.c`. A call of a helper pays for that root: 17 instructions a boxed `to_h` (+1.3%) and 17 a boxed `values` (+6.5%) of a three-member Struct (callgrind, 300,000 calls each: 387,014,248 to 392,128,486 and 78,743,289 to 83,864,679).

Measured with both compilers built on d38099fb5, over the 6,012 programs in `test/`, `benchmark/`, `packages/*/test/` and optcarrot: 304 tests, 2 benchmarks (`bm_structaref`, `bm_structaset`) and 1 package test (`packages/json/test/json_generate_struct_record.rb`) contain one of the helpers and gain that line, and nothing else changes in any of them. Neither benchmark calls the helper: callgrind counts 45,666,825 and 663,317 instructions for them before and after. optcarrot's generated C is byte-identical.

`test/boxed_struct_reflection_root.rb` reads a Struct and a Data made through a class held in a variable by each of the four methods and joins `GC_STRESS_TESTS`. With either root taken back out of the generated C, the test prints wrong members at level 2. Of the 260 tests in `test/*.rb` that failed level 2 on de1e627cc, the five named above passed with this change and none of the others changed its result; on d38099fb5 the five still fail on master and pass with this change, and so does this test, with gcc and clang.

Two helpers of the same shape are left as they are, because no program I could write reaches them with an object nothing else holds: `sp_obj_to_hash` has no caller in this tree, and `sp_obj_deconstruct` is called on a pattern match's subject, which the match holds.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it prints Arrays of Strings, Integers and Symbols only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on d38099fb5)
- [ ] Depends on: # (nothing)
