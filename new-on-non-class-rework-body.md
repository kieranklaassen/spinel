<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Box; end
class Maker
  def new(x) = x * 2
end
c = ARGV.size > 5
r = c ? Box : nil
p (r.new.class rescue "no new")       # Box, CRuby: "no new"
m = c ? 5 : Maker.new
p (m.new(3) rescue "wrong arity")     # "wrong arity", CRuby: 6
```

This fix has a cost, stated below: 66 of 912 generated programs that master answers right by accident raise NoMethodError with it.

`new` on a boxed value built an object by the value's class id and never asked whether the value is a class. nil reads as id 0 and built the program's first class; false, an Integer, a String and a Symbol did too. An instance carries its class's id: it built another object of its own class, or raised ArgumentError for that class's arity, and a method `new` of its own was never called.

The call now splits on the value's tag. A class takes the arms it took, unchanged. Any other value takes the ordinary method call, which finds the value's own `new` as it finds any other method and raises NoMethodError where there is none.

What it costs. An instance whose `new` is given where Spinel does not see it now raises NoMethodError, and master was right for some of those programs by accident: the object it built from the class id was what the unseen `new` answers.

```ruby
class P
  define_method("ne" + "w") { P.new }
end
r = [P, P.new][ARGV.size > 5 ? 0 : 1]
p r.new.class                         # P on master and in CRuby; with this change NoMethodError
```

Of 912 generated programs 66 go from right to wrong this way (a `new` from `define_method` or Forwardable's `delegate` with a computed name, from `method_missing`, from a `class_eval` block on a class held in a variable, from an `inherited` hook, under `if RUBY_ENGINE == "ruby"`), and 378 go from a wrong answer or a wrong raise to right. The same program with any other name in place of `new` raises NoMethodError on master already. No list of givers keeps master's answer for the 66: the name is put together at run time or the method comes from code Spinel does not run, so nothing the program spells tells them from a program with no such giver.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-"no new"
-6
+Box
+"wrong arity"
```

A call of `new` on a boxed receiver also pays the test of the tag, 1 to 9 instructions a call (callgrind, a million calls of `ks[i & 1].new` with gcc: 98.0M to 105.0M); a program with no such call compiles to the C it did. Test: `test/class_value_new_on_non_class.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # ("A call no method answers runs its arguments before it raises" and "A NoMethodError holds its receiver and arguments before it lists them")
