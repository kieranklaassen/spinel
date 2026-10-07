<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def note(a, b, *r) = "#{a} #{b} #{r.size}"

def count
  x = []
  2000.times { |i| x << [i, "p", nil] }
  x.size
end

puts note(ARGV.size, count)
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-0 2000 0
+0 2000 3
```

in a plain run of gcc's build. With `def note(a, *r, b)` gcc's build is right and clang's (`--cc=clang`) prints `0 2000 3`. The rest is one made in place, an empty one or a lone typed splat converted whole (`note(z, count, *ints)`), beside an argument that runs a call where it is written. The same holds for a class method, a module function, `new` and a method added to a builtin; an instance method of the program's own class binds every argument first and was right.

Cost: a call that takes the hold pays one root, 14 instructions under callgrind (25,531,228 to 28,333,286 for 200,000 calls of a one-line method), and a frame slot at compile time: a program of 4,000 such calls at the top level builds with gcc in 92.9 s of CPU where master takes 39.5 (2,000: 27.4 against 17.9; 1,000: 8.6 against 7.3), the curve master's own rooted rests already have (`note(z, count, 1)`, a rest with an element: 70.5 s for 4,000 on master). No other call changes: of the corpus's 6,429 programs `make cident` finds 13 changed, this test and 12 that make such a call.

`emit_rest_pack_kwh` writes such a rest as a bare call among the C arguments, and `emit_args_filled_argv` leaves in place an argument bound to a parameter that takes no root, such as an Integer-typed call. C orders the two as it likes: where the Array is made first, the argument's call collects it.

Where something beside the rest runs where it is written, the bare rest now takes the general packing's own form: a temp declared and rooted in the enclosing frame, assigned where the rest stands. Each argument, keyword value and default the call leaves out is asked with the parameter that takes it (`binding_runs_in_place`): a pure read runs nothing; what a parameter that takes a root is given runs ahead of the call, into its rooted temp (`emit_arg_rooted`), as does a keyword's value the call ran first and whatever a `**` rest collects; a String literal is a static, and a Range of plain reads into a Range parameter is a value. So `log("lit")` against `def log(msg, *r)` and `note(z, build)` with an Array for `build` keep master's C.

A splat read ahead of an argument that rebinds what it reads (`f(reset, *$xs)`, `reset` assigning `$xs`) prints the old elements with gcc on master in a plain run; under `SPINEL_GC_STRESS=2` master's rest was collected as well and the program aborted, and it now prints that plain-run answer there too, the one `f(reset, *$xs, 9)` prints with gcc on master in every run.

Not in this change: a rest freed inside the constructor it is handed to ("A rest array handed to new is held while the object is allocated" holds it; `test/post_rest_keyword_hash` still aborts under stress 2 without it); a receiver that runs where it is written, for a method added to a builtin (`count.f(z)`: "A method added to a builtin runs its receiver before its arguments"); a rest built from a leading splat beside a default the call leaves out (`tail(*ints)` against `def tail(a, *r, k: count)`); a Range, Rational or Complex local read into a boxed parameter beside the rest (`three(q)`: the read is boxed among the C arguments, a cell nothing holds, with or without a rest; that read has its own change, and the rest beside it waits on that one: once the read counts as converted, this change holds the rest there with no more code).

`test/empty_rest_held_beside_argument.rb` prints 10 lines and joins `GC_STRESS_TESTS`; master gets one wrong with gcc and two with clang in a plain run, six and four under `SPINEL_GC_STRESS=2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
