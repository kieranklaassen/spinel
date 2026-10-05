<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A `next` or a `break` with no value in the block of `instance_eval` or `instance_exec` left the call answering something other than nil:

```ruby
class Box
  def initialize; @v = 7; end
end
o = Box.new
c = ARGV.length == 0
t = o.instance_eval { next if c; 4 }
p t     # CRuby nil, Spinel 4
```

The splice of the block declares a slot for the call's value. The last expression stores into it, and so does a `next` or a `break` that carries a value. One with no value stored nothing, so the call read a slot nothing had written. Where such a jump binds to the splice (`ie_block_bare_jump`), the slot now starts as the nil of its type, and a bare `break` is joined into the call's type as a bare `next` already was.

`make cident` against master: 6076 identical, 3 differ; with `--int-overflow=promote`: 6069 identical, 3 differ, 7 refused by both. The three that differ are the new test, `instance_exec_break` and `instance_exec_next`, whose slot now starts as nil and whose output is the same. optcarrot's C is the same. No function over 1,000 lines is touched, and `emit_call_body` is not touched.

A generator outside the tree wrote 3,888 programs: `instance_eval` and `instance_exec` on eight kinds of receiver, `next`, `break`, `next nil`, `break nil`, `next 5` and `break 5`, nine kinds of last expression, the value used three ways, at the top level, in a `while` and in a method. 704 that were wrong are right. No program that was right is anything else, and none that did not build prints a wrong answer.

Left as they were:

- A Float last expression beside such a jump. The Float slot's nil is a sentinel that nothing boxes as nil at this call, so the slot is not started as one and the call answers as before.
- `next nil` and `break nil` beside an Integer last expression answer 0, as before.
- On a receiver that is no object (`5`, `nil`, a boxed value) the block takes another path. A bare `next` there is right; a bare `break` is written as a C `break`, which does not build at the top level and leaves a `while` around it.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (none)
