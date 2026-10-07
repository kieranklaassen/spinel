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

**Not proved, and yours to weigh.** As in the pull request beneath, the value is handed over as itself only in a program the compiler can read no way to a `to_a` in. A `to_a` that comes from where it cannot read (a `require` Spinel skips, `autoload`, a library call that defines code, a class of CRuby's the program reopens, a method name built at run time) is not seen, and there the value now arrives as itself where CRuby asks its `to_a`. Before, it was dropped there, which is CRuby's answer where that `to_a` answers `[]` and no other time. And a proc called only through a second local (`q = pr; q.call(:k)`) reads its argument as an Integer on master, with no splat at all; with the splat it now answers as that line does, where it answered nil.

The argument list built there is spread with `sp_enum_items_from`, which has no items for a value that is no collection. CRuby asks `to_a` only of a value that has one; any other value is the one argument, itself. `emit_spread_args_into` now spreads such a splat, for a block or a proc, with `sp_splat_arg_items`, a new helper beside `sp_enum_items_from`: an Integer (a big one too), a Float, a Symbol, true, false, a class and an object of a class the program wrote are the value itself. Everything else goes to `sp_enum_items_from` as before. The helper is chosen only where the walk of the pull request beneath (`splat_program_may_make_to_a`) finds no way to a `to_a`: an Integer has one where the program reopens Integer, a class where it defines `self.to_a`. `lib/spinel_rt.h` is added to, not changed.

Only an object of the program's own class is handed over. A class Spinel ships in `packages/` is what Spinel wrote of CRuby's class, not all of it: CRuby asks a StringIO, a Tempfile and a Zlib reader for `to_a`, and an empty one answers `[]`, so its splat is no argument at all, which is what the list holds on master. The parser stamps a class or a module opened in a file the require resolver took from `packages/`, and a constant written there (`node_pkg`, read off the splice markers as `node_bi` is, so a build without a line map has it too). `splat_class_is_own` asks whether the program opened the class and every class and included module above it, none of them native; a program that prepends a module it did not write keeps every object's form. A typed operand is asked at compile time, and compiles to master's C when the answer is no. For a boxed one the run time reads a table of the answers per class (`sp_splat_own_cls`, emitted only into a program that builds such a list). A project's package of a bundled one's name is the program's own.

A lambda's call and a Method's are left as they were. Both count their arguments: with the value dropped they raise ArgumentError (given 0, expected 1), and in a program whose `to_a` the compiler cannot see CRuby raises ArgumentError there too, so handing the value over would turn a raise into an answer. Which of the two a Proc is, only the run time knows, so it is asked there (`sp_splat_arg_items_of`); a lambda written in place, a Method and a curried Proc compile to the same C as before.

Checked on master a2bd89005:

- `test/splat_one_value_into_block.rb`, `test/splat_one_value_into_block_bigint.rb` (`# spinel: int64`) and `test/splat_package_object_into_block.rb` fail on master and pass here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`, with gcc and clang.
- 2,580 generated programs (kinds of value into forms of yield, proc and lambda, each program holding only its own kind's classes), each against CRuby: the generated C changes in 813. Of those, 429 go from wrong to right, 179 were right and stay right, and 205 answer as on master: 189 are a lambda's call (135 raise ArgumentError as before, 54 print what they printed) and 16 a boxed String. In this set no program that was right is lost, and none that raised now prints a wrong answer. The other 1,767 compile to the same C.
- 98 more programs over what Spinel ships (a StringIO, a Tempfile, a Set, a Pathname, a Logger, a StringScanner, a BigDecimal, a URI, an OptionParser, a CSV and a Zlib writer, typed and boxed, empty and holding lines; a class of the program beneath one, including one's module, prepending it, reopening it; a Struct, a Data, `Class.new`; and the program's own classes beside them): 70 answer as on master, word for word: 24 right, 42 wrong as before (a StringIO that holds lines is still dropped where CRuby spreads them) and 4 refused as before; 26 go from wrong to right, objects of the program's own classes (a Data and a `Class.new` with a block among them), an Integer and a Symbol; 2 print another wrong answer, a class written `class M::Foo`, whose name master prints as `Foo` with no splat at all. None that was right is lost.
- Cost: the helper is chosen at compile time, only where the splat's kind is one of those or is boxed; a splat known to be an Array, a Hash or a Range compiles to the same C. A boxed Array splatted into a proc held in a local pays 13 instructions a call (callgrind, gcc: 200,000 calls ran 152,473,500 before and 155,074,628 after), and 24 where the receiver is itself a call. The compiler runs the same number of instructions to within 0.03% on two of the largest programs of `test/` (`kernel_conv_protocol` 722,494,272 before and 722,308,558 after, `bundle_misc_b` 418,179,869 and 418,207,105).
- `tools/cident.sh` against a2bd89005: 6377 identical, 5 differ, 0 refusal changes. The five are the three new tests, the test of the pull request beneath and `test/block_param_table_rows.rb`, which splats a boxed value into a block and passes as before.

Left alone:

- A String is still dropped there. The list holds boxed values and a boxed String is a copy, so a block that appends to its parameter would write to the copy, where passing the String without the splat changes it.
- A Proc, a Method, a Regexp, a Rational, a Complex, an Encoding, a MatchData, a Time and a builtin exception (a rescued one too) are still dropped there.
- An object of a class Spinel ships, of a class beneath one, or of a class that mixes one's module in: as on master, right or wrong. CRuby's Pathname and Logger have no `to_a`, so those stay dropped where CRuby hands them over.
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
- [ ] Depends on: # (the pull request "A splatted object arrives as itself in a program with no to_a": this one calls its walk; its commits sit beneath this one with the same SHAs)
