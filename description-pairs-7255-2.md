# PR 7255: second review finding (the guard's reach), 2026-10-03

**Final head: 75c390c2** on `pr/next-in-run-once-blocks`, a plain push of one added commit on cb180793. Five commits on upstream ba6317b6: aa9697da, 8c0fd5dc, 83143a96, cb180793, 75c390c2. `git diff 83143a96 75c390c2` is the test file and its expected output only: the compiler's sources are 83143a96's, the head the Mac's gate passed.

## Outcome: the finding is declined, with the reason in the description

CodeRabbit, src/analyze_desugar.c:6740, "Restrict the override check to the affected method call". Its program reproduces and is not a regression: with an unrelated class defining `define_method`, a `next` in another class's `define_method` block does not build, on master and at every head of this PR but cb180793.

cb180793 tried the scoping it asks for. The coordinator's second reading found by reading that the rule could miss a def, and the builds confirm it. 75c390c2 takes the scoping back.

## The eight programs, per build (CRuby 3.3.6 beside them)

| | CRuby | master | 83143a96 | cb180793 | 75c390c2 |
|---|---|---|---|---|---|
| p1 def in `class K`, `K = Reg` | `[[:a, 1], :after]` | same | same | **does not build** | same as CRuby |
| p2 `class A < K`, `K = Reg` | `[:a, 1]`, `:k` | NameError `A::X` | NameError | NameError | NameError |
| p3 `o.instance_eval { define_method }` in A | `[[:a, 1], :after]` | same | same | **does not build** | same as CRuby |
| p4 `Reg.class_eval do ... end` in A | `[[:a, 1], :after]` | refused | refused | refused | refused |
| p5 call in `Object#helper`, run on a Reg | `[[:x, 1], :after]` | same | same | **builds, SIGSEGV at run time** | same as CRuby |
| p6 the same in `module Kernel` | `[[:x, 1], :after]` | refused | refused | refused | refused |
| p7 own `define_singleton_method`, `define_method` block with next | `1`, `2`, `[:s, 3]` | does not build | does not build | as CRuby | does not build |
| p8 two `Mid` classes | `[:a, 1]` | same | same | same (C equal to 83143a96's) | same |

"does not build" at cb180793 is `returning 'long long int' from a function with return type 'sp_PolyArray *'`; on master and 83143a96 for p7 it is `continue statement not within a loop`. "refused" is `unsupported call: ... (CallNode define_method)`. master here is ba6317b6 with 7238's codegen commit merged, which the analysis does not see.

So F1 (p1), F2 (p3) and F3 (p5) are real regressions of cb180793; p2, p4, p6 behave the same on all builds; F4 (p8) did not show, the two classes' names being told apart before the walk.

## Why back, and not forward

Closing F1 to F4 one by one means treating a class name that is also assigned as unplaceable, counting the blocks between a call and its class statement, treating builtin classes as reaching everything and refusing a name with two superclasses, all to read off the syntax what the class table would say, and that table is still being filled where the rewrite runs. The gain is a program in which one class defines its own `define_method` while another uses `next` in a `define_method` block. The whole-program check is the first commit's, is small, and cannot miss a def. p7 is what it costs.

## Checked on 75c390c2

- `test/define_method_user_defined_block_next.rb` is 83143a96's plus p1, p3 and p5 (as Late, Away and Object#helper). It passes on master, at 83143a96 and at 75c390c2, plain and under `SPINEL_GC_STRESS=1` and `=2`, and does not build at cb180793.
- `test/next_in_run_once_block.rb` plain and under stress; `infer-test`, `reject-test`, `collect-errors-test` on the branch; `gate-props` merged with master 6535952f (scale-test 1.74 / 4.82 / 6.29 / 4.24); clean test-merge with master 6535952f, 7238 and 7256. No `test/reject` program and no `spinel:` message changed. No full `make gate` here; no cident run, the sources being 83143a96's.

Older and unowned, seen on the way: a receiverless `define_singleton_method` inside an instance method registers a class method (the object then has no such method, with or without a `next`); a receiverless `define_method` in `Base#run` called on a `Sub` with its own `define_method` answers `[nil, :after]` on master.

## Reply for the review thread at src/analyze_desugar.c:6740

`review-7255-reply-2.md`, byte for byte.

## PR description: exact old and new strings

Old is the description as it stands on GitHub (the five pairs of `review-7255.md` applied, with the Mac's gate lines). The three pairs written for cb180793 were never applied and are withdrawn.

### 1

Old:

```
The third against the second: 5685 identical, 1 differ, the new `test/define_method_user_defined_block_next.rb`, which the second commit does not build. optcarrot's C is byte for byte the same, 12,255 lines. `reject-test` and the gate's property checks pass here, on the branch and merged with 6220809b
```

New:

```
The third against the second: 5685 identical, 1 differ, the new `test/define_method_user_defined_block_next.rb`, which the second commit does not build. The fourth commit read off the `class` statements which class such a def reaches, and the fifth takes that back and adds the three programs it broke to that test; the compiler's sources at the head are the third commit's. optcarrot's C is byte for byte the same, 12,255 lines. `reject-test` and the gate's property checks pass here, on the branch and merged with 6535952f
```

### 2

Old:

```
Left as they were: such a block written with numbered parameters or `it`, one with a `break` or `redo` beside the `next`, any in a program that defines its own `then`, and a `next` whose value `then` cannot join with the block's last one (a String and an Array).
```

New:

```
Left as they were: such a block written with numbered parameters or `it`, one with a `break` or `redo` beside the `next`, any in a program that defines its own `then`, a `next` whose value `then` cannot join with the block's last one (a String and an Array), and a `define_method` or `define_singleton_method` block's `next` in a program that defines a method of either name anywhere: the block is left as it is whichever class it stands in, and where it is compiled as a method's body the `next` does not build, as on master.
```

### 3, the gate block

The fenced block under ``## `make gate` (on this branch merged with current master)``: the Mac's lines for 83143a96, to be replaced by the lines of its gate on 75c390c2.
