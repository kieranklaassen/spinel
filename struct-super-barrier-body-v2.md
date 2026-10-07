<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Struct whose own `initialize` calls `super` with arguments that allocate lost what it had just stored to the next minor collection.

```ruby
def tags_of(i)
  junk = nil
  200.times { |k| junk = ["c#{k}", "d#{k}"] }
  ["t#{i}", "x"]
end

Pair = Struct.new(:name, :tags) do
  def initialize(i)
    super("n#{i}", tags_of(i))
  end
end

row = []
300.times { |i| row << Pair.new(i) }
bad = 0
row.each_with_index { |s, k| bad += 1 unless s.name == "n#{k}" && s.tags == ["t#{k}", "x"] }
p bad
```

Master (8dc552254) built with gcc prints `37` in a plain run, and `290` at `SPINEL_GC_STRESS=1`. CRuby prints `0`.

`super(a, b)` in a Struct's `initialize` sets the members in one C comma expression, `(self->iv_name = A, self->iv_tags = B, 0)`. The barrier pass puts a barrier after its store only where the store is a statement of its own; inside an expression it wraps the holder, `SP_WBO(self)->iv_tags = sp_tags_of(lv_i)`, and with gcc the barrier runs before the argument is built. A collection inside the argument promotes the Struct and starts the remembered set over, so the Struct, old by now, holds a young Array that is recorded nowhere, and the next minor mark frees it in its slot. It is the hazard the comment in `gc_wb_insert_seg` describes for a statement and leaves open for "an assignment inside a larger expression". clang builds the argument first in this program, and its build of it is right.

A store whose argument may allocate (`operand_may_allocate`), into a member that holds a reference, is now two statements inside the comma expression: the argument is built into a temp of the slot's type, and the temp is stored, where the pass puts the barrier after the store:

```c
(({ __typeof__(self->iv_name) _sa1 = ...; { __typeof__(self) _wb1 = self; _wb1->iv_name = _sa1; sp_gc_wb((void *)_wb1); } 0; }),
 ({ __typeof__(self->iv_tags) _sa2 = sp_tags_of(lv_i); { __typeof__(self) _wb2 = self; _wb2->iv_tags = _sa2; sp_gc_wb((void *)_wb2); } 0; }), 0);
```

The argument stays out of the store's own statement. The pass rewrites a store statement whole and scans on past it, so a store inside the argument would be left with no barrier at all there:

```ruby
First = Struct.new(:name, :tags) do
  def initialize(i, o, t)
    super((o.v = ["v#{i}"]).first, t)     # o is an old object
  end
end
```

With the argument inside the statement, 289 of 300 such `o.v` read back another value in a plain run, gcc and clang, where master is right. Built into the temp, that store is met by the pass as it is on master, and the count is 0.

Every other store of a `super` keeps its form, the store inside an argument among them, and a `super` with no such argument keeps its C: arguments that are read (a parameter, a literal, a constant), members that hold no reference, a bare `super`, `super(*args)`.

Cost: no barrier call is added. The store pays what a store statement's form costs over the wrapper's. Callgrind on 8dc552254, each row this loop with its own Struct:

```ruby
Pair = Struct.new(:name, :tags) do
  def initialize(i)
    super("n" + i.to_s, [i, i + 1])
  end
end
k = 0
i = 0
while i < 200000
  pr = Pair.new(i)
  k += pr.tags.size
  i += 1
end
p k
```

| | gcc before | gcc after | clang before | clang after |
|---|---|---|---|---|
| the program above | 172,055,913 | 172,855,674 | 172,953,792 | 173,152,841 |
| `keyword_init: true`, `super(name: "n" + i.to_s, tags: [i, i + 1])` | 172,055,935 | 172,855,696 | 172,953,706 | 173,152,755 |
| `Struct.new(:name, :size)`, `super("n" + i.to_s, i * 2)`, the loop adds `s.size` | 110,669,969 | 110,469,963 | 110,841,019 | 111,242,997 |
| `initialize(name, tags, extra)` with `super(name, tags)` and `@extra = extra`, made from one String and one Array | 32,017,601 | 32,017,601 | 34,418,457 | 34,418,457 |

That is 4 instructions a `new` of 860 with gcc and 1 with clang for two such stores, and 1 fewer with gcc and 2 more with clang for one. The last row compiles to the C it had.

The generated C of 6 of the 6,447 programs under `test/`, `benchmark/` and `packages/*/test/` differs: the new test and five that have such a `super` (`class_value_new_splat`, `class_value_new_struct_custom_init`, `string_handle_initialize`, `struct_custom_initialize_super`, `struct_super_member_nil_default`). Those five print the same bytes and end the same way before and after in all eight runs: plain, `SPINEL_GC_STRESS=1`, the same with `SPINEL_GC_VERIFY=1`, and `2`, gcc and clang. For two of them that is an abort, on master and here: `class_value_new_splat` at level 1 with the verifier and at level 2, `string_handle_initialize` at level 2. optcarrot's C is byte-identical; compiling it takes 8,245,022,204 instructions before and 8,244,828,262 after.

**Not in this change:**

- A bare `super` stores the initialize's own parameters, built before it is called. One arm of it copies a String parameter the initialize appends to inside the same expression, and that copy stays where it is.
- The pass's step over a store statement it has rewritten is master's, and it leaves a store in another store's value with no barrier wherever the two are one C statement (`k.w = @last.w = v`). The pull request "A store in another store's value takes its write barrier" is about that; this change needs none of it, and keeps its own arguments out of the statement.
- An exception subclass's `super(msg)` stores the message with no barrier (`self->msg = sp_rb_msg_of(lv_i)`). 300 of `class Oops < StandardError` whose `initialize(i)` is `super(msg_of(i))`, with a `msg_of` that allocates as `tags_of` does, read back 36 other messages in a plain run and 274 at level 1, gcc and clang, on master and here; 0 with the minor mark off.
- A member that is a Range of Strings is kept by value (`self->iv_span = sp_srange_new(...)`): `super("n#{i}", (lo_of(i).."c#{i}"))` reads back 43 of 300 wrong with gcc and 38 with clang in a plain run, on master and here.
- The pull request "A store read for its value takes its write barrier after the value is built" closes the hazard above for a store that is the last statement of a statement expression. These stores are operands of a comma expression, which that change leaves with the wrapper, so neither needs the other.

Test: `test/gc_minor_struct_super_store.rb`, in `GC_MINOR_TESTS`: positional arguments, a member with no reference after one with, keywords, and a Data's keywords; then a store inside the first argument, inside the second, and in a sequence whose last expression is the argument, each into one of 300 old objects with the caller allocating between two `new`s. Each line is the number of objects that read back something else. On master built with gcc it prints 39, 44, 39 and 44 for the first four with the minor mark on and 0 with it off, and the generational verifier reports the holder the barrier did not record; clang's build of it is right. The last three print 0 on master and here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after)
- [ ] Depends on: # (nothing)
