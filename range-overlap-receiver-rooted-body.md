<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
bad = 0
keep = []
3000000.times do |i|
  x = i.to_f
  bad += 1 if (x..(x + 1.0)).overlap?((x + 5.0)..(x + 6.0))
  keep << [(x..(x + 1.0)), 1][0] if i % 8 == 0
end
p bad
```

```
spinel diff: output-diff
  program: witness.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-0
+1
```

That is master (e527d205d) in a plain run, no stress setting: two Ranges five apart overlap once in 3,000,000 calls. Under `SPINEL_GC_STRESS=2` they overlap in every call.

`sp_range_overlap_v` takes two boxed values, and the emitters wrote both as arguments of the one call: `sp_range_overlap_v(sp_box_frange(r), sp_box_frange(o))`. A typed Range is boxed by a copy into a fresh cell, which nothing holds while the other argument's cell is allocated. A collection there frees it, the second box takes the same cell, and a Range overlaps itself.

Three sites wrote the call so, and one binding cures the three: a Float Range (the program above), an Integer Range asked about a Float Range (`(i..(i + 1)).overlap?((i + 5.5)..(i + 6.5))`, wrong under stress), and a boxed receiver that a call answers (`boxed(x).overlap?((x + 5.0)..(x + 6.0))` with `def boxed(x) = [(x..(x + 1.0)), 1][0]`: 5 in 3,000,000 in a plain run). They now go through `emit_range_overlap`, which binds a receiver whose value is made at the call to a rooted temp before the argument is made.

The same binding settles the order of the two. C does not say which argument of a call is evaluated first, and gcc makes the second first:

```ruby
def lo(x) = (puts "recv"; x)
def hi(x) = (puts "arg"; x)
x = ARGV.size + 1.0
p (lo(x)..(x + 1.0)).overlap?(hi(x + 5.0)..(x + 6.0))
```

Master prints `arg`, `recv`, `false`; CRuby and this print `recv`, `arg`, `false`.

Not every call is bound. A receiver that is a plain read of a boxed value has nothing made beside it, and neither has any receiver asked about an argument that is a plain read of a boxed value: those keep master's C. callgrind, 200,000 calls in a loop:

| | master | this |
|---|---|---|
| `(i..(i + 3)).overlap?((i + n)..(i + 9))` | 81,110,991 | 83,484,027 (+12 a call) |
| `(x..(x + 3.0)).overlap?((x + 1.0)..(x + 9.0))` | 93,787,166 | 93,472,145 |
| a boxed local asked about a Float Range | 57,335,353 | the same C |
| a Float Range asked about a boxed local | 48,736,259 | the same C |

The first row pays the binding: two Integer Ranges were at fault as well (`(n..(n + 1)).overlap?(n..(n + 1))` is wrong at stress 2 on master).

Of 912 forms (19 receivers, 16 arguments, each printed, in an `if` and in a loop), each built by master and by this and run plain and at `SPINEL_GC_STRESS=2`: 324 keep master's C. Of the 588 whose C changes, 312 are right in a plain run and wrong at stress 2 on master, and right at both with this; 276 are right at both before and after. None is wrong with this.

`test/float_range_overlap_cover.rb`, `test/int_float_exact_compare.rb` and `test/range_overlap_array_flatten_depth.rb` each print wrong lines at `SPINEL_GC_STRESS=2` on master and pass there with this. The new test prints one wrong line of 17 on master in a plain run and ten at stress 2; it is added to `GC_STRESS_TESTS`, and `make gc-stress-test` passes.

`tools/cident.sh`: 6405 identical, 9 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against e527d205d). The 9 are the new test, the four tests that print the compiler's revision, and four tests that call `overlap?` on a typed Range (`float_range_overlap_cover`, `int_float_exact_compare`, `range_overlap_array_flatten_depth`, `range_overlap_empty_boxed`), which pass with the new C.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
