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

Master (759d120fd) built with gcc prints `37` in a plain run, and `290` at `SPINEL_GC_STRESS=1`. CRuby prints `0`.

`super(a, b)` in a Struct's `initialize` sets the members in one C comma expression, `(self->iv_name = A, self->iv_tags = B, 0)`. The barrier pass puts a barrier after its store only where the store is a statement of its own; inside an expression it wraps the holder, `SP_WBO(self)->iv_tags = sp_tags_of(lv_i)`, and with gcc the barrier runs before the argument is built. A collection inside the argument promotes the Struct and starts the remembered set over, so the Struct, old by now, holds a young Array that is recorded nowhere, and the next minor mark frees it in its slot. It is the hazard the comment in `gc_wb_insert_seg` describes for a statement and leaves open for "an assignment inside a larger expression". clang builds the argument first, and its build is right.

A store whose argument may allocate (`operand_may_allocate`), into a member that holds a reference, is now written as a statement of its own inside the comma expression, where the pass puts the barrier after the store:

```c
(({ { __typeof__(self) _wb1 = self; _wb1->iv_name = ...; sp_gc_wb((void *)_wb1); } 0; }),
 ({ { __typeof__(self) _wb2 = self; _wb2->iv_tags = sp_tags_of(lv_i); sp_gc_wb((void *)_wb2); } 0; }), 0);
```

Every other store of a `super` keeps its text, and so does every `super` with no such argument: arguments that are read (a parameter, a literal, a constant), members that hold no reference, a bare `super`, `super(*args)`.

Cost: no barrier call is added. The store pays what a store statement's form costs over the wrapper's. Callgrind, 200,000 `new`s, on 759d120fd:

| | gcc before | gcc after | clang before | clang after |
|---|---|---|---|---|
| two reference members, both arguments allocate | 172,055,913 | 172,855,674 | 172,953,792 | 173,152,841 |
| the same by keywords | 172,055,935 | 172,855,696 | 172,953,706 | 173,152,755 |
| a reference member and an Integer | 110,668,841 | 110,468,835 | 110,841,019 | 111,241,870 |
| arguments that are parameters | 32,017,601 | 32,017,601 | 34,418,457 | 34,418,457 |

That is 4 instructions a `new` of 860 with gcc and 1 with clang for two such stores, and 1 fewer with gcc and 2 more with clang for one. The last row compiles to the C it had.

The generated C of 6 of the 6,430 programs under `test/`, `benchmark/` and `packages/*/test/` differs: the new test and five that have such a `super` (`class_value_new_splat`, `class_value_new_struct_custom_init`, `string_handle_initialize`, `struct_custom_initialize_super`, `struct_super_member_nil_default`). Those five print the same bytes before and after in all eight runs: plain, `SPINEL_GC_STRESS=1`, the same with `SPINEL_GC_VERIFY=1`, and `2`, gcc and clang. optcarrot's C is byte-identical; compiling it takes 8,121,526,728 instructions before and 8,121,526,397 after.

**Not in this change:**

- A bare `super` stores the initialize's own parameters, built before it is called. One arm of it copies a String parameter the initialize appends to inside the same expression; I could not write a program that reaches that arm.
- The pull request "A store read for its value takes its write barrier after the value is built" closes this hazard for a store that is the last statement of a statement expression. These stores are operands of a comma expression, which that change leaves with the wrapper, so neither needs the other.

Test: `test/gc_minor_struct_super_store.rb`, in `GC_MINOR_TESTS`: positional arguments, a member with no reference after one with, keywords, and a Data's keywords; each line is the number of Structs that read back something else. On master built with gcc it prints 39, 44, 39 and 44 with the minor mark on and 0 with it off, and the generational verifier reports the holder the barrier did not record; clang's build passes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after)
- [ ] Depends on: # (nothing)
