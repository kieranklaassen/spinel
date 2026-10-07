<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class Shelf
  def list = (@list ||= [1])
  def none? = @list.is_a?(NilClass)
  def list? = @list.kind_of?(Array)
end
p Shelf.new.none?, Shelf.new.list?   # true and false in CRuby; false and true here
```

`is_a?`, `kind_of?` and `instance_of?` on an Array or a Hash receiver were folded from the slot's type, so a nil held there was an Array and no NilClass. A String slot already reads its NULL for these (`emit_scalar_class_test`); an Array or a Hash slot holds nil as the same NULL and takes the same test in `emit_call_compare_arms`, where the nil fact says the receiver may be nil (`repr_of`'s `may_nil`). A receiver that is not nil keeps the constant, as do `Object`, `Kernel` and `BasicObject`, which hold for nil too. A Struct member is such a receiver whatever `new` is passed: `Row.new([1]).list.is_a?(Array)` reads the member.

The three names are in the call plan's `is_nil_method` list; the plan does not reach these receivers (an instance variable, a parameter whose default is nil, an element read), and the answer is a boolean on both arms, so no type has to be joined. The nested shape that "A kind query nested in another's class argument tests its receiver for nil" settled for an object is still wrong when the inner test is on an Array slot: `@pet.is_a?(@list.is_a?(Array) ? Animal : NilClass)` with `@pet` a Cat and `@list` nil prints true on master, false in CRuby and here.

Not in this change: `Array === x` and `when Array` are answered for the slot's type, and a class test on a local or a parameter that guards a read of it is folded before it is emitted, so the read raises NoMethodError (`x = @list; x.is_a?(Array) ? x.size : -1`); both as on master.

Measured on 1,008 generated programs (the three tests on an Array, a Hash, a String, an Integer, a Struct and an object slot, the nil reaching it seven ways, the call in four positions, each with a twin whose slot holds a value), gcc, plain and under `SPINEL_GC_STRESS=1` and `2`: 945 right on master, 1,008 here; the 63 answered for the slot's type. Cost: a loop over `@list.is_a?(Array)` keeps master's C when `initialize` sets the variable. When only `||=` fills it, master folded the test and gcc the loop with it; here it is two to six instructions a turn (callgrind, two million turns of `c += 1 if @list.is_a?(Array)`: master 763,928; here 12,763,898 with the list filled and 4,762,875 with it nil, where master counts two million and CRuby none).

`make cident REF=upstream/master` on 2f204adb: `6336 identical, 4 differ, 0 refusal changes`: the new test and three programs that gain the test; the four pass. optcarrot's generated C is byte-identical. `test/nil_array_hash_slot_class_test.rb` prints wrong lines on master; it passes with gcc and clang, plain, under `SPINEL_GC_STRESS=1` and `2`, and under `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; equal under Ruby 4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
