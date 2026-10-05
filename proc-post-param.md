<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A proc's parameter that follows a rest or an optional lost a value the body assigned to it:

```ruby
A = "ab" * 2_000
pr = proc do |*rest, z|
  z = A + "<#{rest.size}>" + z
  junk = (1..40).map { |k| A + k.to_s }
  z + junk.size.to_s
end
bad = 0
1_000.times { |i| bad += 1 unless pr.call(1, 2, "s#{i}") == A + "<2>s#{i}40" }
p bad        # 0 in Ruby; 174 on master in a plain run, with gcc and with clang
```

With short Strings a plain run is right and `SPINEL_GC_STRESS=2` stops it ("the mark reached a freed heap string"); a longer body dies with SIGSEGV at level 1.

`emit_proc_literal_here` (`src/codegen.c`) binds such a parameter from the boxed argument channel. An optional's slot is rooted (`emit_proc_param_slot`), and so is a post parameter with a known type; the boxed post parameter was declared without a root:

```c
sp_RbVal lv_z = ({ sp_int __i = _sp_ps + 0; (__i < argc && __i < 16) ? _sp_proc_poly_args[__i] : sp_box_nil(); });
(void)lv_z;
```

What the caller passed is the caller's to hold. A value the body assigns to `z` is held by nothing, and the next allocations free it. A parameter the body writes now gets `SP_GC_ROOT_RBVAL(lv_z);` on that line (`emit_boxed_post_param_use`, which asks `subtree_writes_local`); one the body only reads is declared as it was. `emit_proc_literal_here` does not grow.

`test/proc_post_param_reassigned_root.rb` assigns a parameter after a rest (`proc`), after an optional (`lambda`) and two after a rest (`->`), allocates, reads it back, and counts the answers that are not Ruby's over 1,000 rounds each. On master (ab9b925aa, Linux x86-64) it counts 504 of 3,000 in a plain run, 2,996 at level 1 and 2,973 at level 2, with gcc and clang alike; with this change it prints Ruby's output at plain, level 1, level 1 with `SPINEL_GC_VERIFY=1` and level 2 with both compilers. It is added to `GC_STRESS_TESTS`.

Measured with both compilers built on ab9b925aa:

- 63 one-line programs (`proc`, `lambda`, `->` by ten parameter shapes by a String and an Array, each assigned, then an allocation, then read; and a rest assigned), with gcc and clang at plain, level 1, level 1 with verify and level 2: 15 fail on master, 6 with this change, and none is right on master and wrong with it. The nine cured are the parameter after a rest, after an optional, and the second of two after a rest.
- Generated C: no program in `test/*.rb` (5,797), in `benchmark/` (64), among the package tests (156) or optcarrot changes. None of them assigns such a parameter; the new test is the only one that does.
- Cost (callgrind, 1,000,000 calls): a proc that assigns the parameter, `proc { |*r, z| z = z + 1; z }`, 363,799,014 to 372,804,565, 9 instructions a call. One that only reads it counts the same before and after (`proc { |*r, z| z }` 275,796,877, `proc { |*, z| z }` 131,657,005), and so does a proc without such a parameter (`proc { |a, z| z }` 126,656,986).

Not in this change, each the same before and after:

- The six programs still failing are the `->(k) { k = ... }` form with a required parameter. A block's assigned parameter becomes an ordinary local (`desugar_reassigned_block_params`), and that pass does not look at a lambda literal.
- A proc's assigned required parameter that a nested block reads is skipped by the same pass and loses its value too (345 of 1,000 calls in a plain run with 4,000-character Strings).
- An assigned `&blk` parameter is declared without a root (SIGSEGV at level 2).
- A Range, a Rational or a Complex made in the argument and handed to a parameter the body only reads prints freed bytes at level 2: the call site does not hold the box it makes for the call. That is the caller's side and another change.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it is `0`, `4009`, a String, `4009`, a String)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on ab9b925aa)
- [ ] Depends on: # (nothing)
