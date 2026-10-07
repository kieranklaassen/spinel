<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Img
  def both(s, t)
    s << "x"
    t << "y"
    [s, t]
  end
end
class Other
  def both(s, t) = 0
end
y = [Img.new, Other.new][0]
p y.both(+"a", +"b")              # ["ax", "by"]
```

Under `SPINEL_GC_STRESS=2` this dies on master ("fault on the GC mark path": a bus error with gcc, a segfault with clang); on this branch it prints the line. No plain run was found that shows it: six loops of 300,000 such calls answer right on master.

Cost by callgrind, a million such calls: 1,930,505,399 to 1,957,113,603 (27 instructions a call); a call with one such argument, or none, the same C.

A parameter its method appends to takes a handle on the caller's String. Through a dispatch on a receiver of several classes the arm wraps each such argument in a fresh handle inside its call, `sp_Img_both(self, sp_String_new_shared(_t1), sp_String_new_shared(_t2))`, and the second handle's allocation collects the first.

The arm already binds two fresh values to rooted locals ahead of its call (`emit_poly_arm_args`); a fresh handle now counts as one, so two of them, or one beside a default that allocates, are held. An argument that passes its variable's own handle allocates nothing and is as it was. `make cident REF=5390d3002`: 6,353 identical, 5 differ (this test and the four of the pull request below it), 0 refusal changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (the pull request "An omitted *rest is kept alive while a dispatch arm builds the **kwrest", whose function this adds one test to)
