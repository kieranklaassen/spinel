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

A splat handed to a method of the program is spread in place where its operand is boxed, a scalar or an Array. An object of one of the program's classes was none of those, and the one-element array `sp_splat_to_array` wraps it in was passed as the argument. It is now spread in place too, but only in a program with no way to a `to_a` at all: the name is spelled nowhere (no def, Symbol or String of it, so no alias, attr, `define_method` or `send` of it), there is no `method_missing`, no Enumerable and no eval, no method is made under a name that is no literal, and no class above the object's is a Struct, a Data or a native class. That is one walk a program, kept on the compiler.

The class tables alone do not prove an object has no `to_a`: `alias to_a instance_variables`, an Enumerable whose `each` is an alias and a `define_method` in an `inherited` hook each give it one the tables do not show. So a program that spells a `to_a` anywhere, on any class, compiles to the same C as before and keeps the wrapped array. That is the cost of the rule.

`tools/cident.sh` against dafa0d047: 6281 identical, 1 differ (the new test), 0 refusal changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A splatted value is rooted while its one-element array is allocated": the test's `one(*Foo.new(2))` hands `sp_splat_to_array` a call's fresh answer; its commit sits beneath this one with the same SHA)
