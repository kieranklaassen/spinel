<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
t = "o"
case [[:q, :r], 9]
in [[_, *, t], _]
  p t        # :r
end
```

Before: exit 139, nothing printed. `[[t, _], _]` there printed nil, and so did `[*, [t, _], *]` over `[9, [:x, :y], 8]`. `n = 0` printed 0 for the `"b"` of `[["a", "b"], 9]` and for the `"v"` of `[[{k: "v"}], 9]`. A Symbol local printed `:""` for a Float, a Float local raised `can't convert Symbol into Float (TypeError)`, and `r = "o"` bound by the rest of `[[_, *r], _]` printed six bytes of memory as a String.

After: `:r`, `:q`, `:x`, `"b"`, `"v"`, the Float, the Symbol and `[2, 3]`.

Cost: where the value is of the class the local already held (`t = "o"` taking the `"s"` of `[[1, "s"], 9]`) the program was right with a typed local and is right with a boxed one, and pays a boxed comparison for a typed one. Ten million `t == "s"` take 0.097 s where they took 0.007 (a Symbol 0.058 for 0.006, a Float 0.067 for 0.005, an Integer 0.009 for 0.005, `nil?` the same), whether the arm matched or not. No program that was right changes its answer in the families below.

Stacked: one commit above a479e18d0039, "A target after an Array pattern's splat binds an assigned local to an element of any class", which stands on d08bdb794b24, "An Array pattern binds an assigned local to an element of another class". Each is the same commit in its own pull request.

What a nested pattern binds arrives boxed. Master boxes the locals of a Hash or find pattern that is a required element, and of a pattern under a Hash pattern's key (`pm_seed_locals_poly`), and leaves the rest alone: a nested Array pattern, any pattern after the splat, a Hash pattern inside either. A local there that an assignment also writes kept the assignment's type, and the value was unboxed as that (`emit_pm_typed_assign`), whatever its class. The first commit of this stack walks those patterns too, and boxes only the target of a capture that names another class (`[[Symbol => t, _], _]`).

Chosen: a bare target there boxes the local, under the list that commit brought (`pm_uses`, `pm_local_assigned`). Every assignment to the local is a statement `x = literal`, and every other use prints it, interpolates it or compares it with a literal, so the boxed value goes nowhere else. A local with any other use is typed as it was and writes the same C. A capture's target is decided by the capture, as before.

Rejected: keeping the local typed where the value's class may be its own. What a nested pattern binds arrives boxed whatever the subject's type, so nothing at the binding says which class arrives, and a typed slot can hold only one.

Not here, and unchanged:

- a local with a use off the list: with `p [t]` after the pattern above, the program still exits 139;
- the first name of an `a => x`, at any depth: `[t => x, _]` and `[[t => x, _], _]` bind `x` and leave `t` as it was, with or without an assignment, where Ruby binds both. `pm_seed_capture_value` keeps that name out of this change, and 770 such programs (7 kinds of local, 5 kinds of value, 11 positions, at the top level and in a method) write master's C;
- a lambda that reads a local a nested pattern binds does not build (`lv_t undeclared`): 990 programs of the family below, before and after.

Measured, against the commit below (on every program that changes here, that commit writes master's C):

- The list is the first commit's, drawn on master on a local it boxes already: 5,616 generated programs, each listed use by each way of printing it by up to 21 kinds of value.
- The cure: 4,800 generated programs (10 kinds of local, 10 kinds of value, 12 patterns, 4 kinds of body), of which 3,960 change. 663 were right and stay right, 2,307 become right (714 crashed, 252 raised, 1,341 printed something else), and the 990 with a lambda do not build before or after. A sample of 371 was also run with clang, with `--int-overflow=promote` and at `SPINEL_GC_STRESS=1` and `2`: 371 right each way.
- The value of the local's own class: 1,199 programs take it out of a nested Array and then change it through another name (`e << "x"`, `a[0][1] << "y"`, `e.replace("n")`, `e.push(4)`, `e[:b] = 2`), and the local must show the change. All were right and stay right. With `--share-strings` 1,167 were right and stay right, and 32 crashed and are right.
- A subject whose type settles late (a method defined below, an instance variable, a constant, an empty Array that is filled, a Hash's value, a parameter, a block's parameter): 210 programs; 70 were right and stay right, 140 become right.
- Off the list: 23,394 programs with one more use after the pattern (280 uses, 7 kinds of local, 6 patterns, at the top level and in a method). 21,450 write master's C and 1,476 are refused by both. 468 differ, by eight uses that are other spellings of listed ones (`t.send(:class)`, `x = "#{t}"`, `Kernel.puts t`, `p(*[t])`, `5 => t`, a second literal assigned, a block-local of the same name); 220 of those were right and stay right, 248 become right.
- Counted on master 26d456ec1035. `make cident REF=a479e18d0039`: `6353 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`; the one that differs is the new test.
- `test/array_pattern_target_nested.rb`: master prints seven wrong lines of it and exits 139. With the change it prints its `.expected` with gcc and clang, with `--int-overflow=promote`, and under `SPINEL_GC_STRESS=1` and `2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
