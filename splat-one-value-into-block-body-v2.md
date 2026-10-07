<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

One value that is no collection, splatted into a `yield`, a proc's call or a lambda's call, was dropped.

```ruby
def g(v) = yield(*v)
p(g(5) { |a| a })
f = proc { |a| a }
x = :k
p f.call(*x)
p lambda { |a| a }.call(*x)
```

`spinel diff` on master:

```
spinel diff: exception-diff
  program: lead.rb
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): ArgumentError: wrong number of arguments (given 0, expected 1)

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,2 @@
-5
-:k
-:k
+nil
+nil
```

**Not proved, and yours to weigh.** As in the pull request beneath, the value is handed over as itself only in a program the compiler can read no way to a `to_a` in. A `to_a` that comes from where it cannot read (a `require` Spinel skips, `autoload`, a library call that defines code, a class of CRuby's the program reopens, a method name built at run time) is not seen, and there the value now arrives as itself where CRuby asks its `to_a`. Before, it was dropped there, which was not CRuby's answer either.

The argument list built there is spread with `sp_enum_items_from`, which has no items for a value that is no collection. CRuby asks `to_a` only of a value that has one; any other value is the one argument, itself. `emit_spread_args_into` now spreads such a splat with `sp_splat_arg_items`, a new helper beside `sp_enum_items_from`: an Integer (a big one too), a Float, a Symbol, true, false, a class and an object of the program are the value itself. Everything else goes to `sp_enum_items_from` as before. The helper is chosen only where the walk of the pull request beneath (`splat_program_may_make_to_a`) finds no way to a `to_a`: an Integer has one where the program reopens Integer, a class where it defines `self.to_a`. `lib/spinel_rt.h` is added to, not changed.

Checked:

- `test/splat_one_value_into_block.rb` and `test/splat_one_value_into_block_bigint.rb` (`# spinel: int64`) fail on master and pass here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`, with gcc and clang.
- 2,580 generated programs on master dafa0d047 (kinds of value into forms of yield, proc and lambda, each program holding only its own kind's classes), each against CRuby: the generated C changes in 845. Of those, 637 go from wrong to right (156 raised, 481 printed a wrong answer), 184 were right and stay right, and 24 answer as on master (a boxed String). No program that was right is lost, and none that raised now prints a wrong answer. The other 1,735 compile to the same C.
- Cost: the helper is chosen at compile time, only where the splat's kind is one of those or is boxed; a splat known to be an Array, a Hash or a Range compiles to the same C. A boxed Array pays 7 instructions a call (callgrind, gcc: 200,000 calls of a proc ran 152,468,363 before and 153,868,363 after).
- `tools/cident.sh` against 70cddab37: 6360 identical, 4 differ, 0 refusal changes. The four are the two new tests, the test of the pull request beneath and `test/block_param_table_rows.rb`, which splats a boxed value into a block and passes as before.

Left alone:

- A String is still dropped there. The list holds boxed values and a boxed String is a copy, so a block that appends to its parameter would write to the copy, where passing the String without the splat changes it.
- A Proc, a Method, a Regexp, a Rational, a Complex, an Encoding, a MatchData, a Time and a builtin exception (a rescued one too) are still dropped there.
- An object whose `to_a` answers something that is no Array: CRuby raises TypeError. Such a program has a `to_a`, so it compiles as before.
- `instance_exec(*v)` and a Method's `to_proc` are ways to a `to_a` for the walk, so a program with one compiles as before. `:itself.to_proc.call(*v)` is changed, and right.
- `f[*x]`, a splat beside another argument, and a splat into a method take other paths.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A splatted object arrives as itself in a program with no to_a": this one calls its walk; its commits sit beneath this one with the same SHAs)
