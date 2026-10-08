<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def pick(x)
  return 5 if x == 0
  (x.respond_to?(:zork) ? x.zork : raise(ArgumentError))
end
p pick(0)                # 5
p((pick(1) rescue 7))    # 7
```

This built and printed 5 and 7 until "An untyped conditional a method ends in is unboxed into its return type". Since then the C does not compile: "invalid use of void expression".

That change unboxes an untyped conditional in tail position into the method's return type, since `emit_if_expr` holds such a conditional boxed. It holds it boxed while both arms are emitted. A condition answered at compile time (`respond_to?`, `is_a?`, `block_given?`) leaves the live arm alone, in that arm's own C, and a `raise` there is a void call: there is no box to open.

`emit_tail_value_1` tells such a text already, a few lines below, where it runs the raise and gives the slot its default. That test is now made before the unboxing, and a text that raises takes that path. Every other tail keeps its C.

Not here, each as it was before that change:

- a live arm that is `raise("m")` with the message alone, or a constant defined nowhere, and a conditional in doubled parentheses: that test does not tell their texts, and the C does not compile, as before;
- a method one of whose arms yields: its body is spliced into its callers by another path.

## Measured

On master c594707b, with gcc 13.3 and clang 18.1, plain and at `SPINEL_GC_STRESS=2`.

- A family of 3,240 programs, a conditional neither arm of which has a type at the end of a method (ten arms, six conditions, eight return types; in parentheses, in doubled parentheses, bare, and inside an outer conditional): the C changes for 197 and is byte-equal for the rest. 135 of the 197 built and ran right before that change and do not compile on master: all 135 are right again. 42 more, which did not compile before it either, are right too. The other 20 still do not compile: a `block_given?` whose other arm, a constant defined nowhere, is live at the method's second call. On master 2,152 of the family are right; here 2,329.
- The same conditional at the end of a class method, of an instance method, as the value of a `return`, and at the end of a lambda and of a block (1,080 programs): the C changes for 108, each right before that change and failing to compile on master, each right again. The lambdas and the blocks keep their C.
- `tools/cident.sh` against master: 6484 identical, 1 differ (the new test), 0 refusal changes. `tools/refusals.sh`: 536 records, unchanged. `make reject-test` and `make share-strings-test` pass. The new test is right with gcc and clang at both levels; on master its C fails to compile in eight places, and before that change it was right.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not compared here: the gate compares it)
- [ ] Depends on: #
