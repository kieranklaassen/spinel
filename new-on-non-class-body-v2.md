<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class Box; end
c = ARGV.size > 5
r = c ? Box : nil
p r.new.class
```

printed `Box`; CRuby raises NoMethodError (undefined method 'new' for nil). `new` on a boxed receiver switched on the value's `cls_id` without asking whether the value is a class: nil, false, a number, a String and a Symbol read as 0, the program's first class, and an instance as its own class. The switch now reads `cls_id` only from a value tagged as a class; any other value takes the default arm, which already raises CRuby's NoMethodError.

The decision: the test goes in only where it cannot change a right answer. A program that can give a value below a class a `new` (a `def`, an alias, an attribute or a member, `method_missing`, a method under a name the source does not spell) compiles to the C it did, because there the instance's own `new` may be the answer and this arm does not dispatch to it. So does `new` with a keyword, a splat or an argument beside a literal block: that form's default arm raises before the arguments are evaluated, and the test there would raise ahead of an argument that raises itself. Sending `new` on such a value to the ordinary method call is not done here; `docs/limitations.md` gains the row.

Test: `test/class_value_new_on_non_class.rb`; CRuby raises on 16 of its lines, master on one. Checked on 3,512 generated programs built with gcc and with clang and run at `SPINEL_GC_STRESS` unset, 1 and 2: none that is right on master changes, and 379 that built an object now raise as CRuby does. optcarrot's generated C is unchanged, and the 79 corpus programs whose C changes pass. The cost is the test of the tag, 3 to 4 instructions a call (callgrind over a million calls).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
