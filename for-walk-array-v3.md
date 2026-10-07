<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `for` loop over the Array a call answers lost the Array while it walked it:

```ruby
def words(n) = (1..n).map { |i| "w" + i.to_s }
out = []
for w in words(3000)
  out << w.upcase + "?" * 20
end
p out.size    # 3000 in Ruby; on master: undefined method 'upcase' for nil (NoMethodError)
```

The loop takes the Array into a C temp and nothing else held it, so the first collection the body caused took the Array. `for l in text.lines`, `for w in a + b` and `for k, v in pairs(n)` failed the same way, and so did a variable's Array once the body gave the variable another (`for w in ws; ws = mk(2); sum += w; end` summed 1546860 for 13495500).

The Array walk of `emit_for` now roots the Array, as the String Range, boxed value and Hash walks beside it do. The root is left out where a local, instance, class or global variable holds the Array and the body cannot give it another (`read_rebound_by`); that loop compiles to master's C, and so does a loop over a constant.

A loop that was right and is rooted now is one over a call's answer, or over an instance, class or global variable whose body calls something that could assign it. It pays 7 to 21 instructions a loop entry, whatever the Array's length (callgrind, 200,000 entries of `for x in b.a` through a reader: 14,863,506 to 16,463,512 in a method called each time, 8 an entry; 8,463,457 to 12,463,456 written inside a `while`, 20 an entry, where the root is pushed and popped at each entry). The root is a second slot, so the walk's own temp stays in a register.

Not in this change: a loop over a constant the body assigns again (`for w in LIST; LIST = mk(2)`), as on master.

`test/for_call_array_root.rb` walks a method's answer, `String#lines`, the sum of two Arrays, pairs into two loop variables, an instance variable the body clears and a local the body rebinds. On master (8684d54ce, gcc and clang) it raises NoMethodError in a plain run, so it is an ordinary test and not in `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on 8684d54ce)
- [ ] Depends on: # (nothing)
