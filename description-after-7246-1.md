<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A row stored into an ivar table was read back as the wrong kind of Array when it comes through methods written below the ones they call:

```ruby
class Deep
  def initialize
    @banks = [[1]]
    @patterns = [[]]
  end
  def bank
    @banks[0] = a1
    @banks[0]
  end
  def a4
    h = @patterns[0]
    h << 7
    h << 8
    h
  end
  def a3; a4; end
  def a2; a3; end
  def a1; a2; end
end
p Deep.new.bank     # [0, 8, 0, 0, 0, 0, 0, 0]   CRuby: [7, 8]
```

With `a1` written first and `a4` last, as `test/ivar_table_late_typed_row_store.rb` has them, it printed `[7, 8]`.

`narrow_int_table_ivars` pins a table once every value stored into it is an int array, and d5e6a326 made it wait while a stored value has no type yet. Here the value has a type on the round the pass first sees it, and the wrong one: `a4` answers `h << 8`, typed an int array before `h`, read out of `@patterns`, settled as boxed, and `a3`, `a2` and `a1`, standing below `a4`, take that answer within the round. The table was pinned on it, a pinned table was not vetted again, and when `a1` came out boxed a round later the row went in, and was read back, as a bare `sp_IntArray *`.

A table this pass pinned is now vetted on every round like one it has not pinned yet, and goes back to the poly array when a store is no longer a row, for the rounds to come to decide from there. That is the reset `narrow_object_arrays` gives its own narrowing every round. A table whose rows stay int arrays stays pinned.

The vet also runs on the pass's one run after the fixpoint, and that run matters: a value typed nil in every round has its boxed type only there. On master `x = nil; @t << x` (or a parameter only ever passed nil) gave C that does not build, and `h = nil; h ||= []; @t[i] = h; @t[i]` printed `[0, 0, 0, 0, 0, 0, 0, 0]` for `[]`; both are right now. The cost: a table that stores by index a nil-only local, a parameter only ever passed nil, or a method's answer of such a local (`x = nil; @t[i] = x`) becomes a boxed array where master keeps the table. Its answers are right.

Found with `tools/order_probe.rb` (#7099): `test/ivar_table_late_typed_row_store.rb` with the methods of `Deep` reversed gave the answer above, and its two orders now have the same types (the probe reports nothing for it). The emitted C of the 5,904 programs the branch's base f672bd97 has in `test/`, `test/reject/`, `test/infer/`, `benchmark/` and the packages' tests is byte-identical before and after (f672bd97 against this branch's head; four of them differ only in the build revision inside `RUBY_DESCRIPTION`): no table pinned there loses a row.

`test/ivar_table_row_store_retyped.rb` has the program above; the same store with the table's other readers beside it (a local read out of the row, a block over the table, an element handed to a parameter), which have to follow the table back to the boxed Array; and a table whose row comes through three methods and stays an int array, which keeps its `sp_PtrArray *` slot. It prints its `.expected` plain and under `SPINEL_GC_STRESS=1`, and prints the wrong row on master. `test/ivar_table_nil_typed_store.rb` has the stores the run after the fixpoint catches (a nil-only local and a nil-only parameter appended, `h ||= []` and `h = [] if flag` stored by index) and the nil-only index store; its C does not build on master. Of 66 generated stores of such a value, 62 are right where master has 38, and none master has right is lost.

The four left are not right on master either: a value typed nil in every round that ends as a Hash (`h ||= {}`) or as an Array given a String (`h ||= []; h << "q"`), each stored by index and appended. Appended, their C does not build on master; here it builds and they print a wrong answer (nil for `{}`, an Array holding one address for `["q"]`) with exit status 0, as the Array given a String does on master when stored by index. The store and the slot are right; the method reading the row back is still typed for an int array. So for those two appends, and for others like them (an Array given a Float, a Symbol or another Array; `h = {} if flag`), this branch turns a build failure into a silently wrong answer; that comes with the first commit's vet after the fixpoint.

The branch has three commits. The second kept a pinned table after the fixpoint and the third takes that back, so the change to `src/analyze.c` is the first commit's plus a comment: 19 lines added and 2 removed, all in `narrow_int_table_ivars` (193 lines).

## `make gate` (on this branch merged with current master)

```
scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
scale-test: work at 4x the program is 4.82x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.29x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.24x (linear 4.00, limit 4.50)
Tests:     5660 pass,        0 fail,        0 error
gate: ALL GREEN
```

Run on macOS (arm64) with CRuby 4.0.7 on master 1d26ef67 merged with this branch's three commits (head b8f48be9). macOS has no `timeout`, which `tools/rubyspec/run.sh` calls, so `build/spinel-timeout` was put on PATH under that name for the run.

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (CRuby 4.0.7 with that flag prints exactly what both new tests' `.expected` files hold, run on macOS; they were written from ruby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical to master's at 1d26ef67)
- [ ] Depends on: # (nothing; #7099 is the probe that found it and is merged)
