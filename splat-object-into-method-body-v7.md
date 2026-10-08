<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

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

- `to_a` or `method_missing` spelled as a def, a Symbol or inside a String; a def or a literal of `respond_to?` or `respond_to_missing?`; Enumerable, ObjectSpace, BasicObject, Set or Gem named; a class with an `each` that yields, for which Spinel makes a `to_a` itself;
- an eval, and a Symbol or String that names a way to call, fetch or mix in by name (`send`, `method`, `instance_method`, `const_get`, `include`, `extend`, `prepend`, `to_proc`);
- a method made under a name that is no literal: `define_method`, `alias_method`, the `attr` family and the delegators given anything but literals, directly or through `send`; the name of one of them as a literal anywhere else; an `alias` whose new name is built;
- `include`, `extend` or `prepend` of anything but a constant or `self`; `to_proc` on anything but a Symbol literal; a `&x` whose `x` is neither a Symbol literal nor a Proc or a Method (a constant holding a lambda is not read as a Proc);
- a class whose parent is not a class of the program, a builtin exception or Object, and a class above the object's that is a Struct, a Data or a native class.

Only an object of the program's own class is handed over. A class Spinel ships in `packages/` is what Spinel wrote of CRuby's class, not all of it, so the `to_a` it lacks proves nothing: CRuby asks a StringIO, a Tempfile and a Zlib reader for `to_a`, and an empty one answers `[]`. Such an object, one of a class beneath it and one of a class that mixes its module in keep the wrapped array, wrong as on master and not another wrong answer that reads as right. The parser stamps a class or a module opened in a file the require resolver took from `packages/`, and a constant written there (`node_pkg`, read off the splice markers as `node_bi` is, so a build without a line map has it too). `splat_class_is_own` asks whether the program opened the class and every class and module above it that the compiler holds as a class, with no `packages/` file opening it too and none of them native. A builtin exception above it and Comparable or Kernel mixed in are no such classes and are not asked: CRuby's have no `to_a`. A program that prepends a module it did not write keeps every object's form. So does one that includes a module of `packages/` at the top level (`include FileUtils`): the module is then above every class.

The class tables alone do not prove an object has no `to_a`: `alias to_a instance_variables`, an Enumerable whose `each` is an alias and a `define_method` in an `inherited` hook each give it one the tables do not show. So a program that spells a `to_a` anywhere, on any class, keeps the wrapped array. So does one that only spells a name of the list where nothing is called by it: a Hash key `send:`, a String `"send"`, an Array holding `:attr_reader`. And so does a child of BasicObject, which CRuby hands over as itself: it raises NoMethodError here as on master, because BasicObject is not among the parents the walk allows. That cure is given up to keep the list of parents closed; it can come on its own. These are the cost of the rule.

Not here: an object of a `packages/` class beside one of the program's own.

```ruby
require "logger"
class Own; end
def cls(a) = a.class
p cls(*Own.new)
p cls(*Logger.new(nil))
```

CRuby prints Own and Logger. Master prints Array twice, and under `SPINEL_GC_STRESS=2` aborts after the first line, which the commit beneath these mends (the pull request named under "Depends on"). Here it prints Own and then Array, at every stress level: the answer the Logger line gives alone on master, at every stress level too.

Four commits, each with its test: the fix, two for the walk (a `to_a` made without its name spelled; a program's own Set), and the one for a class of `packages/`.

Checked on master 42557a3c0e7c:

- The four tests pass under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`, with gcc and clang. `test/splat_object_into_method.rb` and `test/splat_object_beside_package.rb` fail on master; the other two are guards that compile to master's C.
- 1,736 generated programs (62 kinds of operand into 28 forms of call, each program holding only its own kind's classes), each against CRuby, with gcc and clang: 260 go from wrong to right and the other 1,476 compile to the same C.
- A StringIO, a Tempfile and a class of the program beneath one, splatted into a method, compile to the same C as on master.
- `tools/cident.sh` against 42557a3c0e7c: 6469 identical, 0 differ, 0 refusal changes. The five tests of these commits and of the one beneath are not in its set.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A splatted value is rooted while its one-element array is allocated": the test's `one(*Foo.new(2))` hands `sp_splat_to_array` a call's fresh answer; its commit sits beneath these with the same SHA)
