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

**Not proved, and yours to weigh.** As in the pull request beneath, the value is handed over as itself only in a program the compiler can read no way to a `to_a` in. A `to_a` that comes from where it cannot read (a `require` Spinel skips, `autoload`, a library call that defines code, a class of CRuby's the program reopens, a method name built at run time) is not seen, and there the value now arrives as itself where CRuby asks its `to_a`. Before, it was dropped there, which is CRuby's answer where that `to_a` answers `[]` and no other time.

The argument list built there is spread with `sp_enum_items_from`, which has no items for a value that is no collection. CRuby asks `to_a` only of a value that has one; any other value is the one argument, itself. `emit_spread_args_into` now spreads such a splat, for a block or a proc, with `sp_splat_arg_items`, a new helper beside `sp_enum_items_from`: an Integer (a big one too), a Float, a Symbol, true, false, a class and an object of a class the program wrote are the value itself. Everything else goes to `sp_enum_items_from` as before. The helper is chosen only where the walk of the pull request beneath (`splat_program_may_make_to_a`) finds no way to a `to_a`: an Integer has one where the program reopens Integer, a class where it defines `self.to_a`. `lib/spinel_rt.h` is added to, not changed.

An object is handed over only where the pull request beneath calls its class the program's own (`splat_class_is_own`): a StringIO, a Tempfile and a Zlib reader keep the list they had. A typed operand is asked at compile time, and compiles to master's C when the answer is no. For a boxed one the run time reads a table of the answers per class (`sp_splat_own_cls`, emitted only into a program that builds such a list).

**Stands aside for a fault of master's.** The value arrives boxed, and on master a boxed receiver does not reach every method the program wrote: a comparison or a unary operator of a boxed object is the builtin one whatever its class defines (`t = [K.new, 1]; q = t[0]; q <=> 1` answers 1), and a builtin class the program reopens answers a boxed receiver with the builtin method (`q + 2.0` with `Float#+` reopened answers 3.5). Where the value was dropped such a call raised on nil; handing the value over would make that raise a wrong answer. So an object whose class, a class above it or a module it includes writes `!=`, `<`, `<=`, `>`, `>=`, `<=>` or a unary operator keeps the list it had (`splat_class_arrives_boxed`), and so does every splat of a program that reopens Integer, Float, Symbol, TrueClass, FalseClass, NilClass, Numeric, Comparable, Object, Kernel, Class or Module (`splat_program_reopens_value_class`). Both lists go when boxed receivers reach those methods.

A lambda's call and a Method's are left as they were. Both count their arguments: with the value dropped they raise ArgumentError (given 0, expected 1), and in a program whose `to_a` the compiler cannot see CRuby raises ArgumentError there too, so handing the value over would turn a raise into an answer. Which of the two a Proc is, only the run time knows, so it is asked there (`sp_splat_arg_items_of`). `pr.call(*x)` therefore reads its receiver before the list is built, as CRuby runs it, and once: a local where it stands when no operand runs a method (a local, an ivar, self, a literal; an operator and an index are calls, and the program may have written them), anything else through a rooted temp. A lambda written in place, a Method and a curried Proc compile to the same C as before.

Checked on master 9274c732e:

- `test/splat_one_value_into_block.rb`, `test/splat_one_value_into_block_bigint.rb` (`# spinel: int64`), `test/splat_package_object_into_block.rb` and `test/splat_proc_receiver_read_once.rb` fail on master and pass here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`, with gcc and clang.
- 2,580 generated programs (kinds of value into forms of yield, proc and lambda, each program holding only its own kind's classes), each against CRuby: the generated C changes in 775. Of those, 400 go from wrong to right, 177 were right and stay right, and 198 answer as on master, word for word: 182 are a lambda's call (130 raise ArgumentError as before, 52 print what they printed) and 16 a boxed String. In this set no program that was right is lost, and none that raised now prints a wrong answer. The other 1,805 compile to the C they have on the pull request beneath.
- 98 more programs over what Spinel ships (a StringIO, a Tempfile, a Set, a Pathname, a Logger, a StringScanner, a BigDecimal, a URI, an OptionParser, a CSV and a Zlib writer, typed and boxed, empty and holding lines; a class of the program beneath one, including one's module, prepending it, reopening it; a Struct, a Data, `Class.new`; and the program's own classes beside them): 72 answer as on master, word for word: 24 right, 44 wrong as before (a StringIO that holds lines is still dropped where CRuby spreads them; an object whose class writes `<=>` is dropped as before) and 4 refused as before; 24 go from wrong to right, objects of the program's own classes (a Data and a `Class.new` with a block among them), an Integer and a Symbol; 2 print another wrong answer, a class written `class M::Foo`, whose name master prints as `Foo` with no splat at all. None that was right is lost.
- Cost: the helper is chosen at compile time, only where the splat's kind is one of those or is boxed; a splat known to be an Array, a Hash or a Range compiles to the same C. A boxed Array splatted into a proc held in a local pays 13 instructions a call (callgrind, gcc: 200,000 calls ran 152,474,635 before and 155,074,638 after), 24 where the receiver is itself a call and 30 where an operand runs a method (`f.call(*h.v)`); into a `yield` or a lambda it pays none. The compiler runs the same number of instructions to within 0.02% on two of the largest programs of `test/` (`kernel_conv_protocol` 728,350,060 before and 728,468,659 after, `bundle_misc_b` 423,525,246 and 423,518,087).
- `tools/cident.sh` against 9274c732e: 6420 identical, 3 differ, 0 refusal changes. The three are the two tests of the pull request beneath and `test/block_param_table_rows.rb`, which splats a boxed value into a block and passes as before; the four new tests are not in that reference.

Left alone:

- A String is still dropped there. The list holds boxed values and a boxed String is a copy, so a block that appends to its parameter would write to the copy, where passing the String without the splat changes it.
- A Proc, a Method, a Regexp, a Rational, a Complex, an Encoding, a MatchData, a Time and a builtin exception (a rescued one too) are still dropped there.
- An object with a singleton method, or extended by a module: its singleton class is no class the program opened, so it is dropped as before.
- An object whose class writes a comparison or a unary operator, and every splat of a program that reopens one of the classes named above: as on master.
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
