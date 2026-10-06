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
p bad        # 0 in Ruby; 174 on master, with gcc and with clang
```

`emit_proc_literal_here` binds such a parameter from the boxed argument channel. An optional's slot is rooted, and so is a post parameter with a known type; the boxed post parameter was declared without a root. What the caller passed is the caller's to hold, but a value the body assigns to `z` was held by nothing.

A parameter the body assigns now gets `SP_GC_ROOT_RBVAL(lv_z);` (`emit_boxed_post_param_use`, which asks `subtree_writes_local`). One the body does not assign is declared as it was.

`test/proc_post_param_reassigned_root.rb` assigns a parameter after a rest, after an optional and two after a rest, allocates, and counts the answers that are not Ruby's. On master (dafa0d047, gcc and clang) the counts are wrong in a plain run and at `SPINEL_GC_STRESS=1` and `2`. It is added to `GC_STRESS_TESTS`.

Not in this change: a String changed in place through the parameter (`z.upcase!`). The C rebinds the slot there though the program writes no assignment, so the new String is still held by nothing: wrong in a plain run, as on master.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on dafa0d047)
- [ ] Depends on: # (nothing)
