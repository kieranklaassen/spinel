<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class Box; end
c = ARGV.size > 5
r = c ? Box : nil
p r.new.class
```

printed `Box`; CRuby raises NoMethodError (undefined method 'new' for nil).

`new` on a boxed receiver switches on the value's `cls_id` (the `poly.new` arm of `emit_call_new_arms`), and it did not ask whether the value is a class. Every box has that field: nil, false, a number, a String and a Symbol carry 0, the id of the program's first class, and an instance carries its class's. So `r.new` on a nil `r` built a `Box`, a Hash miss (`REG["nope"].new`) built one, and an instance built another object of its own class.

The switch now reads `cls_id` only from a value tagged as a class. Any other value switches on `SP_CLASS_NIL_ID`, the id no class has, and takes the default arm, where `sp_class_value_new_fallback` already raises CRuby's NoMethodError. The arguments are evaluated before the switch, as they were.

The opening changes only in a program where no value below a class can answer `new`. `program_answers_new_below_class` reads that from the node table, once: the program has no `def`, alias, attribute or Struct or Data member of that name, no `method_missing`, does not write the name as a Symbol or a String (`define_method(:new)`, `respond_to?(:new)`), and makes or reaches no method under a name it does not spell (`define_method`, `alias_method`, `attr_reader` or `Struct.new` given a name that is not a literal, `send` or `class_eval` given anything but a Symbol, OpenStruct, a delegator). Any other program compiles to the C it did: there an instance's own `new` may be the right answer, and master's arm sometimes gave it.

`test/class_value_new_on_non_class.rb` calls `new` on nil, false, an Integer, a Float, a String, a Symbol, an Array and two instances, out of a conditional, `c && Box`, an Array element, a Hash miss, a parameter and an instance variable, with no argument, an argument that prints, an argument that raises and a block, each beside the class it stands in for. CRuby raises NoMethodError on 16 of its lines; master raises on one of them (the Array) and prints an object's class or value on the other 15. With this change it passes built with gcc and with clang at `SPINEL_GC_STRESS` unset, 1 and 2, and with `--int-overflow=promote`.

Generated C: optcarrot's is byte-identical, and so is that of every program in `benchmark/`. Of the corpus, 79 programs change (58 in `test/`, 21 package tests), 270 switches in all, and those 79 tests pass. 78 change at the switch's opening and nowhere else; `test/systemcallerror_message_from_errno.rb` also has the cut of main's body moved by one statement, since two of its lines are longer.

The cost is the one test of the tag. Callgrind over 1,000,000 calls (gcc 13.3, x86-64), master then this change: `ks[i & 1].new(i).a` 98,000,989 to 101,000,986 instructions, `ks[i & 1].new.a` 98,000,952 to 102,000,951, `ks[i & 1].new { i }.a` 129,007,045 to 132,507,048. That is 3 to 4 instructions a call.

Checked on 3,512 generated programs: 2,080 that call `new` ten ways on a value from nine places, with sixteen values standing beside the class; 846 where a value below a class answers `new` itself, 47 ways (a `def`, inherited, included or prepended, `define_method` under a literal, a computed or an interpolated name, an alias, an attribute, a Struct or Data member, `method_missing`, a reopened Integer, String, Symbol, NilClass, Array, Object or Kernel, a singleton method, `class_eval`, OpenStruct), and 36 beside them where none does; and 550 where an argument of `new` raises, throws, exits or prints, in eleven call forms.

- 54 are refused on both trees with the same message.
- 2,443 compile to the C master gives, byte for byte: every keyword and splat form, and all 792 that give a value a `new` and compile.
- The other 1,015 were built with gcc and with clang on master and with this change and run at `SPINEL_GC_STRESS` unset, 1 and 2. 616 print the same bytes on both (596 CRuby's answer, 20 an argument's own uncaught ArgumentError). 379 that built an object now raise as CRuby does. 20 that raised ArgumentError for an instance of another class now raise NoMethodError.
- Right on master and not right here: 0, in each of the six runs. Loud on master and silently wrong here: 0. A build failure turned crash: 0.
- 5 programs (a literal splat on a fresh instance) stop at `SPINEL_GC_STRESS=2` on the collector's report on both trees.

Left alone (the first two are the new row in `docs/limitations.md`):

- With a keyword, `**`, a splat, `...` or an argument beside a literal block (`r.new(k: 1)`, `r.new(*xs)`, `r.new(x) { }`), a value that is no class still builds an object. That form's default arm raises before the arguments are evaluated, so the test there would raise NoMethodError ahead of an argument that raises itself. It is master's C.
- A program that gives a value below a class a `new`, or writes the name as a Symbol or a String, compiles to master's C: `new` on nil builds an object there as before, and an instance's own `new` is called or not as before.
- `K = nil; K.new` raises NameError (uninitialized constant K), as on master; CRuby raises NoMethodError.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
