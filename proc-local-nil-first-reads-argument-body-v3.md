<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
h = nil
h = ->(x) { x * 2 }
p h.call(1.5)
```

```
spinel diff: output-diff
  program: nil_first.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-3.0
+0
```

With `->(s) { s.length }` called on `"wxyz"` it raises NoMethodError for an Integer. The same literal in a local written once is right.

A local that holds nil as well as the proc is a boxed slot, and the site loop of `infer_block_params` types a literal's parameters only for a receiver it knows as a Proc. The parameters kept the Integer default and read the argument's word through it.

The loop takes such a local now, and `cs_type_proc_site` an arm of a conditional the local is written with (`f = on ? ->(s) { ... } : nil`), where two things hold:

- The proc stays with its name. Every read of the local is the receiver of `call`, `()`, `yield`, `===`, `nil?` or `!`, or a condition, and no write of it is the value of something else. The calls through the name are then all the calls there are.
- Those calls agree. Each hands the same number of plain arguments, one to four, each of one typed kind that is the same at every call, and not all Integers.

The second is asked once, when the inference has settled as it does today (`proc_locals_open`). A program with no such local, or whose calls do not agree, is typed as before, in the rounds it took before. A cured one takes two rounds more.

A parameter is never boxed by this. A callback handed Integers, a boxed value, its own result (`t = f.call(t)`) or two kinds keeps the C it had.

Not in this change:

- `cb = nil; cb = proc { |e| p e }; cb&.call(2**70); cb&.call(7)`: two kinds, so the first line still prints the Bignum's address.
- A proc copied to a second local (`q = pr; q.call("eight!")`), stored, answered or handed to a method.
- `f[x]`, which on a boxed receiver is an index.

The guard walks its own parent map from the program's root. The rewrite of `g = (f = x)` points g's write at f's and leaves the parentheses behind, still naming f's write, and `an_parent_map`, which takes the last node that names a child, answered with them: f's write looked like a statement.

On master a2bd8900: `make cident` reports 6,375 identical, 1 differ (the new test); `make infer-test` passes. The new test passes plain and under `SPINEL_GC_STRESS=1` and `2`; on master it raises at its first line.

Generated programs, run on master b4d30a1d and this above it: 5,391 in nine sets (a callback handed Integers, a boxed value, its own result or two kinds; a parameter called by every method of its class by three roads; and one typed kind of argument by the calls on the parameter by six ways of writing the local). 2,099 get master's C, 16 are refused or do not build on both, and 3,276 get other C. Those 3,276 were run plain and under both stress modes. The 1,050 that are right on master are right here. Of the 2,226 that are wrong or raise on master, 2,188 are right here and 38 are not, each as the same literal in a local written once is on master: 15 print an object and differ from CRuby by its address alone, 10 answer `true` for `2.5.respond_to?(:size)`, 12 make a Symbol at run time (`s.upcase`, `s.succ` on a Symbol), which is right plain and under mode 1 and loses its name under `SPINEL_GC_STRESS=2`, and one interpolates a proc.

Test: `test/proc_local_holds_nil.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
