<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A Regexp given to `any?`, `all?`, `none?` or `one?` over boxed elements matches a Symbol by its
name and a String that has grown by its contents, as `Regexp#===` does. Only a plain String
matched, and `when *patterns` over a held Array asks the same test:

```ruby
p [:a1, :b].any?(/\d/)
s = +"a"
s << "1"
p [s, 3].any?(/\d/)
pats = [/\d/, 3]
y = :a1
p(case y when *pats then :hit else :miss end)
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,3 @@
-true
-true
-:hit
+false
+false
+:miss
```

In `sp_poly_case_eq` a Symbol arm sat behind the Regexp arm's return and never ran. The Symbol
is now asked where the Regexp is, a grown String is read through its handle, and the two dead
lines go. `slice_before`, `slice_after` and a boxed `===` use the same test. A Symbol now pays
the match master never made.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
