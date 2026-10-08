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

Cost: such a local is boxed, and only where every other use of it prints it or compares it with a literal, so what is left to pay is the boxed form of those uses: ten million `t == "o"` take 0.098 s where they took 0.007. And where one such local of a program has a use off the list, none of that program's is boxed (rule 5 below): of the 94,403 generated programs under "Measured", 1,456 stay on master's C for it, and 5 of those would otherwise be cured (4 that master refuses, 1 that prints another line). The timed program, with gcc 13.3 at spinel's own flags, the least CPU time of five runs:

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

With the fourth line from the end swapped: `"o" == t` 0.097 for 0.007, `t != "q"` 0.089 for 0.018, a Symbol against a Symbol 0.058 for 0.005, a Float against a Float 0.067 for 0.005, an Integer against a Float literal 0.063 for 0.005, an Integer against an Integer 0.009 for 0.005 (`7 == t` and `t != 9` the same), `nil?` 0.004 for 0.004. Of an Integer local, `s = "v#{t}"` takes 0.214 for 0.122 and `s = "#{t + 1}"` 0.225 for 0.115.

A binding converts the boxed element to the local's type (`emit_pm_typed_assign`), and `infer_case_pattern_locals` unified that type with the element only for a bare required target (`[t, String]`). A captured element, an element after the splat and the targets of a nested pattern kept the type the local's assignment gave it, so an Integer was unboxed as a String.

Chosen: the local is boxed, in an Array pattern and in a find pattern's window, where all five hold.

1. The element is surely of another class. Every assignment to the local is a statement `x = literal` (`+"o"` and `"o".dup` are a String's only while no `+@` or `dup` of the program's own can answer for a String), and
   - the capture names `Integer`, `Float`, `String`, `Symbol`, `NilClass`, `Array` or `Hash`, a literal of one, an Array pattern, or alternatives of those, and no assignment writes a literal of that class; or
   - the subject is an Array of Integers, of Floats or of Strings, the literals are of another class and none is `nil`.
2. Every class the local may hold is known: those of its literals, those its captures name, and that of the typed element its one bare target binds. A bare target anywhere else binds a value of any class, and so does a capture whose pattern names none.
3. Every other use of the local is on a list (`pm_uses`), for each of those classes. The list is what master answers as CRuby does on a local it boxes itself, a bare target of an Array pattern (`in [t, Symbol]`); the runs are under "Measured".
   - `puts x`, `print x`, a statement `p x`, and its interpolation;
   - `==` and `!=` with a literal, and `nil?`; a literal's own `7 == x`, but not of an object of the program's classes, which Ruby asks for its `==` there. Not a Float against an Integer literal the compiler holds as a Bignum (one past 64 bits, and -9223372036854775808), which the boxed comparison gets wrong;
   - printed by `puts` or a statement `p`, or interpolated, at once: `class`, `inspect`, `to_s`, `size`, `length`, `empty?`, `upcase`, `reverse`, `first`, `to_sym`, `to_f`, and `+` and `-` with an Integer literal. Not `size`, `length` or `upcase` of a Symbol (a boxed Symbol counts its bytes, `:é.size` is 2 there, and its `upcase` is not rooted), not `reverse` of an Array (not rooted while `puts` walks it), not `first` of an object of the program's classes (it goes through a `to_a` or an `each` there).
4. The name is the builtin's. The program has no method of its own under it, in any class or module, whether a `def`, an `alias`, an `alias_method`, a `define_method` or an `attr_reader` makes it, or an `undef`, a `remove_method` or a `private` takes it away; one of those called with a name that is not a literal, and a `method_missing`, count for every name. A class of the program's own counts too (`class Tally; def to_f(*digits)`): a boxed `t.to_f` is compiled as a dispatch over every class of the program's with a method under that name, whatever parameters it takes. Three names count for the read that asks them: a `<=>` for `==` and `!=` (a boxed `==` is answered from it, with Comparable or without), a `to_ary` for `puts`, a `to_a` for `first`. A `puts`, `print` or `p` of the program's own counts wherever it is defined. So does the `to_s` or `inspect` the builtin one asks, except in a class of the program's own, where it is asked of that class's objects only. An Array pattern, or the name `Array`, binds an Array only while the program has no class such a pattern matches (one with `deconstruct`, a Struct, a subclass of Array); with one, the local may hold its object.
5. No local of the program fails 2, 3 or 4 where 1 holds for it. Where one does, no local of the program is boxed and the program writes master's C, or is refused as it was. Boxing the others would build a program master refused for one of them, and the local left typed would then print master's wrong line where nothing was printed before.

