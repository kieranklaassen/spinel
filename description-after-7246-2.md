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

After the fixpoint the pass runs once more, and there a pinned table is left as the rounds decided it, as on master: no round is left then to retype what was read out of the table. So `x = nil; @t[i] = x` keeps its table.

Found with `tools/order_probe.rb` (#7099): `test/ivar_table_late_typed_row_store.rb` with the methods of `Deep` reversed gave the answer above, and its two orders now have the same types (the probe reports nothing for it). The emitted C of the 5,904 programs the branch's base f672bd97 has in `test/`, `test/reject/`, `test/infer/`, `benchmark/` and the packages' tests is byte-identical before and after (f672bd97 against this branch's head; four of them differ only in the build revision inside `RUBY_DESCRIPTION`): no table pinned there loses a row.

`test/ivar_table_row_store_retyped.rb` has the program above; the same store with the table's other readers beside it (a local read out of the row, a block over the table, an element handed to a parameter), which have to follow the table back to the boxed Array; and a table whose row comes through three methods and stays an int array, which keeps its `sp_PtrArray *` slot. It prints its `.expected` plain and under `SPINEL_GC_STRESS=1`, and prints the wrong row on master. `test/infer/ivar_table_nil_only_store.rb` has three stores by index of a value that is only ever nil (a local, a parameter, the answer of a method that returns such a local), and `infer-test` asserts that each table keeps its `sp_PtrArray *` slot, as it does on master.

What this branch does not do: a value typed nil in every round has its boxed type only after the fixpoint, and stored into such a table it is as on master. Such values are `h = nil; h ||= []`, `h = {} if flag`, and a local or a parameter that is only ever nil. Stored by index, the ones that are only ever nil are right, on master and here. Appended, `x = nil; @t << x` gives C that does not build, on master and here; and `h = nil; h ||= []; @t[i] = h; @t[i]` prints `[0, 0, 0, 0, 0, 0, 0, 0]` for `[]`, on master and here.

The cost, in numbers from generated programs that are not in this PR: of 66 stores of such a value into an int table, 41 are right here and 38 on master. A head of this branch that un-pinned the table after the fixpoint (the third commit) had 62 of them right as printed, but of 914 further generated programs it had 54 wrong or unbuilt that master has right; this head differs from master in none of the 914.

The branch has four commits: the fix, which vetted a pinned table on every run of the pass; one that keeps a pinned table on the run after the fixpoint; one that took that back; and one that restores it, because un-pinning there lost a program master has right (after `x = nil; @t[i] = x`, `r = @t[k]; r.equal?(@t[k])` printed false: the local stayed an int array while the element went boxed). The tree is the second commit's, so the branch as it stands vets a pinned table again in every round and leaves it alone after the fixpoint. In `src/analyze.c` it is 24 lines added and 6 removed: `narrow_int_table_ivars` (194 lines) is told whether it runs in a round, and its two callers say so. The `Makefile` gains the infer fixture's two lines.

## `make gate` (on this branch merged with current master)

```
scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
scale-test: work at 4x the program is 4.82x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.29x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.24x (linear 4.00, limit 4.50)
Tests:     5659 pass,        0 fail,        0 error
gate: ALL GREEN
```

Run on macOS (arm64) with CRuby 4.0.7 on master 1d26ef67 merged with this branch's four commits (head 8479317c). macOS has no `timeout`, which `tools/rubyspec/run.sh` calls, so `build/spinel-timeout` was put on PATH under that name for the run.

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (CRuby 4.0.7 with that flag prints exactly what the new test's `.expected` file holds, run on macOS; it was written from ruby 3.3.6. The infer fixture has no `.expected`)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical to master's at 1d26ef67)
- [ ] Depends on: # (nothing; #7099 is the probe that found it and is merged)
