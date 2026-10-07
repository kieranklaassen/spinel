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

in a plain run of gcc's build. With `def note(a, *r, b)` gcc's build is right and clang's (`--cc=clang`) prints `0 2000 3`. The same holds for a class method, a module function, `new` and a method added to a builtin; an instance method of the program's own class binds every argument first and was right.

Three tests of the corpus fault for this cause under `SPINEL_GC_STRESS=2` on master and pass with it: `forward_args_callee_below` and `forwarding_args_class_value_super_lead_builtin` (gcc, clang and `--share-strings`), `ctor_ivar_default_keywords` (clang).

`emit_rest_pack_kwh` writes an empty rest, and a lone typed splat it converts whole (`note(z, count, *ints)`), as a bare call among the C arguments, and `emit_args_filled` leaves in place an argument whose type needs no root, such as an Integer-typed call. C orders the two as it likes: where the Array is made first, the argument's call collects it.

Where an argument, a keyword value or a default the call leaves out is not a pure read, the bare rest now takes the general packing's own form: a temp declared and rooted in the enclosing frame, assigned where the rest stands. Every other call keeps master's C: of the corpus's 6,357 programs `make cident` finds 35 changed, this test and 34 that make such a call. A call it takes pays one root, 14 instructions under callgrind (25,522,048 to 28,324,125 for 200,000 calls of a one-line method).

`test/empty_rest_held_beside_argument.rb` prints 10 lines and joins `GC_STRESS_TESTS`; master gets one wrong with gcc and two with clang in a plain run, six and four under `SPINEL_GC_STRESS=2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
