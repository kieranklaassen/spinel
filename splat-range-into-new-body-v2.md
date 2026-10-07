<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A Range splatted into `new` was handed to the constructor as one value.

```ruby
class D
  def initialize(a, *r) = @r = r
  def r = @r
end
p D.new(1, *(1..3)).r
```

```
spinel diff: output-diff
  program: lead.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[1, 2, 3]
+[1..3]
```

With an optional before the rest (`a, b = 9, *r`) the optional took the Array and the rest stayed empty. Into three plain parameters the program raised TypeError, `Pair.new(*(1..2))` on a Struct did not compile, and an Enumerator arrived as itself.

A Range, a String Range or an Enumerator splatted into a method of the program is rewritten to `*x.to_a`, so its elements land on the parameters; the same splat into a method, a class method or `super` is right. `splat_feeds_user_method` left a constructor out unless the class had a class method `new`. It now answers yes for `new` on a class whose `initialize` the program wrote, on a Struct and on a Data. A class with none of these compiles to the C it had: a builtin exception's child without an `initialize` and a builtin class the program reopens take their arguments in arms of their own. Answering yes for every class the program names would trade one fault for another twice: `MyErr.new(*("boom".."boom"))` on a builtin exception's child without an `initialize` went from a wrong message to a C error, and `Array.new(*(2..3))` on a reopened Array from a C error to an ArgumentError a `rescue` swallows.

The constructor was left out because the spread makes a fresh Array in its argument list, and a constructor allocated the object before `initialize` held its parameters. The pull request beneath roots the rest ahead of that allocation, so this one stands on it.

Checked on master 9274c732e:

- `test/splat_range_into_new.rb` does not compile on master (the Struct line) and passes here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`, with gcc and clang. It is added to `GC_STRESS_TESTS`.
- 660 one-program forms (`new`, an inherited `new`, a top-level method, an instance method, a class method and `super`; five signatures; eleven splats; with and without a leading argument), each against CRuby, in a plain run and under `SPINEL_GC_STRESS=2`: the C changes in 100, each a `new` handed a Range. 74 of them bound the Range whole and are right; 26 were right (the signature `a, *r, z`) and stay right. All 100 are right under stress too. The other 560 compile to the same C.
- 31 more programs around the edges: 18 go to right from a wrong answer, a raise or a C error (a Struct, a Data, three plain parameters, a keyword beside the splat, two splats, an Enumerator, an endless Range, which now raises RangeError as CRuby does, an `initialize` that hands the rest to `super`); 3 were right and stay right; 6 compile to the same C; 4 are wrong as before (below).
- `tools/cident.sh` against the commit beneath: 6420 identical, 1 differ (the new test), 0 refusal changes.

Left alone:

- `M::D.new(*r)`, a `new` with no receiver inside a class method and `self.class.new(*r)` still hand the Range over whole. So does a Range of Floats, where CRuby raises TypeError.
- A class method `new` that calls `super`: as before.
- An exception class whose `initialize(a, b)` hands `super` an interpolated String: `MyErr.new(*(1..2))` printed `[1, 2]-0` and now prints `1-2`. Under `SPINEL_GC_STRESS=2` its message is read after it was freed, as it is for `MyErr.new(1, 2)` on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A rest array handed to new is held while the object is allocated": the spread array this one makes in a constructor's argument list is the rest it roots; its commit sits beneath this one with the same SHA, above the commit of "An Array a call returns is held while its elements are boxed")
