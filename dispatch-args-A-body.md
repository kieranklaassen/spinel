<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Img
  def two(x = "a" * 2, y = "c" * 2) = [x, y]
end
class Other
  def two = 0
end
y = [Img.new, Other.new][0]
bad = 0
keep = []
i = 0
while i < 300_000
  v = y.two
  keep << v if i % 7 == 0
  bad += 1 unless v[0] == "aa" && v[1] == "cc"
  i += 1
end
bad2 = 0
keep.each { |v| bad2 += 1 unless v[0] == "aa" && v[1] == "cc" }
p bad, bad2, keep.size            # 0, 0, 42858 in CRuby; 0, 1, 42858 on master
```

`spinel diff` on master: output-diff, `1` for `0`; on this branch: same. That is a plain run, gcc and clang alike. Under `SPINEL_GC_STRESS=2` a single `y.two` aborts ("the mark reached a freed slot"), and so do three tests of the corpus: `test/poly_dispatch_empty_kwrest.rb`, `test/opt_before_required_kwrest.rb` and `test/poly_splat_anonymous_rest.rb`.

Cost by callgrind, a million calls: `def b(*r, **o)` called with nothing 837,928,269 to 878,274,939 (40 instructions a call), two allocating defaults 851,566,425 to 880,633,500 (29); a call with one omitted rest, or with defaults that allocate nothing, the same C.

Through a dispatch on a receiver of several classes, a parameter the call leaves out has its value spelled in the arm's call: `sp_Img_two(self, sp_str_repeat(...), sp_str_repeat(...))`, or `sp_Img_b(self, sp_PolyArray_new(), sp_SymPolyHash_new())` for `def b(*r, **o)`. Nothing roots it there, so of two such values the one C builds second collects the first. The empty Hash of an omitted `**kwrest` came with cbc44cb5b (an omitted **kwrest is an empty Hash through a dispatch on several classes); its test is the first of the three above.

The cure is master's own: the arm that is given arguments already binds two fresh values to rooted locals ahead of its call (`emit_poly_arm_args`), but counted only a value built in a statement expression. Its test for "fresh" is widened, one cause a commit:

1. an omitted `*rest` and an omitted `**kwrest`, in the arm that is given no argument (`emit_poly_user_arm0`), which bound nothing;
2. an omitted parameter's default that allocates (`"a" * 2`, `{}`, `Other.new`, a keyword's default), in both arms, also where a splat or a `**` may leave the parameter out.

With clang only, `(x = "a" * 2, *r)` and `(x = "a" * 2, **o)` abort on master at stress 2; gcc runs them in the order that survives. Both are in the test and right with both compilers here. `make cident REF=5390d3002`: 6,353 identical, 4 differ (the new test and those three), 0 refusal changes.

Not here, the same on master: `Img.new` with such parameters (the constructor's own call), and a class method through a class value.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
