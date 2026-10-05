<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`test/hash_splat_to_a.rb` prints one wrong line under the stress lane:

```
$ bin/spinel test/hash_splat_to_a.rb -o /tmp/h && SPINEL_GC_STRESS=2 /tmp/h | diff test/hash_splat_to_a.rb.expected -
17c17
< [1, 2]
---
> [-2604246222170760229, -2604246222170760229]
```

The line is `p [*Pt.new(1, 2)]`. With String members, `p Pt.new("a" + "1", "b" + "2").to_a` ends in SIGSEGV at that level.

`to_a`, `values`, `deconstruct`, `values_at` and `deconstruct_keys` on a Struct or Data are emitted inline by `emit_struct_recv_call`: the receiver goes into a C temporary, the Array or Hash is allocated, and the members are read off the temporary:

```c
({ sp_Pt *_t11 = sp_Pt_new(1LL, 2LL); sp_PolyArray *_t12 = sp_PolyArray_new(); SP_GC_ROOT(_t12); sp_PolyArray_push(_t12, ... _t11->iv_a ...); ... })
```

A receiver made in place (a `new`, a method's result, the Struct a splat converts) is held by nothing while the container is allocated. `to_h`, a few lines below in the same function, roots its receiver temporary; these four emitters now root theirs, one `SP_GC_ROOT` each.

A receiver read from a local, an instance variable, self or a constant is held where it is, and three of the four emitters run no Ruby code between the receiver and the last member read (`to_a`, `values` and `deconstruct`; `values_at` with literal keys; `deconstruct_keys`). Those three ask `expr_is_held_ref` and write for a held receiver the C they wrote before. `values_at` with keys known only at run time roots every receiver: a key runs after the receiver was read and can drop the variable it came from, as in `l.values_at((l = nil; i), k(1), k(0))`, which ends in SIGSEGV at that level on master.

The function is 675 lines and becomes 678.

Measured with both compilers built on de1e627cc: optcarrot's generated C is byte-identical, so is that of the 64 programs in `benchmark/`, and 28 of the 5,711 in `test/*.rb` change, each by added `SP_GC_ROOT`s and nothing else. The root costs 14 instructions a call where the receiver is made in place (callgrind, 200,000 times `Pt.new(i, 2).to_a.size`: 48,213,449 to 51,016,737, +5.8% of that call) and nothing where it is held (`l.to_a.size` on a local: 37,100,472 before and after): `l.to_a`, `l.values_at(1, 0)`, `l.deconstruct_keys([:a])` and `x, y = *l` on a local generate master's C.

`test/struct_values_fresh_receiver_root.rb` reads a Struct or Data made in place through each of the five methods, through a splat in four positions, by literal and by run-time keys, and once through a run-time key that drops the local the receiver was read from. It and `test/hash_splat_to_a.rb` join `GC_STRESS_TESTS`; `make gc-stress-test` fails without the change and passes with it. Plain runs and `SPINEL_GC_STRESS=1` do not show the loss: the freed Struct's bytes are still there when the members are read.

Of the 261 tests in `test/*.rb` that failed under `SPINEL_GC_STRESS=2` on ab60de7ca, 260 still fail on de1e627cc; 23 of those pass with this change and none of the others changes its result: `anon_struct_class_value`, `call_args_read_in_place`, `closure_captures_class_value`, `each_with_index_terminal_poly`, `ewi_terminal_poly_name`, `hash_splat_to_a`, `issue_2971`, `issue_2973`, `issue_3079`, `keyword_computed_key`, `nested_pattern_data_deconstruct`, `paren_receiver_shapes`, `proc_rebound_local_arg_order`, `struct_conformance_wave`, `struct_each_with_index_blockless`, `struct_each_with_index_own_method`, `struct_enumerable_wave8`, `struct_local_reassigned`, `struct_local_zero_arg_new`, `struct_subclass`, `struct_super_splat_kwsplat`, `struct_to_a_values`, `struct_value_equality`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it prints Arrays of Strings, Integers and Symbols only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on de1e627cc)
- [ ] Depends on: # (nothing)
