<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`instance_exec` and `instance_eval` on an object made in place lost that object under the stress lane:

```ruby
class K
  def initialize(s) = (@e = s)
end
p K.new("e" + "1").instance_exec { [@e, @e] }    # ["e1", "e1"] in Ruby; SIGSEGV on master at SPINEL_GC_STRESS=2
```

On a user class the call is spliced inline (`emit_call_instance_eval_arms`): the receiver goes into a C temporary and the block's body reads its instance variables through it. Nothing rooted the temporary, so the block's first allocation could collect a receiver that only the temporary holds.

The temporary is now rooted, unless the receiver is `self` or a read of a local, an instance variable or a constant, which hold their object already (`expr_is_held_ref`).

`test/instance_exec_fresh_receiver_root.rb` reads a receiver made in place through nine forms of the call and counts the wrong answers of 20,000 more. On master (dafa0d047, gcc and clang) it is right in a plain run, prints a wrong count at level 1 with exit 0, and ends in SIGSEGV at level 2. It is added to `GC_STRESS_TESTS`.

Not in this change: a receiver read from a local that the block itself empties, `y.instance_exec { y = nil; a = ["h" + "4", "i" + "5"]; [@e, a, @e] }`. The temporary is then the object's only holder and is not rooted: SIGSEGV at level 2, as on master.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on dafa0d047)
- [ ] Depends on: # (nothing)
