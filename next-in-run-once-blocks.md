<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A `next` in a block that is run once where it is written did not build:

```ruby
c = ARGV.length == 0
p 5.instance_eval { next 0 if c; self * 2 }                  # 0
p catch(:t) { next 5 if c; throw :t, 1 }                     # 5
class Box
  def base = 3
  define_method(:dm) { next 0 if ARGV.length == 0; base * 2 }
end
p Box.new.dm                                                 # 0
Pair = Struct.new(:x, :y)
h = Pair.new(1, 20).to_h { |k, v| next [k, 0] if v > 5; [k, v] }
p h[:y]                                                      # 0
```

Each stopped at the C compiler with "continue statement not within a loop". These blocks are spliced in place, or compiled as a method's body, with no loop around them, and the `next` came out as the `continue` an iterator's block gets. Inside a loop the same program built and was wrong, because the `continue` took the enclosing loop's next turn:

```ruby
i = 0
out = []
while i < 3
  i += 1
  v = i.instance_eval { next -1 if self == 2; self * 10 }
  out << v
  out << :after
end
p out   # CRuby [10, :after, -1, :after, 30, :after], Spinel [10, :after, 30, :after]

p [1, 2, 3].map { |x| y = catch(:k) { next 0 if x == 2; x }; y + 100 }
        # CRuby [101, 100, 103], Spinel [101, 0, 103]
```

Three rewrites, each handing the `next` to code that already runs one:

- `instance_eval` and `instance_exec` on anything but a user object, and `Kernel#catch`: the body becomes the block of a `then`, `{ true.then { body } }`. `emit_block_value_into` gives that block its `do { } while (0)` and its value slot, and `then_block_value_ty` joins the `next` values into the block's type. A user object's `instance_exec` is spliced inside a loop already and keeps its form.
- `define_method` and `define_singleton_method`: the block is the method's body, so a `next` it owns is retyped as the `return` it means.
- `Struct#to_h` with a block is unrolled into one store per member, the pair read off the block's last statement. With a `next` in the block the members go into a Hash first, `s.to_h.to_h { }`, whose `to_h` runs the block in a loop.

The block of `Class.new`, `Module.new`, `Struct.new` or `Data.define` is the class's body, and a `next` in it would make the definitions after it or not at run time. That is refused at the `next`, with a message, instead of reaching the C compiler (`test/reject/class_body_block_next.rb`, registered in `reject-test`).

Only a block that owns a `next` is touched; which one it owns is read from the source, stopping at loops, blocks, lambdas and defs. The two passes run from passes `analyze_program` already calls (`desugar_define_method_proc_arg` and `desugar_instance_eval_builtin`), so that function does not grow, and nothing in `emit_call_body` or `emit_stmt_inner` changes.

Found with the dead code probe (#7223), which puts a `next` at the head of the blocks of 300 tests: 64 of its results on d83c5bd5 were this C error, and 12 of them are in these blocks. 11 now build and print their test's `.expected`; the one in a `Data.define` block is refused. The other 52 are in the block of `Fiber.new`, `Thread.new` or `Enumerator.new` and are a change of their own, which this one does not need.

`make cident REF=917dd251`, with optcarrot in the corpus: 5677 identical, 5 differ, 0 refusal changes. The five are the new test and the four programs that print `RUBY_DESCRIPTION`, which names the compiler's own commit (`frozen_chilled_builtin_strings`, `object_scoped_ruby_constants`, `ruby_description_shape`, `symbol_id2name_ruby_desc_minmax`); before the commit was made, against f672bd97, it was 5681 identical and the new test. optcarrot's C is byte for byte the same, 12,255 lines. `reject-test` and the gate's property checks pass here (scale-test 1.74 / 4.82 / 6.31 / 4.25); the full `make gate` is below.

`test/next_in_run_once_block.rb` has the `next` with a value, without one and of each kind (Integer, String, Symbol, Float, nil) in `instance_eval` and `instance_exec`; in a `while` and in a `map` block, where the statements after the block still run; a captured local written before it; an `ensure` it leaves; `catch` with a tag, with a block parameter and without a tag, with a `throw` beside it; all of it again in a method, a proc and a lambda; `define_method` with no parameter, with one, with a keyword, with an iterator's block and a `while` that keep their own `next`, with an `ensure`, and in `class << self`; `define_singleton_method`; and `Struct#to_h` and `Data#to_h` with Symbol and String keys, in a `while` and in a proc. It prints its `.expected` plain and under `SPINEL_GC_STRESS=1` and `=2`, and does not build on master.

Left as they were: such a block written with numbered parameters or `it`, one with a `break` or `redo` beside the `next`, any in a program that defines its own `then`, and a `next` whose value `then` cannot join with the block's last one (a String and an Array).

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it prints Integers, Symbols, Strings, a Float, nil and Arrays of them, nothing whose `inspect` changed since)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (OPTCARROT_LINE)
- [ ] Depends on: # (nothing)
