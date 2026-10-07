<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Tag
  attr_reader :n
  def initialize(n) = @n = n
end
tag = Tag.new(1)
p({ tag => :a } == { tag => :a })   # true
h = { tag => 1 }
g = { tag => 2 }
p h.merge(g).size                    # 1
p({ a: tag } == { a: tag })          # true
```

Before: false, 2, false. Nothing is refused and nothing raises.

After: true, 1, true.

Cost: a class whose object a program writes into a Hash literal, or passes in keywords, is a heap object for the whole program, as one written into an Array literal or passed as a positional argument already is. Ten million `Tag.new(i)` beside such a literal take 0.051 s where they took 0.005. The program, with gcc 13.3 at spinel's own flags, the least CPU time of five runs:

```ruby
class Tag
  attr_reader :n
  def initialize(n) = @n = n
end
tag = Tag.new(1)
h = { tag => :a }
p h.size
i = 0
s = 0
while i < 10_000_000
  t = Tag.new(i)
  s += t.n
  i += 1
end
p s
```

`an_phase_value_types` lays a small immutable class out by value, then takes the layout back from every class whose object needs a heap pointer. Its arm for an Array or Hash literal asked each element for its type. A Hash literal's element is the pair, which has no type, so neither the key nor the value was seen. The class stayed by value and each literal boxed a copy of the struct: two literals holding the same object held two, and `==`, `eql?`, `hash` and `equal?` answered for two.

Chosen: the pair's key and its value are each asked, in a Hash literal (`{ tag => 1 }`), in a Hash argument without braces (`take(tag => 1)`) and in keywords (`take(a: tag)`) alike. A positional argument already takes the layout back, and `**o` gathers a keyword's value into a Hash as a brace pair stores it.

Rejected: the braces only. It leaves `take(tag => 1) == take(tag => 1)` and `def take(**o) = o; take(a: tag) == take(a: tag)` false, 16 of the 202 forms below.

Left alone:

- a class that keeps the by-value layout is as before; this change looks at no other use;
- `test/poly_dispatch_arg_gc_root.rb`, one of the six programs below, fails at `SPINEL_GC_STRESS=2` on master (`the mark reached a freed slot`) and fails the same way here.

Measured on master d02a49fb7f74 with gcc, every program against CRuby 3.3.6:

- 396 one-program forms: six classes (one field, two, a Float field, a method and no reader, and as controls a class with its own `==`, `eql?` and `hash` and a class with a writer) by 33 reads (the key in `==`, `merge`, a repeated key, `uniq`, `<=`, `keys`, `key?`, `[]`, `&`; the value in `==`, `values`, `equal?`, `uniq`, `invert`, nested, in an Array; keywords and a Hash argument without braces; and controls with no Hash literal), at the top level and in a method. Master: 194 right, 202 a wrong answer. With the change: 396 right.
- 320 more: five classes (a String field, a `true` field, eight fields, one field, and a class with a writer) by 32 reads (`{ tag: }`, the key and the value read back with `equal?`, `key?`, `value?`, `delete`, `**h`, a literal in a block, a lambda, a loop, a method's answer, a default argument, an instance variable, an interpolation, a frozen literal, a Hash as a key). Master: 216 right, 104 a wrong answer. With the change: 320 right.
- All 716 are right too at `SPINEL_GC_STRESS=2`, and the first 396 with clang at `SPINEL_GC_STRESS=1`.
- `make cident REF=d02a49fb7f74`: `6398 identical, 7 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The seven are the new test and six programs that write a small class into a Hash literal or keywords: `test/class_body_constant_bare_new.rb`, `test/json_to_json_boxed_receiver.rb`, `test/ostruct_temp_rooted.rb`, `test/poly_dispatch_arg_gc_root.rb`, `test/poly_dispatch_proc_form_untyped_param.rb`, `packages/io/test/io_buffer_poly_io_write.rb`. Five print their `.expected` on master and here with gcc and clang, with `--int-overflow=promote`, and under `SPINEL_GC_STRESS=1` and `2`; the sixth is the one above. optcarrot's C is unchanged. `make reject-test` and `tools/refusals.sh` pass.
- `test/hash_literal_value_object.rb`: master prints 10 of its 13 lines wrong. With the change it prints its `.expected` in each of those ways. Each of its three parts has a class of its own, since one use that needs a heap object gives the whole class one.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
