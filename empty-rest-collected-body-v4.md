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

Cost: the rest is held wherever what stands beside it is not proven to run nothing, and calls master ran right pay it: an argument, a keyword's value or a default left out that is a call (`note(z, inc(z))`, whatever `inc` does), and anything else the list below does not name. A held call pays one root. 200,000 calls of a one-line method in a loop, gcc and clang: at the top level 30,092,566 to 33,094,621 and 29,758,550 to 33,560,603 instructions (15 and 19 a call, a tenth and an eighth of that loop); in a method 15 and 20; with the call as a keyword's value 17 and 17. Compile time: a held rest is one more slot in its function's root frame, as each of master's own rooted rests is (`note(z, count, 1)`), and gcc's time for one function of N such calls grows faster than N. At the top level, master to here, with master's own rooted rests in brackets: 1,000 calls 6.7 s to 7.8 s (10.5), 2,000 14.0 to 17.2 (22.4), 4,000 35 to 51 (58). In one method 2,000 take 15.0 s and 19.4 s (21.5), and 4,000 take 34 s on master and 79 s here, more than master's own rooted rests (56 s). clang at 2,000: 43 s to 47 s (78). Of the corpus's 6,513 programs `make cident` finds 10 changed: this test and 9 that make such a call, 6 of them right on master in every run and 3 that abort there under `SPINEL_GC_STRESS=2` (`test/builtin_send_kwsplat` with `--share-strings` is cured; the other two still abort, for the constructor's reason below).

`emit_rest_pack_kwh` writes such a rest as a bare call among the C arguments, and `emit_args_filled_argv` leaves in place an argument bound to a parameter that takes no root, such as an Integer-typed call. C orders the two as it likes: where the Array is made first, the argument's call collects it.

Where something beside the rest runs where it is written, the bare rest now takes the general packing's own form: a temp declared and rooted in the enclosing frame, assigned where the rest stands. Each argument, keyword value and default the call leaves out is asked with the parameter that takes it (`binding_runs_in_place`): a pure read runs nothing; what a parameter that takes a root is given runs ahead of the call, into its rooted temp (`emit_arg_rooted`), as does a keyword's value the call ran first and whatever a `**` rest collects; a String literal with no NUL in it is a static, and a Range of plain reads into a Range parameter is a value. A read that allocates nothing and runs nothing of the program's is a value too (`read_runs_nothing`): a global the program assigns, `size` or `length` of a String, an Array or a Hash where no class of the program defines the name, an attribute read through a generated reader, an operator over scalars on such reads; and a lone `**h` that is a pure read of a Hash of Symbol keys, into keyword parameters of its value's type. So `log("lit")` against `def log(msg, *r)`, `note(z, build)` with an Array for `build`, `note($g, s.size)` and `opt(**h)` keep master's C.

A splat read ahead of an argument that rebinds what it reads (`f(reset, *$xs)`, `reset` assigning `$xs`) prints the old elements with gcc on master in a plain run; under `SPINEL_GC_STRESS=2` master's rest was collected as well and the program aborted, and it now prints that plain-run answer there too, the one `f(reset, *$xs, 9)` prints with gcc on master in every run.

Not in this change, each on master and here: a rest freed inside the constructor it is handed to (`test/post_rest_keyword_hash` aborts under `SPINEL_GC_STRESS=2`); a block-pass that runs a call beside a bare rest handed to `new` (`D.new(z, &mkproc)` against `def initialize(a, *r, &blk)`: clang's build prints the rest's size as 3); a receiver that runs where it is written, for a method added to a builtin (`count.f(z)`: "A method added to a builtin runs its receiver before its arguments"); a rest built from a leading splat beside a default the call leaves out (`tail(*ints)` against `def tail(a, *r, k: count)`); a Range, Rational, Complex or Time local read into a boxed parameter beside the rest (`three(q)` against `def three(a, *r)`: the read is boxed among the C arguments, into a cell nothing holds, and gcc's build prints a wrong size for the rest under `SPINEL_GC_STRESS=2`).

`test/empty_rest_held_beside_argument.rb` prints 16 lines and joins `GC_STRESS_TESTS`; master gets one wrong with gcc and two with clang in a plain run, and under `SPINEL_GC_STRESS=2` six with gcc, while clang's build aborts at the first.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head, in a container without CRuby 4.0: the build; `test/empty_rest_held_beside_argument.rb` with gcc and clang at `SPINEL_GC_STRESS` 0, 1 and 2 and with `--share-strings`; `ruby tools/gate.rb check`; `make cident` against master (6,503 programs identical, 10 differ: the new test and the nine tests counted above); `make share-strings-test` and `make int-min-test`; the test's `.expected` is CRuby 3.3.6's, run with `--enable-frozen-string-literal`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the test has none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not: the C is master's byte for byte)
- [ ] Depends on: none
