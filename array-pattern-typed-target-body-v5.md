<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
t = "o"
case [3, "s"]
in [Integer => t, String]
  p t        # 3
end
```

Before: exit 139, nothing printed. With `n = 0` bound by `[String => n, Integer]` over `["a", 4]`, `p n` printed 0. `t = "o"` bound by `[*, t]` over `[1, 2]` did not build.

After: 3, "a" and 2.

Cost: such a local is boxed, and only where every other use of it prints it or compares it with a literal, so what is left to pay is the boxed form of those uses. Ten million `t == "o"` take 0.098 s where they took 0.007. The program, with gcc 13.3 at spinel's own flags, the least CPU time of five runs:

```ruby
t = "o"
case [true, :w]
in [Integer => t, *] then puts "hit"
else puts "miss"
end
i = 0
n = 0
while i < 10_000_000
  n += 1 if t == "o"
  i += 1
end
p n
```

With the fourth line from the end swapped: `"o" == t` 0.099 for 0.007, `t != "q"` 0.090 for 0.018, a Symbol against a Symbol 0.059 for 0.005, a Float against a Float 0.068 for 0.005, an Integer against a Float literal 0.064 for 0.005, an Integer against an Integer 0.009 for 0.005 (`7 == t` and `t != 9` the same), `nil?` 0.004 for 0.004. Of an Integer local, `s = "v#{t}"` takes 0.221 for 0.125 and `s = "#{t + 1}"` 0.228 for 0.116.

A binding converts the boxed element to the local's type (`emit_pm_typed_assign`), and `infer_case_pattern_locals` unified that type with the element only for a bare required target (`[t, String]`). A captured element, an element after the splat and the targets of a nested pattern kept the type the local's assignment gave it, so an Integer was unboxed as a String.

Chosen: the local is boxed, in an Array pattern and in a find pattern's window, where all three hold.

1. The element is surely of another class. Every assignment to the local is a statement `x = literal` (`+"o"` and `"o".dup` are a String's only while the program has no `+@` or `dup` of its own), and
   - the capture names `Integer`, `Float`, `String`, `Symbol`, `NilClass`, `Array` or `Hash`, a literal of one, an Array pattern, or alternatives of those, and no assignment writes a literal of that class; or
   - the subject is an Array of Integers, of Floats or of Strings, the literals are of another class and none is `nil`.
2. Every other use of the local is on a list (`pm_uses`) of what a boxed local answers as the typed one did:
   - `puts x`, `print x`, a statement `p x`, and its interpolation;
   - `==` and `!=` with a literal, and `nil?`; a literal's own `7 == x`, but not of an object of the program's classes, which Ruby asks for its `==` there;
   - printed by `puts` or a statement `p`, or interpolated, at once: `class`, `inspect`, `to_s`, `+` and `-` with an Integer literal, `size`, `length`, `empty?`, `upcase`, `reverse`, `first`, `to_sym`, `to_f`. Not `size`, `length` or `upcase` of a Symbol: a boxed Symbol counts its bytes (`:é.size` is 2 there), and its `upcase` is not rooted.
3. The name is the builtin's. The program has no method of its own under it, in any class or module, whether a `def`, an `alias`, an `alias_method`, a `define_method` or an `attr_reader` makes it, or an `undef`, a `remove_method` or a `private` takes it away; one of those called with a name that is not a literal, and a `method_missing`, count for every name. A class of the program's own counts too (`class Tally; def to_f(*digits)`): a boxed `t.to_f` is compiled as a dispatch over every class of the program's with a method under that name, whatever parameters it takes. A `puts`, `print` or `p` of the program's own counts wherever it is defined. So does the `to_s` or `inspect` the builtin one asks, except in a class of the program's own, where it is asked of that class's objects only. An Array pattern, or the name `Array`, binds an Array only while the program has no class such a pattern matches (one with `deconstruct`, a Struct, a subclass of Array); with one, the local may hold its object.

So the boxed value is printed or compared by the builtin's own method and goes nowhere else: not into a container, an object, a block's or a method's answer, nor to a method of the program's. A local with any other use, and every other local, is typed as it was and writes the same C.

Rejected: boxing wherever the class differs, whatever the uses. It cures more, but a boxed String stored into a container or an object is a copy (`Box.new(t).v << "m"` no longer reached `t`), a boxed value answers `object_id` and `equal?` otherwise and has no `upto`, and programs that were right went wrong or were refused.

Rejected: reading a listed name as the builtin's unless a `def` of it is in sight. `alias print keep` hands the local itself to the program's `keep`, and a `String#empty?` of the program's own is not asked of a boxed String, so programs that were right printed another line.

Rejected: keeping a listed name where the only method under it is in a class of the program's own, which answers for that class's objects. The boxed call names that method all the same: beside `class K; def +(*a)`, `puts t + 1` of a boxed Integer does not build. And reading `+"o"` as a String whatever `String#+@` is: the local may then hold what that method answers.

Not here:

