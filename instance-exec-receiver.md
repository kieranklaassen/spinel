<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`instance_exec` and `instance_eval` on an object made in place lose that object under the stress lane:

```ruby
class K
  def initialize(s) = (@e = s)
end
p K.new("e" + "1").instance_exec { [@e, @e] }    # ["e1", "e1"] in Ruby
```

Under `SPINEL_GC_STRESS=2` this ends in SIGSEGV on master, and two tests in `test/` fail that level for it (`instance_exec_args_caller_self`, `instance_exec_receiver_ivars`). Level 1 shows it too, as a wrong answer with no report: when the block builds another object of the receiver's class, 3 of 20,000 calls read that object's ivar in place of the receiver's.

On a user class the call is spliced inline (`emit_call_instance_eval_arms`): the receiver goes into a C temporary and the block's body reads its ivars through it.

```c
sp_K *_t1 = sp_K_new();
sp_StrArray *_t4 = sp_StrArray_new();
sp_StrArray_push(_t4, _t1->iv_e);
```

Nothing rooted `_t1`, so the block's first allocation could collect a receiver that only the temporary holds. The temporary is now rooted, unless the receiver is self or a read of a local, an ivar or a constant, which hold their object already (`expr_is_held_ref`). One file, `src/codegen_call_object.c`, +5 −1. The root costs 12 instructions a call on a receiver made in place (callgrind, 300,000 times `N.new(i).instance_exec { @n }` on d38099fb5: 24,889,147 to 28,489,148) and nothing on a held one, whose C is unchanged.

Measured with both compilers built on d38099fb5, over the 6,012 programs in `test/`, `benchmark/`, `packages/*/test/` and optcarrot: 12 tests change, each by a root on such a temporary (a slot in the function's root frame where it has one, which renumbers the slots after it) and nothing else. No benchmark and no package test changes, and optcarrot's generated C is byte-identical.

`test/instance_exec_fresh_receiver_root.rb` reads a receiver made in place through nine forms of the call and counts the wrong answers of 20,000 more, and joins `GC_STRESS_TESTS`. On master (d38099fb5) it ends in SIGSEGV at level 2 and prints 3 for the count at level 1; with this change it prints Ruby's output at every level with gcc and clang. Of the 260 tests in `test/*.rb` that failed level 2 on de1e627cc, the two named above passed with this change and none of the others changed its result, and the 85 other tests that call `instance_exec` or `instance_eval` passed as before, plain and at level 2; on d38099fb5 the two still fail on master and pass with this change.

Not covered, and the same on master: a receiver read from a local or an instance variable that the block itself empties. The temporary is then the object's only holder and is not rooted, so `y.instance_exec { y = nil; a = ["h" + "4", "i" + "5"]; [@e, a, @e] }` still ends in SIGSEGV at level 2.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on d38099fb5)
- [ ] Depends on: # (nothing)