So the boxed value is printed or compared by the builtin's own method and goes nowhere else: not into a container, an object, a block's or a method's answer, nor to a method of the program's. A local with any other use, and every other local, is typed as it was and writes the same C.

Rejected: boxing wherever the class differs, whatever the uses. It cures more, but a boxed String stored into a container or an object is a copy (`Box.new(t).v << "m"` no longer reached `t`), a boxed value answers `object_id` and `equal?` otherwise and has no `upto`, and programs that were right went wrong or were refused.

Rejected: a list of what a boxed local "should" answer, read off the runtime. Five reads that looked the same boxed and typed were not (a Float against a Bignum literal, a Symbol's `size`, an Array's `reverse` under `puts`, `==` beside a `<=>` of the program's own, `puts` beside a `to_ary`), so each entry is now there only for what the runs show.

Rejected: reading a listed name as the builtin's unless a `def` of it is in sight. `alias print keep` hands the local itself to the program's `keep`, and a `String#empty?` of the program's own is not asked of a boxed String, so programs that were right printed another line.

Rejected: keeping a listed name where the only method under it is in a class of the program's own, which answers for that class's objects. The boxed call names that method all the same: beside `class K; def +(*a)`, `puts t + 1` of a boxed Integer does not build.

Not here:

- a bare target after the splat over an Array whose element class is not typed (Symbols, `true` and `false`, `nil`, Arrays, Hashes, objects, Ranges, a mix): `t = "o"` bound by `[_, *, t]` over `[:q, :r]` still exits 139. Nor a local a second bare target binds, or a capture whose pattern names no class (2);
- a use off the list, or a method of the program's own under a listed name (3, 4): such a local is typed as on master and fails as it did, and by 5 so does every other local of that program. Beside any `class Tally; def ==(o)`, `t = "o"` bound by `[Integer => t, String]` over `[3, "s"]` still prints false for `p t == 3`;
- a program master refused for a local this cures builds now, and a second local of the first kind above then fails as master's does where it builds: `n = 0` bound by `[String => n, Integer]` over `["a", 4]` with `puts n.upcase` was refused (`undefined method 'upcase' for an instance of Integer`); beside the `[_, *, t]` above the program now builds and exits 139;
- an arm with a guard (`in [Integer => t, String] if ok`): its target is not counted, so the local is typed as on master and by 5 so is every other local of that program;
- the capture of an arm that then fails, which Ruby keeps: `[Integer => t, String]` over `[3, :w]` leaves `t` as it was, where Ruby prints 3. Where the local is of another class than that capture, master did not build, and the program now builds and prints the same old value: `t = 2.5` with `[String => t, "zz"]` over `["s", "r"]` printed nothing (`incompatible types when assigning to type 'sp_float'`) and prints 2.5, where Ruby prints "s";
- `t + 1` and `t - 1` at the end of the Integer range raise RangeError, as every Integer does by default: `t = "o"` bound by `[Integer => t, String]` over `[9223372036854775807, "s"]` with `p t + 1` raised a TypeError; it raises `integer overflow in +` now, and prints 9223372036854775808 with `--int-overflow=promote`, as Ruby does;
- `Integer` does not match -9223372036854775808, on master or here. `t = "o"` with `[Integer => t, String]` over that number and `puts t - 1` was refused at compile time (`undefined method '-' for an instance of String`); it builds now, misses, and raises the same NoMethodError at run time, where Ruby prints -9223372036854775809;
- a String's invalid bytes: `"\xff".upcase` answers a String and `"\xff".to_sym` a Symbol on master, where Ruby raises. `n = 0` bound by `[String => n, Integer]` over `["\xff", 4]` with `puts n.upcase` was refused; it builds now and prints the line `n = "\xff"; puts n.upcase` prints;
- `p 1 != 2` prints `true` on master whatever `TrueClass#inspect` the program defines. A program master refused for `p 1 != t` of an Array local (`unsupported equality`) builds now and prints `true` the same way.

Measured with gcc, every program against CRuby 3.3.6. The list's runs are on master 8dc5522541bb; the generated families ran on master 5a752fceb48c with the change built there, and two of them again on 42557a3c0e7c; the test, `make cident` and the compile times are on 80e28dd295a7.

- The list is drawn on master, on a local it boxes itself, the bare target of `in [t, Symbol]`: 119,914 generated reads. Each use stands in 14 positions (`p` and `puts` of one value and of two, `print`, four interpolations, a statement, a value, a condition, an element, an argument) over 87 values (65 of the seven classes, 22 of none: a Range, a Class, a Rational, an exception), bound by the pattern and assigned before a pattern that fails, at the top level and in a method, and runs with gcc and clang at `SPINEL_GC_STRESS` unset, 1 and 2. A use is on the list for a class only where all six runs print CRuby's line for every value of that class. Off for that: a Float against a Bignum literal (144 reads), a Symbol's `size`, `length` and `upcase` (220), `puts` of an Array's `reverse` at stress 2 (8), and every value of no named class. Left on, where master's typed local answers the same: the 3.3 format of `Hash#inspect` (130), an Integer sum past 64 bits, a RangeError by default (160), and a String's invalid or NUL bytes (26; under "Not here").
- Beside a class of the program's own: 81,792 more reads, each use of each class beside such a class in 72 forms (with no method of its own; a `<=>` that answers 0, 1 or nil, with Comparable and without; an `==` or a `!=` that answers true or false; `coerce`, the operators, `to_str`, `to_ary`, `to_a`, `each`, `hash`, `eql?`, `respond_to?`; each listed name). What fails there and not above is off by 3 and 4: `==` and `!=` beside a `<=>`, an `==` or a `!=` (132), `first` beside a `to_a` or an `each` (4), `puts` beside a `to_ary` (2), `class` beside a `class` (2).
- The cure and its limits: twelve generated families, 94,403 programs: a capture and a bare target after the splat over twelve kinds of body (12,054); one more use after each shape of pattern, on the list and off it (50,946); a method of the program's own under a listed name, or under a name a listed use might ask, by up to 76 roads to a method (15,320); a class of the program's own with such a method, in eight shapes of parameters (3,888); objects of the program's own classes as the subject (9,270); a `puts`, `print` or `p` of the program's own (2,925). 66,662 write master's C byte for byte and 5,214 are refused before and after. Of the 22,527 that change, 2,784 were run on both trees, a sample of each family in name order: 1,185 were right and stay right, 1,527 become right (630 did not build, 358 were refused, 310 printed another line, 180 crashed, 49 raised), 3 more print an object's default `inspect`, as Ruby does but for the address, and 69 fail before and after as they did (63 do not build, with the same error from the C compiler; 5 print the same other line; 1 raises the same RangeError). None that was right fails.
- `make cident REF=80e28dd295a7`: `6477 identical, 0 differ, 1 refusal changes, 0 refused by both, 0 not in the reference`; the one refusal change is the new test, which master refuses.
- Compile time, the least of eight `spinel -c`: optcarrot 1.41 s for 1.40; a program of 2,000 `case` statements of two arms each, with a local apiece, 0.91 s for 0.81 where the C is master's, and 1.69 for 0.81 where each local is boxed. Master takes 1.45 for that program with a bare target in the pattern, where it boxes the 2,000 locals itself.
- `test/array_pattern_target_typed_before.rb`: master refuses it (`undefined method '-' for an instance of String`, for a local it typed a String). With the change it prints its `.expected` with gcc and clang, with `--int-overflow=promote`, with `--share-strings`, and under `SPINEL_GC_STRESS=1` and `2`; it is added to `GC_STRESS_TESTS`, and `make gc-stress-test`, `make reject-test` and `tools/refusals.sh` pass.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
