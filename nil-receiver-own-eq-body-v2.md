<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Tag
  attr_reader :v
  def initialize(v) = @v = v
  def ==(o) = o.is_a?(Tag) && @v == o.v
end
a = [Tag.new(1)]
a[2] = Tag.new(4)
p a[1] == nil          # true
p nil == a[1]          # true
p a[1] == Tag.new(1)   # false
```

This printed `false` and `false`, and the third line died of signal 11.

The cure has a cost, stated here and measured below: where the receiver may be nil, one nil test ahead of the call (2 to 6.5 instructions a comparison); where nil is ruled out, nothing.

A nil in a slot typed as an object is a NULL pointer. The equality emitter's object arm called the class's `==` with that pointer as `self`: a body that reads no instance variable of `self` answered by its own rule, and one that reaches `@v` faulted. The other way round, `nil == a[1]` was folded to false, as it is for an object that cannot be nil.

Where the receiver may be nil (`Repr.may_nil`, the nil fact) the call now tests it: nil answers as `NilClass#==` does, true for nil alone, and the method runs for an object. The argument is evaluated once, after the receiver, either way. A `!=` derived from `==`, an `==` given a boxed argument, `===` and a `when` take the same test, and `nil == x` on such a slot is a NULL test. A receiver the fact rules nil out for keeps its C, and so does a program that gives nil an `==` of its own.

Not here, each as it was:

- a class's own `!=`, `eql?` and `equal?` on such a slot;
- the other names nil answers itself where the class defines them (`to_s`, `inspect`, `hash`): the class's method still runs on the NULL.

## Measured

On master 3d629868, with gcc 13.3 and clang 18.1, plain and at `SPINEL_GC_STRESS=2`.

- A family of 4,200 programs: six bodies of `==` (one with a subclass that overrides it, one with a `!=` of its own); ten slots (a gap a store past an Array's end leaves, a nil element, a local, a Hash value, `find`, `first`, a method's value, a parameter, an instance variable never set and one set to nil), each holding nil and holding an object; 35 uses (against `nil` from both sides, a new object, a call with an effect, itself, another slot, a boxed value, an Integer, a Float, `true`, a String, a Symbol, an Array; in `if`, `unless`, `?:`, `&&` and `while`; `eql?`, `equal?`, `nil?`, `include?`). On master 2,816 are right, 595 print a wrong answer, 455 die of signal 11, 44 raise and 290 are refused. The C changes for 1,822 and is byte-equal for the rest. Of the 1,822, the 840 that were right are right, and so are the other 982 (490 wrong answers, 448 signal 11, 44 raises), with both compilers at both levels. Here 3,798 are right. The 112 that still fail keep master's C: the `eql?` and `equal?` uses (84) and `!=` on the class that defines its own (28).
- Cost, by callgrind, over 20 million comparisons in a `while`: an instance variable against a local, 89 instructions a turn on master and 91 here; an element of an Array with a gap against another element, 124.5 and 131; two parameters no caller gives nil, the same C.
- On master 106c9650, which this commit sits on: `tools/cident.sh` against master: 6527 identical, 2 differ, 0 refusal changes. The two are the new test and test/recursive_set_json.rb, where globals are compared with `==`; it passes with both compilers at both levels. `tools/refusals.sh`: 536 records, unchanged. `make reject-test`, `make share-strings-test`, `make int-min-test` and `make infer-test` pass. The new test is right with gcc and clang at both levels, and with `--share-strings`; on master it dies of signal 11.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this commit in a Linux container, with gcc 13.3 and clang 18.1: the build, `ruby tools/gate.rb check` with the change staged, `tools/refusals.sh`, `make reject-test`, `make share-strings-test`, `make int-min-test`, `make infer-test`, the new test and test/recursive_set_json.rb with both compilers plain and at `SPINEL_GC_STRESS=2`, and `tools/cident.sh`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (compared with CRuby 3.3.6 run with that flag)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is byte-equal to master's)
- [x] Depends on: nothing
