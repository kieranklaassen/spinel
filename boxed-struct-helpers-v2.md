<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A Struct or Data made in place and read as a boxed value lost its members under the stress lane:

```ruby
S = Struct.new(:a, :b)
T = Struct.new(:c)
k = [S, T][0]
p k.new("a" + "1", "b" + "2").to_a    # ["a1", "b2"] in Ruby; [, ] on master at SPINEL_GC_STRESS=2, exit 0
```

`to_a`, `to_h`, `values` and `deconstruct` on a boxed Struct or Data go through `sp_obj_to_h` and `sp_obj_struct_values`, which the compiler writes for the program. Each takes the object by value, allocates its Hash or Array, and then reads the members, so an object made in place is held by nothing while the container is allocated.

Both helpers now open with `SP_GC_ROOT_RBVAL(v);`.

`test/boxed_struct_reflection_root.rb` reads a Struct and a Data made through a class held in a variable by each of the four methods. On master (dafa0d047, gcc and clang) it is right in a plain run and at level 1, and prints wrong members at level 2 with exit 0. It is added to `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on dafa0d047)
- [ ] Depends on: # (nothing)
