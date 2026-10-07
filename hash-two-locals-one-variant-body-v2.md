<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Hash filled through a second local lost the entries under its first name. The cure has two costs.

In instructions (callgrind): the names of such a Hash take the poly-keyed variant, where `h["b"]` is 196 instructions a loop turn against 97 on the String-keyed one, a store 225 against 104 and `fetch` 379 against 179 (a walk of eight entries is 340 against 751). Where one of the names is also handed to a method that another call hands a Hash of one kind, the parameter is boxed for both callers, as master boxes any parameter given two kinds: a walk of eight entries in the method goes from 538 to 3,656 instructions a call, a lookup from 86 to 130. A program pays only where master writes its `g = h` as a converting copy.

In a program that raises: where master raises, as CRuby does, because the Hash's values do not take a method or cannot be its argument, the values are boxed now and the program answers as master answers for any boxed value. Of 417 such uses tried, six that master raises in or refuses print a line here: `v.even?`, `v.odd?`, `~v` and `v / 2` on a String (true, false, -1 and 0), `[7, 8].join(v)` and `v.gsub(/x/, "y")` on an Integer ("718" and "1"). On master `x = [1, "x"]; s = x[1]; p s.even?` prints true.

```ruby
h = {a: 1}
g = h
m = {1 => :a}
g.merge!(m)
p h.to_a
```

```
spinel diff: output-diff
  program: two_names.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[[:a, 1], [1, :a]]
+[[:a, 1]]
```

The argument widened `g` to the poly-keyed variant while `h` kept its literal's, so `g = h` was written as a conversion, which builds another Hash, and what went in through `g` never reached `h`. The same entries were lost the other way round (`h.merge!(m)`, read through `g`), and with `update`, `replace`, `store`, an index store and a store in a block.

The alias loop in `infer_write_types` already gives an Array under two names the boxed kind on both. A Hash now takes the poly-keyed variant under every name it goes by and keeps it: the literal is marked for it and the slots are pinned, as `widen_arg_hash` does for a caller's local. It does so where each local is written once, with a literal, `Hash.new` or another such local.

What was chosen:

- The names of one Hash are a group, joined whole or not at all. Master writes `g = h` as a conversion only into a variant with boxed values. A Hash of another kind written into any other variant is refused when the C is written, the literal's own write among them (`h = {1 => 1}; g = h; h[2] = "s"`, or `h = {a: 1}; g = h; m = {"k" => 2}; g.merge!(m)`). A group with such a write is left alone and stays refused: joined, the program would build and run on into whatever came after the refusal.
- A program is left alone where master refuses or raises for a value's kind and would not for the same value boxed, as far as the analysis sees it: an `op=` whose operand is of another kind than its slot (`t = 0; h.each { |_k, v| t += v }` over String values; a local, a global, an attribute or an Array's element), and a Range between two kinds (`(1..v)`). Given a boxed operand master's `op=` adds whatever number or text it reads as, and a boxed String bound of a Range counts as 0: joined, the program would build and print a sum.
- Two String-keyed names given a value of another kind take the poly-keyed variant too, not the String-keyed one with boxed values. Nothing pins that variant across rounds, and derived again each round it came after the round's writes were typed.
- A group is joined on kinds each of its names had last round too. A second name is typed from the first before the first's own stores widen it, so it runs a round behind and often reaches the same kind by itself. A changed program takes at most two rounds more.

Not in this change, and as before:

- The refused groups and the programs left alone above.
- A local written twice, a conditional (`g = c ? h : k`), a parameter, and a Hash that came from a call, an instance variable, a global, a constant or an element: still a converting copy.

Measured on master 5a752fce above the four pull requests below, and replayed on 9274c732 (the test in three modes, `make cident`, `make infer-test`). CRuby 3.3.6 is the reference, and every program is run plain and under `SPINEL_GC_STRESS=1` and `2`. Of 15,676 generated programs of one Hash under two names, 8,647 compile to the C they did or are refused as they were. Of the 7,029 others:

- 6,857 are right in all three modes, 529 of them programs master refuses.
- None that is right on master is wrong, refused or not building here, and none that master refuses or raises in prints a wrong line in a plain run.
- 86 are right plain and under stress 1 and wrong or aborting under stress 2, through two faults master has for any boxed value: `sort_by` with a block over a Hash of boxed values, and a Symbol made at run time (`:v.succ`).
- 86 are wrong in every mode, as they are on master.

Test: `test/hash_local_alias_widened.rb`. Master builds it and prints 22 of its 26 lines wrong.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: the pull requests "A Hash parameter given two kinds of value is not typed from its body", "A Hash walk whose block deletes the current entry goes on from the next", "Hash[h] answers a new Hash" and "A receiver made by a call is held while `* n`, invert, compact and flatten build the answer"
