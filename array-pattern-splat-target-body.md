<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
t = "o"
case [:q, :r]
in [_, *, t]
  p t        # :r
end
```

Before: exit 139, nothing printed. Over `[[1], [2]]` the same local printed six bytes of memory as a String, over `[true, false]` nil, over `[{a: 1}, {b: 2}]` `""`. `n = 0` printed 6 for the Symbol and 0 for the `"s"` of `[1, "s"]`. A Float local raised `can't convert Symbol into Float (TypeError)`.

After: `:r`, `[2]`, `false`, the Hash, `:r`, `"s"` and `:r`.

Cost: where the element is of the class the local already held (`t = "o"` taking the `"s"` of `[1, "s"]`) the program was right with a typed local and is right with a boxed one, and pays a boxed comparison for a typed one. Ten million `t == "s"` take 0.097 s where they took 0.007 (a Symbol 0.058 for 0.006, a Float 0.069 for 0.005, an Integer 0.009 for 0.006, `nil?` the same), whether the arm matched or not. No program that was right changes its answer in the families below.

Stacked: one commit above d08bdb794b24, "An Array pattern binds an assigned local to an element of another class", which is the same commit in its own pull request.

That commit boxes an assigned local where the element is surely of another class, which a capture (`Integer => t`) or an Array of Integers, of Floats or of Strings can say. An Array of Symbols, of `true` and `false`, of Arrays, of Hashes, of objects or of a mix is a boxed Array: its type tells no class for an element. A bare target after the splat over such an Array has neither, so the local kept the type its assignment gave it and the element was unboxed as that (`emit_pm_typed_assign`), whatever its class.

Chosen: such a target boxes the local, under the list that commit brought (`pm_uses`, `pm_local_assigned`). Every assignment to the local is a statement `x = literal`, and every other use prints it, interpolates it or compares it with a literal, so the boxed value goes nowhere else. A local with any other use is typed as it was and writes the same C.

Rejected: reading the element at the local's type where the class may be the same, as before. Nothing at the binding says which class arrives, and a typed slot can hold only one.

Not here, and unchanged:

- the same bare target inside a nested Array pattern (`[[t, _], _]`, `[*, [*, t]]`): `pm_seed_locals_poly` leaves it at the assignment's type and it fails the same way. Of 340 such programs 28 crash, 46 raise and 146 print something else, before and after. It is one line there under the same list, and the next commit;
- a local with a use off the list: with `p [t]` after the pattern above, the program still exits 139;
- a lambda that reads a local an Array pattern binds does not build (`lv_t undeclared`), whatever the pattern: 1,020 programs of the family below, before and after.

Measured, against the commit below (on every program that changes here, that commit writes master's C):

- The list is that commit's, drawn on master on a local it boxes already: 5,616 generated programs, each listed use by each way of printing it by up to 21 kinds of value.
- The cure: 6,552 generated programs (13 kinds of local, 21 subjects, 6 patterns, 4 kinds of body), of which 4,320 change. 996 were right and stay right, 2,304 become right (482 crashed, 351 raised, 1,471 printed something else), and the 1,020 with a lambda do not build before or after. A sample of 413 was also run with clang, with `--int-overflow=promote` and at `SPINEL_GC_STRESS=1` and `2`: 413 right each way.
- The element of the local's own class: 1,068 programs take it out of a mix and then change it through another name (`e << "x"`, `a[1] << "y"`, `e.replace("n")`, `e.push(4)`, `e[:b] = 2`), and the local must show the change. 1,044 were right and stay right; 24 crashed and are right. The same with `--share-strings`.
- A subject whose type settles late (a method defined below, an instance variable, a constant, an empty Array that is filled, a Hash's value, a parameter, a block's parameter): 132 programs, of which 84 change; 28 were right and stay right, 56 become right. Where the Array's type tells Integers or Strings in the end, the C is the parent's.
- Arrays of Integer Arrays and of Float Arrays (`Array.new(2) { Array.new(2, 0) }`) and of one class's objects, which are boxed Arrays as a pattern's subject: 360 programs, of which 324 change; 128 were right and stay right, 196 become right.
- Off the list: 23,394 programs with one more use after the pattern (280 uses, 7 kinds of local, 6 shapes, at the top level and in a method). 21,450 write master's C and 1,476 are refused by both. 468 differ, by eight uses that are other spellings of listed ones (`t.send(:class)`, `x = "#{t}"`, `Kernel.puts t`, `p(*[t])`, `5 => t`, a second literal assigned, a block-local of the same name); 220 of those were right and stay right, 248 become right.
- Counted on master 26d456ec1035. `make cident REF=d08bdb794b24`: `6352 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`; the one that differs is the new test.
- `test/array_pattern_target_after_splat.rb`: master exits 139 on it with nothing printed. With the change it prints its `.expected` with gcc and clang, with `--int-overflow=promote`, and under `SPINEL_GC_STRESS=1` and `2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
