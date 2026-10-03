# PR 7255: review finding, rebase and second reading, 2026-10-03

**Final head: 83143a96** on `pr/next-in-run-once-blocks` (was 888719b6, then 8c0fd5dc). Three commits on upstream ba6317b6:

- aa9697da, the first commit rebased from 917dd251. Its only content change is four lines added to `test/collect/refusals.expected`; its message names that file and the new cident and scale-test numbers.
- 8c0fd5dc, the review fix: the retyping moved to the three places where the block is registered as a method.
- 83143a96, added after the second reading, a plain push on top of 8c0fd5dc: it restores the guard for a program that defines its own `define_method` or `define_singleton_method`, and makes the each-unroll retype only once every element has named a method.

## Why a rebase

Master's c517d9ca (22:11 UTC) made `collect-errors-test`, a leg of `make gate`, compare every refusal message of `test/reject/` with the golden file `test/collect/refusals.expected`. This PR adds `test/reject/class_body_block_next.rb`, so 888719b6 merged with master failed that leg (`refusals: FAIL (the refused programs or their messages changed)`) although git merged it cleanly. The golden file does not exist on 917dd251, so the two records could only be added on a newer base. By git, no other open PR adds a program to `test/reject/` or `test/collect/`.

PR 7238 (cd3ddfe2) is unchanged. Merged with ba6317b6 it builds, its test passes plain and under `SPINEL_GC_STRESS=1`, and `collect-errors-test`, `reject-test` and `infer-test` pass.

## The review finding: fixed (8c0fd5dc)

Seven programs with a `define_method` named at run time and a `next value` in its block (the name from a local or a parameter; in a class body, in a class method, in an `each` over a parameter, through `self.class.define_method` and at top level), each on master f672bd97, on 888719b6 and on CRuby 3.3.6: none behaves differently on the branch than on master. Such a call registers no method on either, so its block is never emitted. The finding holds in the analysis: the `return` left in the block was read as the enclosing method's and widened its inferred type (`sp_sym sp_Maker_s_make` became `sp_RbVal`; generated C differed from master's for three of the seven). Two more programs name the methods by an `each` over literals: those are registered, do not build on master and answer as CRuby on the branch.

## The second reading's five points

1. **The reply's first sentence was false** for the each-unrolled names. Reworded to "whose name is only known at run time"; the count of programs is corrected to seven. New text in `review-7255-reply.md`.
2. **Regression confirmed and fixed.** The reader's own program (`r.define_singleton_method(:a) { }` on a `Reg` with that method) does not build at aa9697da, at 8c0fd5dc or on master, for an older reason (`incompatible types when assigning to type 'sp_RbVal' from type 'sp_Reg *'`), and its C is the same at both commits; written inside a method, its C differed by 19 lines. The same shape with a user `define_method`, receiverless in a method of the class, built and answered `[1, :after]` on master and at aa9697da and did not build at 8c0fd5dc (`returning 'long long int' from a function with return type 'sp_PolyArray *'`). 83143a96 restores the guard: `method_body_next_to_return` leaves the body alone when the program has a def by either name, and searches for one only when the body owns a `next`. Ten programs of these shapes compile at 83143a96 to the C aa9697da gave. Test: `test/define_method_user_defined_block_next.rb`, which passes on master, at aa9697da and at 83143a96 and does not build at 8c0fd5dc.
3. **The half-registered each: real, fixed.** `[:a, n].each { |v| define_method("m_#{v}") { next 1 if c; 2 } }` in a class method gave the enclosing method `sp_RbVal` at aa9697da and at 8c0fd5dc, `sp_sym` on master. The unroll now retypes after its loop, when every element has named a method; 83143a96 gives `sp_sym`. Pinned as `mixed` in `test/infer/define_method_runtime_name_next.rb` and in the `infer-test` line.
4. **Test added:** `test/next_in_run_once_block.rb` gains a `next` in each-unrolled methods over Symbol, Integer and String elements (eight more lines of expected output).
5. **The gate block.** This thread cannot read matz/spinel's PR description: the block's lines were written by the Mac from its own run and never passed through here. Its anchor in the description is the heading ``## `make gate` (on this branch merged with current master)`` and the fenced block right under it, which the source text here holds as the placeholder `GATE_LINES`. The Mac replaces that fenced block's content with the lines of its gate on 83143a96.

