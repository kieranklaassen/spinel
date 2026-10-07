<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A method called on a small object made in place could read a freed String:

```ruby
class Name
  def initialize(r) = @s = "hello world " * r
  def has(k) = @s[k] ? 1 : 0
end
bad = 0
100_000.times { bad += 1 unless Name.new(240).has("wor" + "ld") == 1 }
p bad        # 0 in Ruby; 1111 on master, with gcc and with clang
```

A class with a few fields that is never written is kept by value, in the C temp its call reads it from. Nothing held that temp's String field while the argument was built or while the method allocated. The String fields of such a temp are now rooted one by one (`emit_gc_root_tmp_refs`, which a by-value argument already goes through) at the four places that take the receiver into a temp: the plain call, a method with a block expanded at its call, a comparison the class defines, and an interpolated part with its own `to_s`.

A receiver read from a local, an instance variable or `self` compiles to master's C, and so does a by-value class with no String field. The root costs 16 instructions a call (callgrind, 200,000 calls of `C.new(3).len("ab")`: 104,919,964 to 108,119,967).

Not in this change, both as on master: `!Name.new(240)` where the class defines `!`, and the subject of a pattern match (`case Name.new(240) in [a, b]`) whose `deconstruct` allocates.

`test/value_object_receiver_string_root.rb` counts the wrong answers of 2,000 calls through eight forms. On master (8684d54ce, gcc and clang) every form is wrong in a plain run, so it is an ordinary test and not in `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it is nine lines, each `0`)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on 8684d54ce)
- [ ] Depends on: # (nothing)