- a bare target after the splat over an Array whose element class is not typed (Symbols, `true` and `false`, `nil`, Arrays, Hashes, objects, Ranges, a mix): `t = "o"` bound by `[_, *, t]` over `[:q, :r]` still exits 139;
- a program with a method of its own under a listed name, as 3 says, and a Symbol's `size`, `length` and `upcase`: such a local is typed as on master and fails as it did. Beside any `class Tally; def ==(o)`, `t = "o"` bound by `[Integer => t, String]` over `[3, "s"]` still prints false for `p t == 3`;
- the capture of an arm that then fails, which Ruby keeps: `[Integer => t, String]` over `[3, :w]` leaves `t` as it was, where Ruby prints 3. Where the local is of another class than that capture, master did not build, and the program now builds and prints the same old value: `t = 2.5` with `[String => t, "zz"]` over `["s", "r"]` printed nothing (`incompatible types when assigning to type 'sp_float'`) and prints 2.5, where Ruby prints "s";
- `Integer` does not match -9223372036854775808, on master or here. `t = "o"` with `[Integer => t, String]` over that number and `puts t - 1` was refused at compile time (`undefined method '-' for an instance of String`); it builds now, misses, and raises the same NoMethodError at run time, where Ruby prints -9223372036854775809;
- `p 1 != 2` prints `true` on master whatever `TrueClass#inspect` the program defines. A program master refused for `p 1 != t` of an Array local (`unsupported equality`) builds now and prints `true` the same way.

Measured with gcc, every program against CRuby 3.3.6. The generated families ran on master 5a752fceb48c with the change built there, the two marked on master 759d120fd207; the test, `make cident` and the compile times are on 8dc5522541bb.

- The list was drawn on master, on a local it boxes already (two assignments that never run): 5,616 generated programs, each listed use by each way of printing it by up to 21 kinds of value, and from a method, a block, a lambda, a loop and a rescue. They print what CRuby prints, but for 64 that differ only in the 3.3 format of `Hash#inspect` and 27 where the call raises as in Ruby and master skips the `ensure` of a `begin` whose `rescue` names another class, as it does for any exception. Two uses failed there and are off the list: `print x.class` (refused) and a literal's own `==` with an object of the program's own class.
- The cure: four generated families (a capture, a bare target after the splat, twelve kinds of body, and 457 programs of mixed shapes), 9,090 programs, of which 3,911 change. 1,193 were right and stay right, 2,457 become right, and 261 fail as before for another cause (249 where a lambda reads the local do not build, 12 are a RangeError). A sample of 461 was also run with clang, with `--int-overflow=promote` and at `SPINEL_GC_STRESS=1` and `2`: 453 right each way; the other 8 are master's own answers (3 a bignum element, 5 a Symbol's `length` or `upcase`, which write master's C).
- A method of the program's own under a listed name: 7,966 programs, each of the 16 names by 7 kinds of local by up to 76 roads to a method (in the local's class, in Object, Kernel, BasicObject, Numeric, Comparable; a module included, prepended or refined; `alias`, `alias_method`, `define_method`, `attr_reader`, `undef`, `private`, with a literal name and without; a Struct's member; `method_missing`; a class of the program's own). 6,353 write master's C and 1,553 are refused by both. The 60 that change have the method in a class of the program's own and a second local that only `p`, `puts`, an interpolation or a literal's own `7 == t` reads: 56 were right and stay right, 4 were refused and are right. 942 more programs define a method under a name off the list that a listed use might still ask of the local (81 names: `to_str`, `coerce`, `<=>`, `eql?`, `hash`, `respond_to?`, `!` and others), in the local's class or in Object: 922 were right and stay right, 1 becomes right, 19 are wrong before and after.
- A class of the program's own with a method under a listed name, in eight shapes of parameters (none, a rest, an optional one, two, keywords, a block, one, an optional one with a keyword), on master 759d120fd207: 2,352 programs with the method under each of the 16 names, or under `inspect` or `to_s`, by four kinds of answer beside six locals. Of the 1,392 that call the name on the local, 1,150 write master's C and 242 are refused by both. The 960 that print the local beside an `inspect` or a `to_s` (`p`, `puts`, `print`, an interpolation) change: 380 were right and stay right, 520 become right (350 crashed, 170 printed something else), and 60 do not build before or after (a `def inspect(&b)` or `def to_s(&b)` that answers a String). 1,536 more have `==` or `!=` in the class and compare the local by a literal's own `3 == t`: 96 are refused by both, 1,248 print what CRuby prints, and 192 do not build before or after, at the class's own `K.new != 5`.
- A `puts`, `print` or `p` of the program's own: 2,757 programs, 3 names by 15 bodies by 63 roads. All write master's C or are refused by both.
- Objects of the program's own classes: 9,270 programs (a class with `deconstruct`, its parent, a module it includes, an alias, `define_method`, a subclass of Array, a Struct, an unrelated class; bound by `Foo =>`, `Object =>`, `Array =>`, `[Integer, Integer] =>`, `[*] =>`, or not bound). 6,280 write master's C. Of the 2,990 that change, one of each kind of class, pattern and use was run, 365 programs: 262 were right and stay right and 103 become right (22 crashed, 1 raised, 80 printed something else; 4 of the 103 print an object's default `inspect`, as Ruby does but for the address).
- Off the list: 50,946 programs with one more use after each shape of pattern. Where that use is off the list the C is master's byte for byte.
- `make cident REF=8dc5522541bb`: `6447 identical, 0 differ, 1 refusal changes, 0 refused by both, 0 not in the reference`; the one refusal change is the new test, which master refuses.
- Compile time, the least of eight `spinel -c`: optcarrot 1.37 s for 1.38; a program of 2,000 `case` statements of two arms each, with a local apiece, 0.87 s for 0.77 where the C is master's, and 1.57 for 0.77 where each local is boxed. Master takes 1.37 for that program with a bare target in the pattern, where it boxes the 2,000 locals itself.
- `test/array_pattern_target_typed_before.rb`: master refuses it (`undefined method '-' for an instance of String`, for a local it typed a String). With the change it prints its `.expected` with gcc and clang, with `--int-overflow=promote`, and under `SPINEL_GC_STRESS=1` and `2`; it is added to `GC_STRESS_TESTS`, and `make gc-stress-test`, `make reject-test` and `tools/refusals.sh` pass.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
