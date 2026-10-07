<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def two(x = "a" * 2, y = "c" * 2) = [x, y]
xs = []
bad = 0
keep = []
i = 0
while i < 300_000
  v = two(*xs)
  keep << v if i % 7 == 0
  bad += 1 unless v[0] == "aa" && v[1] == "cc"
  i += 1
end
bad2 = 0
keep.each { |v| bad2 += 1 unless v[0] == "aa" && v[1] == "cc" }
p bad, bad2, keep.size            # 0, 0, 42858 in CRuby; 2, 2, 42858 on master
```

`spinel diff` on master: output-diff, `2` and `2` for `0` and `0`; on this branch: same. That is a plain run, gcc and clang alike. Under `SPINEL_GC_STRESS=2` a single `p two(*xs)` aborts ("the mark reached a freed slot") with both.

Cost by callgrind, a million calls: `two(*xs)` above 952,508,873 to 959,580,243 (7 instructions a call); a spread that does reach the parameter (`two(*one)` into `def two(x = "a" * 2, y = 3)`) 145,660,444 to 163,660,445 (18); a spread into parameters whose defaults do not allocate, the same C.

A parameter read out of a spread (a splat's element, the gathered positionals, a `**`'s key) is written where the argument stands, with its default as the other branch: `sp_two((0 < len ? _t2->data[0] : sp_box_str(sp_str_repeat("a", 2))), (1 < len ? _t2->data[1] : sp_box_str(sp_str_repeat("c", 2))))`. A default that allocates is then fresh inside the call's parentheses, where nothing roots it: the other default's allocation collects it, and in `Img.new(*xs)` the object's own allocation does. A default the call leaves out outright is not exposed: `emit_arg_rooted` gives it a rooted temp ahead of the call.

Such a value is now assigned to a rooted temp where it stands (`emit_rooted_conversion`, which a converted bare read uses already), so nothing runs earlier than it did. Only a parameter whose default may allocate and whose type takes a root gets the temp. It is the one layout (`emit_args_filled_argv`), so a top-level method, a class method, `new` and `super(*a)` are cured together; all are in the test. `make cident REF=b4d30a1d3`: 6,368 identical, 6 differ, 0 refusal changes: the new test and five of the corpus's own, each a spread into a parameter whose default allocates.

Not here, the same on master: `Img.new(*xs)` into `def initialize(x = "a" * 2, *r)` (the rest's array, not the default).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