Checked on 83143a96: `make cident REF=8c0fd5dc` 5685 identical, 1 differ (the new test); 8c0fd5dc against aa9697da 5685 identical, 0 differ; aa9697da against ba6317b6 5680 identical, 5 differ (the new test and the four `RUBY_DESCRIPTION` programs); both tests plain and under `SPINEL_GC_STRESS=1` and `=2`; `gate-props` merged with 6220809b; scale-test 1.74 / 4.82 / 6.29 / 4.24, master's four on the same machine; clean test-merge with master 6220809b, 7238 and 7256. No full `make gate` here.

Found beside it, on master, not built: a local or an inner block's parameter in an each-unrolled `define_method` block that takes a parameter is undeclared in the C (`%w[x y].each { |v| define_method("s_#{v}") { |n| j = n + 1; j.to_s } }`: `'lv_j' undeclared`).

## PR description: exact old and new strings

Old is the description as it was opened; nothing here has been applied yet.

### 1

Old:

```
- `define_method` and `define_singleton_method`: the block is the method's body, so a `next` it owns is retyped as the `return` it means.
```

New:

```
- `define_method` and `define_singleton_method`: where the block is registered as a method it is that method's body, so a `next` it owns is retyped as the `return` it means. A call whose name is only known at run time registers no method and keeps its `next` (`test/infer/define_method_runtime_name_next.rb` pins the enclosing method's type in `infer-test`), and so does every such block in a program that defines a `define_method` or `define_singleton_method` of its own (`test/define_method_user_defined_block_next.rb`).
```

### 2

Old:

```
(`test/reject/class_body_block_next.rb`, registered in `reject-test`).
```

New:

```
(`test/reject/class_body_block_next.rb`, registered in `reject-test`, its message in `test/collect/refusals.expected`).
```

### 3

Old:

```
The two passes run from passes `analyze_program` already calls (`desugar_define_method_proc_arg` and `desugar_instance_eval_builtin`), so that function does not grow, and nothing in `emit_call_body` or `emit_stmt_inner` changes.
```

New:

```
The `then` and `to_h` rewrites and the refusal run from `desugar_instance_eval_builtin`, which `analyze_program` already calls, and the `define_method` retyping runs where the block is registered (`walk_scope`, `collect_dm_each_unroll`, `desugar_define_method_keywords`), so `analyze_program` does not grow, and nothing in `emit_call_body` or `emit_stmt_inner` changes.
```

### 4

Old:

```
`make cident REF=917dd251`, with optcarrot in the corpus: 5677 identical, 5 differ, 0 refusal changes. The five are the new test and the four programs that print `RUBY_DESCRIPTION`, which names the compiler's own commit (`frozen_chilled_builtin_strings`, `object_scoped_ruby_constants`, `ruby_description_shape`, `symbol_id2name_ruby_desc_minmax`); before the commit was made, against f672bd97, it was 5681 identical and the new test. optcarrot's C is byte for byte the same, 12,255 lines. `reject-test` and the gate's property checks pass here (scale-test 1.74 / 4.82 / 6.31 / 4.25); the full `make gate` is below.
```

New:

```
`make cident REF=ba6317b6`, with optcarrot in the corpus: 5680 identical, 5 differ, 0 refusal changes. The five are the new test and the four programs that print `RUBY_DESCRIPTION`, which names the compiler's own commit (`frozen_chilled_builtin_strings`, `object_scoped_ruby_constants`, `ruby_description_shape`, `symbol_id2name_ruby_desc_minmax`). The second commit against the first: 5685 identical, 0 differ. The third against the second: 5685 identical, 1 differ, the new `test/define_method_user_defined_block_next.rb`, which the second commit does not build. optcarrot's C is byte for byte the same, 12,255 lines. `reject-test` and the gate's property checks pass here, on the branch and merged with 6220809b (scale-test 1.74 / 4.82 / 6.29 / 4.24, master's four); the full `make gate` is below.
```

### 5

Old:

```
with an `ensure`, and in `class << self`; `define_singleton_method`; and `Struct#to_h` and `Data#to_h`
```

New:

```
with an `ensure`, and in `class << self`; `define_singleton_method`; the methods an `each` over literals names; and `Struct#to_h` and `Data#to_h`
```

### 6, the gate block

The fenced block under ``## `make gate` (on this branch merged with current master)``: the Mac's own lines from the old head, to be replaced by the lines of its gate on 83143a96.
