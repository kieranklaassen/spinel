<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

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

**The cost, yours to weigh.** A boxed Array or Hash splatted into a block or a proc ran right before and now pays the test of what the value is. Instructions a call more than on master (callgrind, 200,000 calls, `v` a boxed Array; the first line in its loop is about 760 a turn):

| the call | gcc | clang |
|---|---|---|
| `f.call(*v)`, a proc in a local | 9 | 5 |
| `@f.call(*v)` | 10 | 5 |
| `f.call(*h.v)`, `v` an `attr_reader` | 9 | 5 |
| `f.call(*h.v)`, `def v = @v` | 13 | 5 |
| `f.call(*val)`, a call with no receiver | 12 | 5 |
| `yield(*v)` into `&pr` | 9 | 9 |
| `mk.call(*v)`, the receiver a call | 20.5 | 14.5 |
| `yield(*row)`, `row` a boxed row of a table | 7 | 6 |

What a boxed value is, is known only when the program runs, so no list made at compile time takes the test away. A splatted value that is a call the pure-read list does not clear is also taken into a temp of its own before the Proc is asked (the 3 and 4 more with gcc), and a receiver that is itself a call is run once into a rooted temp (24 and 18 a call where that call does more). A lambda in a local and a splat known to be an Array, a Hash or a Range run the instructions they ran.

**Not proved, and yours to weigh.** As in the pull request beneath, the value is handed over as itself only in a program the compiler can read no way to a `to_a` in. A `to_a` that comes from where it cannot read (a `require` Spinel skips, `autoload`, a library call that defines code, a class of CRuby's the program reopens, a method name built at run time) is not seen, and there the value now arrives as itself where CRuby asks its `to_a`. Before, it was dropped there, which is CRuby's answer where that `to_a` answers `[]` and no other time.

The argument list built there is spread with `sp_enum_items_from`, which has no items for a value that is no collection. CRuby asks `to_a` only of a value that has one; any other value is the one argument, itself. `emit_spread_args_into` now spreads such a splat, for a block or a proc, with `sp_splat_arg_items`, a new helper beside `sp_enum_items_from`: an Integer (a big one too), a Float, a Symbol, true, false, a class and an object of a class the program wrote are the value itself, and everything else goes to `sp_enum_items_from` as before. The helper is chosen only where the walk of the pull request beneath (`splat_program_may_make_to_a`) finds no way to a `to_a`. A typed operand is asked at compile time and compiles to master's C when the answer is no; a boxed one reads a table of the answers per class (`sp_splat_own_cls`, emitted only into a program that builds such a list). `lib/spinel_rt.h` is added to, not changed.

**Stands aside for a fault of master's.** The value arrives boxed, and on master a boxed receiver does not reach every method the program wrote: a comparison or a unary operator of a boxed object is the builtin one whatever its class defines (`t = [K.new, 1]; q = t[0]; q <=> 1` answers 1), and a builtin class the program reopens answers a boxed receiver with the builtin method. Where the value was dropped such a call raised on nil; handing the value over would make that raise a wrong answer. So an object whose class, a class above it or a module it includes writes a comparison or a unary operator keeps the list it had (`splat_class_arrives_boxed`), and so does every splat of a program that reopens Integer, Float, Symbol, TrueClass, FalseClass, NilClass, Numeric, Comparable, Object, Kernel, Class or Module (`splat_program_reopens_value_class`). Both lists go when boxed receivers reach those methods.

A lambda's call and a Method's are left as they were. Both count their arguments: with the value dropped they raise ArgumentError, and in a program whose `to_a` the compiler cannot see CRuby raises there too, so handing the value over would turn a raise into an answer. Which of the two a Proc is, only the run time knows, so it is asked there (`sp_splat_arg_items_of`), and the Proc that is asked is the Proc that is called: a splatted value that runs code is taken in a statement of its own before the Proc is read, and where an argument after the splat runs code or can give the Proc's variable another value, the receiver is read once, before the arguments as CRuby reads it, into a rooted temp.

Checked with gcc and clang; the tests and the cost table on master 9c7ea3ce06f3, the rest on 42557a3c0e7c:

- `test/splat_one_value_into_block.rb`, `test/splat_one_value_into_block_bigint.rb` (`# spinel: int64`), `test/splat_package_object_into_block.rb` and `test/splat_proc_receiver_read_once.rb` fail on master and pass here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`.
- 2,580 generated programs (kinds of value into forms of yield, proc and lambda), each against CRuby: the generated C changes in 775. Of those, 400 go from wrong to right, 177 were right and stay right, and 198 answer as on master, word for word (182 a lambda's call, 16 a boxed String). No program that was right is lost, and none that raised now prints a wrong answer.
- 98 more programs over what Spinel ships (a StringIO, a Set, a Pathname, a Logger and others, typed and boxed; a class of the program beneath one; a Struct, a Data, `Class.new`): 72 answer as on master, word for word, 24 go from wrong to right, and 2 print another wrong answer, a class written `class M::Foo`, whose name master prints as `Foo` with no splat at all. None that was right is lost.
- The compiler runs the same number of instructions to within 0.02% (`kernel_conv_protocol` 737,726,515 before and 737,767,238 after, `bundle_misc_b` 427,442,057 and 427,499,848).
- `tools/cident.sh` against the pull request beneath: 6473 identical, 5 differ, 0 refusal changes. The five are the four new tests and `test/block_param_table_rows.rb`, which splats a boxed row into a block and passes as before (the last line of the table above).

Left alone:

- A String is still dropped there: the list holds boxed values and a boxed String is a copy, so a block that appends to its parameter would write to the copy.
- A Proc, a Method, a Regexp, a Rational, a Complex, an Encoding, a MatchData, a Time, a builtin exception, an object with a singleton method and an object of a class Spinel ships or of a class beneath one: as on master.
- A lambda's call and a Method's, as said above: `lambda { |a| a }.call(*5)` still raises ArgumentError where CRuby answers 5. A Symbol's `to_proc` is a lambda.
- A splat whose value runs code that gives the Proc's variable another Proc where neither test above sees it (an interpolation that runs a `to_s` of the program, a `define_method` body that assigns it): raises ArgumentError as on master, where CRuby calls the Proc it read first.
- `f[*x]`, a splat beside another argument, and a splat into a method take other paths.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A splatted object arrives as itself in a program with no to_a": this one calls its walk; its commits sit beneath this one with the same SHAs)
