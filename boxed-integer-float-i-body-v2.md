<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
row = [5, "q"]
x = row[0]
p x.i
```

```
spinel diff: exception-diff
  program: boxed_i.rb
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): NoMethodError: undefined method 'i' for an instance of Integer

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +0,0 @@
-(0+5i)
```

A boxed Float raises the same way, and so does a number held as a Hash value, a parameter or an instance variable given two kinds, a block parameter over a mixed Array, a value picked by a condition, and a call written `x&.i`, `x.send(:i)` or `map(&:i)`.

A boxed number answers `real`, `imaginary`, `conj`, `rect`, `polar` and `to_c` through the `sp_poly_*` helpers. `i` was in none of the boxed arms, so the call was left untyped and emitted as a missing method.

It is typed and emitted beside `conj` now. `sp_poly_imag_unit` answers the imaginary number an Integer or a Float answers unboxed, and raises NoMethodError for any other value, with the message it had.

The call is taken only where nothing of the program's own answers an `i`:

- No class or module has one as a method, a reader or a class method. `i` is a common reader name, and a boxed value of such a program can be one of its objects, or a class that answers `i` on its class tag (`[K, J].each { |c| p c.i }`).
- The program does not require `ostruct`. A boxed OpenStruct answers any reader with its member.

Beside either, the call is typed and emitted as it was, and the program gets the C it had. The analysis and the emitter ask the one question (`an_program_answers_name`, `program_answers_name`). It is not `poly_name_user_claimed`, which says no inside a dispatch's builtin arm and would change that program's C there.

What it costs a running program (callgrind, a loop of 200,000 turns with the call less the same loop without it): 93 instructions a turn for a boxed Integer and 93 for a boxed Float, against 88 and 86 for the unboxed call, which makes the same Complex. The unboxed `i` and the boxed `conj` compile to the C they had.

Not in this change:

- A boxed Rational's `i` still raises. Unboxed it answers a Float part (`(0+0.5i)` for CRuby's `(0+(1/2)*i)`), and the boxed call does not take that answer.
- A boxed number now prints what the unboxed call prints on master, and three of those lines are not CRuby's. Under `# spinel: int64`, `x = [4611686018427387903, "q"][0]; p x.i` prints `(0+4611686018427387904i)`, as `x = 4611686018427387903; p x.i` does on master: an Integer past 2**53 does not fit the Float the part is kept in. `x = [0.0, "q"][0]; p x.i.conj` prints `(0+-0.0*i)` for `(0-0.0i)`, as `x = 0.0; p x.i.conj` does. And `x = [2.5, "q"][0]; p x.i * 2` prints `(0.0+5.0i)` for `(0+5.0i)`, as `x = 2.5; p x.i * 2` does.
- An Integer past 64 bits still raises boxed: `x = [2**70, "q"][0]; p x.i`. Unboxed, master refuses to build it.
- `x.respond_to?(:i)` on a boxed number still answers false, as `x.respond_to?(:conj)` does.
- Beside a class or a module with an `i` of any kind, or under `ostruct`, a boxed number's `i` still raises. A class-level `attr_reader :i` (in `class << self`), a `def O.i` on one object, `method_missing` and a top-level `def i` are not answers the boxed dispatch has on master, so they do not count: a boxed number is answered beside them, and they raise as they did.

Measured on master 9274c732:

- Generated programs: 2,448. Nine ways of holding the value boxed (an element of a mixed Array, a Hash value, a condition, a parameter, an instance variable, a block parameter, `&.`, `send(:i)`, `map(&:i)`) by seventeen values (5, -3, 0, 2.5, -0.0, 0.0, a String, nil, a Symbol, 2**70, 4611686018427387903, a Rational, a Complex, an object with and without an `i`, a class with and without `def self.i`) by eight uses, with nothing else defined (1,224); and the same by two uses beside a class with a reader `i`, a class with `def self.i`, a module with `def self.i` and an inherited class method (1,224).
- 1,566 get the C they had: all 1,224 beside a definition, the 144 whose value is an object or a class with an `i`, and 198 where the receiver is not boxed or the use is `respond_to?`.
- The 882 that get other C were run plain and under `SPINEL_GC_STRESS=1` and `2` on both trees. 342 that raise (302) or print the program's own rescue (40) on master are right here. 306 that are right stay right: a String, nil, a Symbol, a Complex, an object and a class with no `i` raise as they did. 112 raise on both, with the same line (the Rational, 2**70). 32 print a wrong line on both: 16 the program's own rescue of the Rational's or 2**70's raise, 16 that rescue on master and one of the three lines above here. None that was right is wrong.
- 90 raise on master and print a line CRuby does not print here. 83 print the line their unboxed twin prints on master (the three kinds above: 37 an Integer past 2**53, 19 a negative zero, 27 a Float's `i` times an Integer). 7 are `row.first(1).map(&:i)` followed by `p x.respond_to?(:i)`: master raises at the first line, and the second prints false here, as it does on master in the same program without the first.
- Ways of defining an `i`: 73 preludes (65 that define one or require `ostruct`, 8 controls that do neither) by 20 boxed receivers, 1,460 programs. 1,223 get the C they had, among them every instance method, reader, `attr_accessor`, Struct and Data member, `alias`, `alias_method`, `define_method`, `def self.i`, `class << self`, `define_singleton_method`, a module's `def self.i`, `module_function`, `extend`, `include`, an inherited method of either kind, a reopened Integer, Float, String, Numeric, Object or Kernel, and `require "ostruct"`. Of the 237 that get other C, none that was right on master is wrong, and none that raised prints a wrong line.
- `make cident` reports 6,420 identical, 1 differ (`test/boxed_number_i.rb`, the new test of the cured call); `make infer-test` passes.
- The three tests pass plain and under `SPINEL_GC_STRESS=1` and `2`, built with gcc 13.3 and with clang 18.1 (`--cc=clang`), and with `--share-strings`.

Tests: `test/boxed_number_i.rb`; master raises at its first line. `test/boxed_number_i_class_method.rb` and `test/boxed_number_i_ostruct.rb` are right on master and stay right: they hold the two places the call stands down, a class method `i` reached through a boxed class and an OpenStruct member `i`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: nothing
