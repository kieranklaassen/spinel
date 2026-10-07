<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

One value that is no collection, splatted into a `yield` or a proc's call, was dropped.

```ruby
def g(v) = yield(*v)
p(g(5) { |a| a })
f = proc { |a| a }
x = :k
p f.call(*x)
```

`spinel diff` on master:

```
spinel diff: output-diff
  program: lead.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-5
-:k
+nil
+nil
```

**Not proved, and yours to weigh.** As in the pull request beneath, the value is handed over as itself only in a program the compiler can read no way to a `to_a` in. A `to_a` that comes from where it cannot read (a `require` Spinel skips, `autoload`, a library call that defines code, a class of CRuby's the program reopens, a method name built at run time) is not seen, and there the value now arrives as itself where CRuby asks its `to_a`. Before, it was dropped there, which was not CRuby's answer either. And a proc called only through a second local (`q = pr; q.call(:k)`) reads its argument as an Integer on master, with no splat at all; with the splat it now answers as that line does, where it answered nil.

The argument list built there is spread with `sp_enum_items_from`, which has no items for a value that is no collection. CRuby asks `to_a` only of a value that has one; any other value is the one argument, itself. `emit_spread_args_into` now spreads such a splat, for a block or a proc, with `sp_splat_arg_items`, a new helper beside `sp_enum_items_from`: an Integer (a big one too), a Float, a Symbol, true, false, a class and an object of the program are the value itself. Everything else goes to `sp_enum_items_from` as before. The helper is chosen only where the walk of the pull request beneath (`splat_program_may_make_to_a`) finds no way to a `to_a`: an Integer has one where the program reopens Integer, a class where it defines `self.to_a`. `lib/spinel_rt.h` is added to, not changed.

A lambda's call and a Method's are left as they were. Both count their arguments: with the value dropped they raise ArgumentError (given 0, expected 1), and in a program whose `to_a` the compiler cannot see CRuby raises ArgumentError there too, so handing the value over would turn a raise into an answer. Which of the two a Proc is, only the run time knows, so it is asked there (`sp_splat_arg_items_of`); a lambda written in place, a Method and a curried Proc compile to the same C as before. That is the second commit.

Checked:

- `test/splat_one_value_into_block.rb` and `test/splat_one_value_into_block_bigint.rb` (`# spinel: int64`) fail on master and pass here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`, with gcc and clang.
- 2,580 generated programs on master dafa0d047 (kinds of value into forms of yield, proc and lambda, each program holding only its own kind's classes), each against CRuby: the generated C changes in 813. Of those, 429 go from wrong to right, 179 were right and stay right, and 205 answer as on master: 189 are a lambda's call (135 raise ArgumentError as before, 54 print what they printed) and 16 a boxed String. No program that was right is lost, and none that raised now prints a wrong answer. The other 1,767 compile to the same C.
- Cost: the helper is chosen at compile time, only where the splat's kind is one of those or is boxed; a splat known to be an Array, a Hash or a Range compiles to the same C. A boxed Array splatted into a proc held in a local pays 13 instructions a call (callgrind, gcc: 200,000 calls ran 152,466,988 before and 155,068,116 after), and 24 where the receiver is itself a call.
- `tools/cident.sh` against f3da0151f: 6375 identical, 4 differ, 0 refusal changes. The four are the two new tests, the test of the pull request beneath and `test/block_param_table_rows.rb`, which splats a boxed value into a block and passes as before.

Left alone:

- A String is still dropped there. The list holds boxed values and a boxed String is a copy, so a block that appends to its parameter would write to the copy, where passing the String without the splat changes it.
- A Proc, a Method, a Regexp, a Rational, a Complex, an Encoding, a MatchData, a Time and a builtin exception (a rescued one too) are still dropped there.
- An object whose `to_a` answers something that is no Array: CRuby raises TypeError. Such a program has a `to_a`, so it compiles as before.
- A lambda's call and a Method's, as said above: `lambda { |a| a }.call(*5)` still raises ArgumentError where CRuby answers 5. A Symbol's `to_proc` is a lambda.
- `instance_exec(*v)` and a Method's `to_proc` are ways to a `to_a` for the walk, so a program with one compiles as before.
- `f[*x]`, a splat beside another argument, and a splat into a method take other paths.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A splatted object arrives as itself in a program with no to_a": this one calls its walk; its commits sit beneath these two with the same SHAs)
