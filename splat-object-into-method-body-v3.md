<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

An object splatted into one of the program's methods arrived wrapped in an Array.

```ruby
class Foo
  def initialize(n) = @n = n
  def n = @n
end
def cls(a) = a.class
def num(a) = a.n
x = Foo.new(1)
p cls(*x)
p num(*x)
```

```
spinel diff: exception-diff
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): NoMethodError: undefined method 'n' for an instance of Array

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1 @@
-Foo
-1
+Array
```

**Not proved, and yours to weigh.** The object is handed over as itself only in a program the compiler can read no way to a `to_a` in. A `to_a` that comes from where it cannot read is not seen: a `require` Spinel skips, `autoload`, a library call that defines code (`ERB#def_method`), a class CRuby already has and the program reopens (other than Set and Gem), a method name built at run time and handed to `inject` or `to_enum`. There the object now arrives as itself where CRuby asks its `to_a`. It was not CRuby's answer before either: with `def cnt(*r) = r.size`, `p cnt(*x)` prints 1 in such a program on master, where CRuby prints the length of the `to_a`. A sweep of 299 programs written to get past the rule found 40 of them, 15 with no `rescue` in the way.

A splat handed to a method of the program is spread in place where its operand is boxed, a scalar or an Array. An object of one of the program's classes was none of those, and the one-element array `sp_splat_to_array` wraps it in was passed as the argument. It is now spread in place too, but only in a program with no way to a `to_a` at all. That is one walk a program (`splat_program_walk_for_to_a`), kept on the compiler. It answers "may", and the program compiles to the same C as before, for any of:

- `to_a` or `method_missing` spelled as a def, a Symbol or inside a String; a def or a literal of `respond_to?` or `respond_to_missing?`; Enumerable, ObjectSpace, BasicObject, Set or Gem named;
- an eval, and a Symbol or String that names a way to call, fetch or mix in by name (`send`, `method`, `instance_method`, `const_get`, `include`, `extend`, `prepend`, `to_proc`);
- a method made under a name that is no literal: `define_method`, `alias_method`, the `attr` family and the delegators given anything but literals, directly or through `send`; the name of one of them as a literal anywhere else; an `alias` whose new name is built;
- `include`, `extend` or `prepend` of anything but a constant or `self`; `to_proc` on anything but a Symbol literal; a `&x` whose `x` is neither a Symbol literal nor a Proc or a Method;
- a class whose parent is not a class of the program, a builtin exception or Object, and a class above the object's that is a Struct, a Data or a native class.

The class tables alone do not prove an object has no `to_a`: `alias to_a instance_variables`, an Enumerable whose `each` is an alias and a `define_method` in an `inherited` hook each give it one the tables do not show. So a program that spells a `to_a` anywhere, on any class, keeps the wrapped array. That is the cost of the rule.

Three commits: the fix, then two that widen the walk (a `to_a` made without its name spelled; a program's own Set), each with its test.

`tools/cident.sh` against 70cddab37: 6361 identical, 1 differ, 0 refusal changes. The one is the first test; the two guard tests compile to master's C, which is their point.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A splatted value is rooted while its one-element array is allocated": the test's `one(*Foo.new(2))` hands `sp_splat_to_array` a call's fresh answer; its commit sits beneath these with the same SHA)
