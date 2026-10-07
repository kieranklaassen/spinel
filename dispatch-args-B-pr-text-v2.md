<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Img
  def m(s, t, k: "a" * 2)
    s << "x"
    t << "y"
    [s, t, k]
  end
end
class Other
  def m(s, t, k: 1) = []
end
y = [Img.new, Other.new][0]
keep = []
bad = 0
i = 0
while i < 300_000
  r = y.m(+"a", +"b")
  keep << [r, i] if i % 7 == 0
  bad += 1 unless r == ["ax", "by", "aa"]
  i += 1
end
bad2 = 0
keep.each { |r, i| bad2 += 1 unless r == ["ax", "by", "aa"] }
p bad, bad2, keep.size            # 0, 0, 42858 in CRuby; 1, 2, 42858 on master
```

`spinel diff` on master: output-diff, `1` and `2` for `0` and `0`; on this branch: same. That is a plain run with gcc; built with clang this loop answers right on master. Under `SPINEL_GC_STRESS=2` one `p y.both(+"a", +"b")` into `def both(s, t)` that appends to both dies on master with either compiler ("fault on the GC mark path": a bus error with gcc, a segfault with clang); on this branch it prints `["ax", "by"]`.

Cost by callgrind, a million `y.both(+"a", +"b")`: 1,930,508,221 to 1,957,901,889 (27 instructions a call); a call with one such argument, or none, the same C.

A parameter its method appends to takes a handle on the caller's String. Through a dispatch on a receiver of several classes the arm wraps each such argument in a fresh handle inside its call, `sp_Img_both(self, sp_String_new_shared(_t1), sp_String_new_shared(_t2))`, and the second handle's allocation collects the first.

The arm already binds two fresh values to rooted locals ahead of its call (`emit_poly_arm_args`); a fresh handle now counts as one, so two of them, or one beside a default that allocates, are held. An argument that passes its variable's own handle allocates nothing and is as it was. `make cident` against the pull request below: this test differs, nothing else.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (the pull request "An omitted *rest is kept alive while a dispatch arm builds the **kwrest", whose function this adds one test to)
