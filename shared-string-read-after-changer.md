<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A plain run, no flag:

```ruby
s = +"hello"
t = s
p s.sub(s << "l", "L")          # CRuby "L"; Spinel built with clang "hello"
p(s == t << "l")                # CRuby true; Spinel false, with gcc and with clang
u = +"ab"
v = u
p u.end_with?(v << "c" * 4000)  # CRuby true; Spinel built with clang segfaults
```

A String that two names share is read where the read stands in the C call, as a copy of the bytes it holds then or as a pointer into its buffer. C leaves the order of a call's operands open. Beside an argument that changes a shared String in place, the read ran first wherever the compiler put it first: the copy held the old bytes, and the pointer was left behind when the append grew the buffer. Ruby reads the receiver when the method runs, after its arguments.

`emit_operands_in_order` already binds a call's one running operand ahead of an operand made where it stands. The read of a shared String now counts as such an operand, so the argument is bound first and the read comes after it.

It applies only where all of this holds, and every other call keeps its C:

- an operand of the call is the plain read of a shared String slot, a local or an instance variable held as a String handle, and no enclosing emitter has read it into a temp already;
- an operand of the call holds a String mutator (`an_str_mutator_name`) whose receiver is a shared String slot. Two slots can hold one String, so any of them counts;
- for a slot in an instance variable, that operand is the mutator alone, over values whose builtins run no code of the program's (the test `subtree_may_run_proc` makes of a call, with a plain field read let through): it can assign no variable, so the slot holds the same String after it. A local is asked what the function asks already (`operand_local_rebound_by`);
- the call that was emitted reads the slot's bytes (`sp_String_cstr` on the slot, in the copy and in the pointer). An arm that takes the String by its handle reads it when it runs (`s.concat(t << "l")`), and the rewrite is dropped as before.

It costs one rooted temp on a call it binds, 10 to 18 instructions. Seven loops of 200,000 such calls that ran right, with gcc and with clang, take 0.7% to 7.1% more instructions under callgrind (`s.start_with?(t.replace("hello"))` 31,063,933 to 33,263,919 with gcc; `s.tr(v.replace("abc"), u)` 365,467,856 to 368,271,810). They ran right for as long as the mutator left the buffer where it was, or by the data. No list tells two handles apart, so no narrower test cuts it. The compiler itself runs 0.02% and 0.10% more instructions on two of the benchmarks.

Not here, each as on master:

- the mutator in parentheses (`s.sub((s << "l"), "L")`), under `||` (`s.sub(s.upcase! || "x", "L")`), in a call with a block or a `&.`, or inside a method the operand calls;
- an operand that assigns the variable (`s.sub(s = u.concat("l"), "L")`);
- on an instance variable: a mutator in a conditional or with an argument that runs code of the program's; `+`, `==`, `!=`, `eql?` and `<=>` (`@s == @s << "l"`: `recv_read_before_args` reads the receiver ahead of the arguments, as a copy); and a call with no receiver (`format`, a method of the program), whose arguments another emitter binds in the order written;
- two shared Strings read in one call (`s.sub(t << "l", s)` is now right on a plain run; under `SPINEL_GC_STRESS=2` neither copy is held while the other is made, as before).

## Measured

On the piece this depends on, with gcc and with clang, plain and at `SPINEL_GC_STRESS=2`.

- 1,180 generated programs: 33 calls that read a shared String, 9 ways an operand changes one in place, through a second name, the same name, one instance variable or two. Before, 587 answer as CRuby does with both compilers at both levels; with this, 997. Built with clang, a plain run of 533 prints other content and 32 segfault; with this 183 and none. Built with gcc, 201 print other content; with this 129. At `SPINEL_GC_STRESS=2`, 40 (gcc) and 156 (clang) abort or crash; with this none. No program that is right in a cell is anything else with this, and no crash becomes a wrong answer.
- The 183 left are the cases under "Not here": 57 have the mutator's receiver in parentheses, 25 the mutator in a conditional on an instance variable, and 101 are on an instance variable through `==`, `!=`, `eql?`, `<=>`, `+`, `format`, a method of the program or an Array literal.
- 113 hand-written programs around the edges (a rebinding operand, a lambda that assigns the name, two reads, a reader's field, blocks, `&.`): 235 of their 452 runs are right before and 331 with this; none that is right before is anything else.
- `tools/cident.sh` against the piece this depends on: 6449 identical, 1 differ (the new test), 0 refusal changes. `tools/refusals.sh`: 536 records, unchanged. `make reject-test`, `make share-strings-test` and `make gc-stress-test` pass. The new test is right with gcc and clang at both levels; before, 3 of its 11 lines are wrong with gcc, and with clang 6 of the 8 it prints are wrong and it segfaults.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not compared here: the gate compares it)
- [ ] Depends on: # ("An interpolated String operand is made in the order written and held")
