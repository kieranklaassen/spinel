<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class K
  def two(a, b) = a.size + b.size + a.getbyte(0)
end
def mk(x) = x + "a"
k = K.new
s = +"base"
t = s
t << "a"
w = "x"
bad = 0
i = 0
while i < 200_000
  bad += 1 unless k.two(s, mk(w)) == 105
  i += 1
end
p bad
```

prints 22 in a plain run, built with gcc or with clang; CRuby prints 0. `s` has a second name that appends to it, so it lives in a shared slot and a read of it is a fresh copy. A call on an object binds each argument to a temp, and since "Root no argument temp copied from a local its statement cannot rebind" the temp of a local's read has no root, the local holding the value. The local does not hold this copy, nothing does, and `mk(w)` collects it. Before that commit the program printed 0.

It costs the root that was missing: 11 instructions a call here (callgrind, 200,000 calls: 170,263,852 to 172,475,562), 15 where the callee has a rest parameter, 30 where two copies are passed. A call with one such read and nothing else made among its arguments emits the C it did.

- `emit_dispatch`: the temp is rooted again where the read is such a copy and a later argument can allocate.
- A call whose arguments stand in the C argument list (`emit_arg_rooted`), older than that commit: `two(s, u)` with two such Strings makes both copies there, C does not say which first, and the second's allocation collects the first (1 wrong of 60,000 in a plain run); the same beside an argument that makes a String in the list, `three(s, mk(w).size, u)`. The copy is bound to a rooted temp where it stands (`emit_rooted_conversion`), so the arguments run in the order they ran in. Bundled Pathname has such a call, `dir_form_p(o, joined)`, under `--share-strings`.
- The Array a rest parameter receives is built in that list too: `rest(s, 1, 2)` is right built with gcc and aborts built with clang under `SPINEL_GC_STRESS=2`.

Not changed: `s + u` itself, and a method that takes both Strings as handles and sums them; a builtin method given such a String beside a value made in place (`delete`, `squeeze`, `partition`, `sub`, `gsub`, `tr`, `center`, `ljust`, `split`, a Hash literal's key and value); Struct and Data members; `<`, `between?` and `case`/`when` on two copies.

The test is in `GC_STRESS_TESTS`. On master its last line is wrong in a plain run and it aborts under `SPINEL_GC_STRESS=2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
